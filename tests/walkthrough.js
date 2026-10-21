// Walkthrough test: drives every main flow with a fake webcam and saves a
// screenshot per step to tests/out/. Coordinates come from the original
// layout (Main is 642 x 684, centred on the stage).
//
// Usage: node tests/walkthrough.js [url] [camera.y4m]
// The optional Y4M should show a still scene for ~8 s and then something
// moving, so background removal can detect the empty scene and then key.
const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");

const url = process.argv[2] || "http://localhost:8123/index.html";
const y4m = process.argv[3];
const out = path.join(__dirname, "out");
fs.mkdirSync(out, { recursive: true });

const VW = 1000, VH = 800;
const MX = Math.floor((VW - 642) / 2), MY = Math.floor((VH - 684) / 2);
const at = (x, y) => [MX + x, MY + y];
// Control bar is at (1, 504) inside Main.
const bar = (x, y) => at(1 + x, 504 + y);
const EFFECTS = bar(500 + 62, 17 + 12);
const SHUTTER = bar(301 + 19, 12 + 19);
const DOWNLOAD = bar(20 + 16, 8 + 16);
const PIC1 = bar(15 + 1 + 14, 17 + 1 + 11);
const PIC4 = bar(15 + 31 + 15, 17 + 1 + 11);
const dot = n => bar(276 + 24 * n + 8, 21 + 8);
// Grid cell i (0-8) on the current page; cells fill column by column.
const cell = i => at(1 + 16 + 208 * Math.floor(i / 3) + 96, 23 + 16 + 156 * (i % 3) + 72);
const SCREEN_CENTER = at(1 + 320, 23 + 240);

async function launch() {
   const args = ["--use-fake-device-for-media-stream", "--use-fake-ui-for-media-stream", "--autoplay-policy=no-user-gesture-required"];
   if (y4m) args.push("--use-file-for-fake-video-capture=" + y4m);
   const browser = await chromium.launch({ args });
   const page = await browser.newPage({ viewport: { width: VW, height: VH }, acceptDownloads: true });
   const errors = [];
   page.on("console", m => { if (m.type() === "error") errors.push("console: " + m.text()); });
   page.on("pageerror", e => errors.push("pageerror: " + e.message + "\n" + e.stack));
   await page.goto(url);
   await page.waitForFunction(() => window.photobooth && window.photobooth.app, null, { timeout: 30000 });
   return { browser, page, errors };
}

async function click(page, p, wait) {
   await page.mouse.move(p[0], p[1]);
   await page.mouse.down();
   await page.mouse.up();
   await page.waitForTimeout(wait == null ? 800 : wait);
}

// Clicks photo n in the strip, which opens it in the viewer.
async function openPhoto(page, n, wait) {
   const pos = await page.evaluate(n => {
      const list = photobooth.app.main.photoList;
      let item = null;
      list.renderers.forEach((i, r) => { if (i === n) item = r; });
      return { x: list.x + item.x + 43, y: list.y + item.y + 33 };
   }, n);
   await click(page, at(pos.x, pos.y), wait);
}

async function shot(page, name) { await page.screenshot({ path: path.join(out, name + ".png") }); }

(async () => {
   const results = [];
   const check = (name, ok, detail) => { results.push((ok ? "PASS " : "FAIL ") + name + (detail ? " - " + detail : "")); };

   // --- Run 1: effects, photos, viewer, download, delete -------------------
   let { browser, page, errors } = await launch();
   await page.waitForTimeout(2500);
   await shot(page, "01-normal");

   await click(page, EFFECTS, 2500);
   await shot(page, "02-effects-page1");
   for (const [n, name] of [[1, "03-effects-page2"], [2, "04-effects-page3"], [3, "05-effects-page4"]]) {
      await click(page, dot(n), n === 2 ? 6000 : 2500);
      await shot(page, name);
   }
   await click(page, dot(0), 2000);

   await click(page, cell(0), 2500);                      // Sepia
   await shot(page, "06-sepia");
   check("select Sepia", await page.evaluate(() => photobooth.app.main.screen.selectedIndex === 0));

   await click(page, EFFECTS, 2000);
   await click(page, dot(1), 2000);
   await click(page, cell(6), 2500);                      // Twirl
   await page.mouse.move(SCREEN_CENTER[0] + 60, SCREEN_CENTER[1] - 40);
   await page.mouse.down();
   await page.mouse.move(SCREEN_CENTER[0] + 80, SCREEN_CENTER[1] - 20, { steps: 4 });
   await page.mouse.up();
   await page.waitForTimeout(1500);
   await shot(page, "07-twirl");

   await click(page, SHUTTER, 300);
   await page.waitForTimeout(1300);
   await shot(page, "08-countdown");
   await page.waitForFunction(() => photobooth.app.main.model.photos.length === 1 && photobooth.app.main.model.mainState === 1, null, { timeout: 30000 }).catch(() => {});
   await shot(page, "09-photo-taken");
   check("one photo taken", await page.evaluate(() => photobooth.app.main.model.photos.length === 1));
   // As in the original, the app returns to live view once the photo has
   // dropped into the strip; clicking it opens the viewer.
   check("back to live view after the drop", await page.evaluate(() => photobooth.app.main.model.mainState === 1));
   await openPhoto(page, 0, 1500);
   await shot(page, "09b-viewer-1pic");
   check("viewer open", await page.evaluate(() => photobooth.app.main.model.mainState === 3));

   const dl = page.waitForEvent("download", { timeout: 10000 }).catch(() => null);
   await click(page, DOWNLOAD, 1500);
   await shot(page, "10-save-dialog");
   await click(page, [Math.floor((VW - 200) / 2) + 100, Math.floor((VH - 100) / 2) + 70 + 11], 1500);
   const download = await dl;
   if (download) {
      const file = path.join(out, "download.jpg");
      await download.saveAs(file);
      check("download", fs.statSync(file).size > 1000, download.suggestedFilename());
   } else check("download", false, "no download event");
   await shot(page, "11-saved");

   // 4-photo mode.
   await click(page, SHUTTER, 1500);                      // back to picture mode
   await click(page, PIC4, 800);
   await click(page, SHUTTER, 300);
   // Wait for the fourth shot and for its thumbnail to land in the strip.
   await page.waitForFunction(() => {
      const m = photobooth.app.main;
      let n = 0;
      m.photoList.renderers.forEach(() => n++);
      return m.model.photos.length === 2 && n === 2 && m.model.mainState === 1;
   }, null, { timeout: 30000 }).catch(() => {});
   await shot(page, "12-four-taken");
   check("four-up photo taken", await page.evaluate(() => photobooth.app.main.model.photos.length === 2));
   await openPhoto(page, 1, 2500);
   await shot(page, "12b-viewer-4pic");
   await click(page, at(1 + 250, 23 + 150), 2500);         // a quadrant of the card
   await shot(page, "13-viewer-4pic-zoom");
   check("zoomed into a quadrant", await page.evaluate(() => photobooth.app.main.viewer.getViewer4Index() !== -1),
      String(await page.evaluate(() => photobooth.app.main.viewer.getViewer4Index())));

   // Delete the first photo from the strip (delete button at (5, 70) in the item).
   const item0 = await page.evaluate(() => {
      const list = photobooth.app.main.photoList;
      let first = null;
      list.renderers.forEach((i, r) => { if (i === 0) first = r; });
      return { x: list.x + first.x, y: list.y + first.y };
   });
   await click(page, at(item0.x + 5 + 5, item0.y + 70 + 6), 2000);
   await shot(page, "14-after-delete");
   check("delete", await page.evaluate(() => photobooth.app.main.model.photos.length === 1));

   check("no runtime errors (run 1)", errors.length === 0, errors.join(" | "));
   await browser.close();

   // --- Run 2: background removal ------------------------------------------
   ({ browser, page, errors } = await launch());
   await page.waitForTimeout(1000);
   await click(page, EFFECTS, 1500);
   await click(page, dot(2), 1500);
   await click(page, cell(0), 800);                       // Clouds
   await shot(page, "15-bg-step-out");
   await page.waitForTimeout(5000);
   await shot(page, "16-bg-detected");
   const detected = await page.evaluate(() => !!photobooth.app.main.screen.backgroundRemover.detectedBackground);
   check("background detected", detected);
   await page.waitForTimeout(4000);
   await shot(page, "17-bg-keyed");
   check("no runtime errors (run 2)", errors.length === 0, errors.join(" | "));
   await browser.close();

   fs.writeFileSync(path.join(out, "results.txt"), results.join("\n") + "\n");
   console.log(results.join("\n"));
})();
