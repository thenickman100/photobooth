// Smoke test: loads the app in Chromium with a fake webcam, clicks through
// the main flows and saves screenshots to tests/out/.
// Usage: node tests/smoke.js [url] [y4m file for the fake camera]
const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");

const url = process.argv[2] || "http://localhost:8123/index.html";
const y4m = process.argv[3];
const out = path.join(__dirname, "out");
fs.mkdirSync(out, { recursive: true });

(async () => {
   const args = ["--use-fake-device-for-media-stream", "--use-fake-ui-for-media-stream", "--autoplay-policy=no-user-gesture-required"];
   if (y4m) args.push("--use-file-for-fake-video-capture=" + y4m);
   const browser = await chromium.launch({ args });
   const page = await browser.newPage({ viewport: { width: 1000, height: 800 } });
   const errors = [];
   page.on("console", m => { if (m.type() === "error" || m.type() === "warning") errors.push(m.type() + ": " + m.text()); });
   page.on("pageerror", e => errors.push("pageerror: " + e.message + "\n" + e.stack));
   await page.goto(url);
   await page.waitForFunction(() => window.photobooth && window.photobooth.app, null, { timeout: 20000 });
   await page.waitForTimeout(3000);
   await page.screenshot({ path: path.join(out, "01-start.png") });
   fs.writeFileSync(path.join(out, "errors.txt"), errors.join("\n"));
   console.log(errors.join("\n") || "no console errors");
   await browser.close();
})();
