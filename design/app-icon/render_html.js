// Renders HTML pages to 1024 x 1024 PNGs (transparent where the page is).
// Usage: node render_html.js <dir> <name> [<name> ...]  (<dir>/<name>.html -> <dir>/<name>.png)
const { chromium } = require('playwright');
(async () => {
  const dir = process.argv[2];
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1024, height: 1024 } });
  for (const name of process.argv.slice(3)) {
    await page.goto(`file://${dir}/${name}.html`);
    await page.evaluate(() => document.fonts.ready);
    await page.screenshot({ path: `${dir}/${name}.png`, omitBackground: true });
  }
  await browser.close();
})();
