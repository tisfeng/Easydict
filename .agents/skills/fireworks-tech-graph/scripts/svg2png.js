#!/usr/bin/env node
// Browser fidelity route: shared root dimensions, trusted Chrome resolution,
// bounded @2x export and PNG readback. Use fireworks.py export-png for 1920px.
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const { loadRenderer, chromeExecutable } = require("./renderer_runtime");
async function main() {
  const directory = path.resolve(process.argv[2] || ".");
  const loaded = loadRenderer();
  const executablePath = chromeExecutable(loaded.api);
  if (!executablePath) throw new Error("No compatible Chrome or Chromium executable was found");
  const browser = await loaded.api.launch({ headless: true, executablePath,
    args: process.env.FIREWORKS_CHROME_NO_SANDBOX === "1"
      ? ["--no-sandbox", "--disable-setuid-sandbox"] : [] });
  try {
    for (const file of fs.readdirSync(directory).filter(file => file.endsWith(".svg")).sort()) {
      const svgPath = path.join(directory, file);
      const canvas = JSON.parse(execFileSync(process.env.FIREWORKS_PYTHON || "python3",
        [path.join(__dirname, "svg_canvas.py"), svgPath], { encoding: "utf8", timeout: 10000 }));
      const width = Math.ceil(canvas.width), height = Math.ceil(canvas.height);
      if (width * height * 4 > 64000000 || Math.max(width, height) * 2 > 32768)
        throw new Error("2x PNG exceeds the 64 megapixel / 32768px export budget");
      const page = await browser.newPage();
      const temporary = fs.mkdtempSync(path.join(directory, ".fireworks-browser-png-"));
      try {
        await page.setViewport({ width, height, deviceScaleFactor: 2 });
        await page.setRequestInterception(true);
        page.on("request", request => request.url().startsWith("data:")
          ? request.continue() : request.abort());
        const data = fs.readFileSync(svgPath).toString("base64");
        await page.setContent(`<html><body style="margin:0;background:transparent"><img src="data:image/svg+xml;base64,${data}" width="${width}" height="${height}"></body></html>`);
        await page.evaluate(async () => { await document.querySelector("img").decode(); await document.fonts.ready; });
        const destination = svgPath.replace(/\.svg$/, ".png");
        const temporaryPng = path.join(temporary, "render.png");
        await page.screenshot({ path: temporaryPng, type: "png", omitBackground: true });
        const png = fs.readFileSync(temporaryPng);
        if (png.length < 24 || png.subarray(0,8).toString("hex") !== "89504e470d0a1a0a"
            || png.readUInt32BE(16) !== width * 2 || png.readUInt32BE(20) !== height * 2)
          throw new Error("PNG dimension readback failed");
        fs.renameSync(temporaryPng, destination);
        console.log(JSON.stringify({ ok: true, png: destination, width: width * 2, height: height * 2, renderer: loaded.module }));
      } finally { await page.close(); fs.rmSync(temporary, { recursive: true, force: true }); }
    }
  } finally { await browser.close(); }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
