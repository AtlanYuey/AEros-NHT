import 'dart:collection';

import 'package:auto_route/auto_route.dart' show RoutePage;
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Open source licenses, as an iOS Settings style list (instead of
/// Flutter's Material [LicensePage]).
@RoutePage()
class MyLicensePage extends StatefulWidget {
  const MyLicensePage({Key? key}) : super(key: key);

  @override
  State<MyLicensePage> createState() => _MyLicensePageState();
}

class _MyLicensePageState extends State<MyLicensePage> {
  late final Future<Map<String, List<LicenseEntry>>> _licenses = _load();

  static Future<Map<String, List<LicenseEntry>>> _load() async {
    final map = SplayTreeMap<String, List<LicenseEntry>>(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        map.putIfAbsent(package, () => <LicenseEntry>[]).add(entry);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Licenses';
    return FutureBuilder<Map<String, List<LicenseEntry>>>(
      future: _licenses,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const AppleGroupedPage(
            title: title,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            ],
          );
        }
        return AppleGroupedPage(
          title: title,
          children: [
            AppleSection(
              footer: '${data.length} packages',
              children: [
                for (final entry in data.entries)
                  AppleListTile(
                    title: Text(entry.key),
                    value: '${entry.value.length}',
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => _LicenseDetailPage(
                          package: entry.key,
                          entries: entry.value,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LicenseDetailPage extends StatelessWidget {
  const _LicenseDetailPage({required this.package, required this.entries});

  final String package;
  final List<LicenseEntry> entries;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return AppleGroupedPage(
      title: package,
      children: [
        for (final entry in entries)
          AppleSection(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: SelectableText(
                  entry.paragraphs.map((p) {
                    final indent = p.indent > 0 ? '    ' * p.indent : '';
                    return '$indent${p.text}';
                  }).join('\n\n'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.secondaryLabel,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
