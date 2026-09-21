// Shared trusted module resolution and Chrome discovery for PNG and GIF.
const fs = require("fs");
const path = require("path");
function loadRenderer() {
  const attempts = [];
  const loaders = [
    {
      label: "puppeteer",
      load: () => require("puppeteer"),
      resolve: () => require.resolve("puppeteer"),
      version: () => require("puppeteer/package.json").version,
    },
    {
      label: "puppeteer-core",
      load: () => require("puppeteer-core"),
      resolve: () => require.resolve("puppeteer-core"),
      version: () => require("puppeteer-core/package.json").version,
    },
  ];
  if (process.env.FIREWORKS_PUPPETEER_PATH) {
    const explicitPath = path.resolve(process.env.FIREWORKS_PUPPETEER_PATH);
    loaders.unshift({
      label: "FIREWORKS_PUPPETEER_PATH",
      load: () => require(explicitPath),
      resolve: () => require.resolve(explicitPath),
      version: () => {
        const packagePath = fs.statSync(explicitPath).isDirectory()
          ? path.join(explicitPath, "package.json")
          : path.join(path.dirname(explicitPath), "package.json");
        return JSON.parse(fs.readFileSync(packagePath, "utf8")).version;
      },
    });
  }
  for (const candidate of loaders) {
    try {
      return {
        api: candidate.load(),
        module: candidate.label,
        resolvedModule: candidate.resolve(),
        moduleVersion: candidate.version(),
      };
    } catch (error) {
      attempts.push(`${candidate.label}:${error.code || error.message}`);
    }
  }
  throw new Error(
    `Puppeteer is unavailable. Install puppeteer-core or set FIREWORKS_PUPPETEER_PATH. ${attempts.join("; ")}`,
  );
}

function chromeExecutable(renderer) {
  const candidates = [
    process.env.FIREWORKS_CHROME_PATH,
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/usr/bin/google-chrome",
    "/usr/bin/google-chrome-stable",
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
    "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
  ].filter(Boolean);
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  if (typeof renderer.executablePath === "function") {
    try {
      const bundled = renderer.executablePath();
      if (bundled && fs.existsSync(bundled)) {
        return bundled;
      }
    } catch (error) {
      // puppeteer-core intentionally has no bundled browser.
    }
  }
  return null;
}

module.exports = { loadRenderer, chromeExecutable };
