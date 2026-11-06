import CryptoKit
import Foundation
import Observation
import Security

/// Stores the API tokens in the Keychain and refreshes them.
final class AuthStore: @unchecked Sendable {
    static let shared = AuthStore()

    private let accessKey = "api_v2_access_token"
    private let refreshKey = "api_v2_refresh_token"
    private let lock = NSLock()
    private var refreshTask: Task<Bool, Never>?

    var accessToken: String? { Keychain.read(accessKey) }
    var refreshToken: String? { Keychain.read(refreshKey) }
    var isLoggedIn: Bool { !(accessToken ?? "").isEmpty }

    func save(access: String, refresh: String?) {
        Keychain.write(accessKey, access)
        if let refresh, !refresh.isEmpty {
            Keychain.write(refreshKey, refresh)
        }
    }

    func clear() {
        Keychain.delete(accessKey)
        Keychain.delete(refreshKey)
    }

    /// Refreshes the access token once, sharing concurrent requests.
    func refresh() async -> Bool {
        let task: Task<Bool, Never> = lock.withLock {
            if let refreshTask { return refreshTask }
            let task = Task<Bool, Never> { [weak self] in
                guard let self, let token = self.refreshToken else { return false }
                do {
                    let pair = try await NHClient.shared.refreshTokens(token)
                    self.save(access: pair.accessToken, refresh: pair.refreshToken)
                    return true
                } catch {
                    return false
                }
            }
            refreshTask = task
            return task
        }
        let result = await task.value
        lock.withLock { refreshTask = nil }
        return result
    }
}

private enum Keychain {
    static let service = "com.atlanyuey.nhentai"

    static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty
        else { return nil }
        return value
    }

    static func write(_ key: String, _ value: String) {
        delete(key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// The signed-in user, observed by the UI.
@Observable
final class UserSession {
    static let shared = UserSession()

    private(set) var user: CurrentUser?
    private(set) var isLoggedIn: Bool = AuthStore.shared.isLoggedIn

    @MainActor
    func reload() async {
        isLoggedIn = AuthStore.shared.isLoggedIn
        guard isLoggedIn else {
            user = nil
            return
        }
        if let user = try? await NHClient.shared.currentUser() {
            self.user = user
        }
    }

    @MainActor
    func login(access: String, refresh: String?) async {
        AuthStore.shared.save(access: access, refresh: refresh)
        await reload()
    }

    @MainActor
    func logout() {
        AuthStore.shared.clear()
        user = nil
        isLoggedIn = false
    }
}

/// The API's proof of work for posting: a nonce such that
/// sha256(challenge + nonce) starts with `difficulty` zero bits.
enum ProofOfWork {
    static func solve(challenge: String, difficulty: Int) -> String {
        guard difficulty > 0 else { return "" }
        let fullBytes = difficulty / 8
        let remainingBits = difficulty % 8
        let mask: UInt8 = remainingBits == 0 ? 0 : UInt8((0xFF << (8 - remainingBits)) & 0xFF)
        var nonce = 0
        while nonce < (1 << 30) {
            let digest = Array(SHA256.hash(data: Data("\(challenge)\(nonce)".utf8)))
            var ok = true
            for i in 0..<fullBytes where digest[i] != 0 {
                ok = false
                break
            }
            if ok, mask == 0 || (digest[fullBytes] & mask) == 0 {
                return "\(nonce)"
            }
            nonce += 1
        }
        return ""
    }
}
