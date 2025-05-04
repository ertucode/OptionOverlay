import { $ } from "bun";
import { existsSync } from "fs";
import {
  scheme,
  config,
  derivedDataPath,
  builtAppPath,
  appBundlePath,
  quitApp,
} from "./common";

// Step 2: Build the app
async function buildApp() {
  console.log("📦 Building the app...");
  await $`xcodebuild -scheme ${scheme} -configuration ${config} -derivedDataPath ${derivedDataPath} build`;
}

// Step 3: Copy app to /Applications
async function installApp() {
  if (!existsSync(builtAppPath))
    throw new Error("❌ Build failed: App not found.");
  console.log("🚚 Copying app to /Applications...");
  await $`rm -rf ${appBundlePath}`.quiet(); // Remove old version if exists
  await $`cp -R ${builtAppPath} ${appBundlePath}`;
}

// Step 4: Add to login items
async function addToLoginItems() {
  console.log("🧷 Adding to login items (if not present)...");
  const script = `
    tell application "System Events"
      if not (exists login item "${scheme}") then
        make login item at end with properties {path:"${appBundlePath}", hidden:false}
      end if
    end tell
  `;
  await $`osascript -e ${script}`;
}

// Step 5: Launch the app
async function launchApp() {
  console.log("🚀 Launching the app...");
  await $`open -a "${scheme}"`;
}

async function main() {
  try {
    await quitApp();
    await buildApp();
    await installApp();
    await addToLoginItems();
    await launchApp();
    console.log("✅ App updated and running!");
  } catch (err) {
    console.error("❌ Error:", err);
  }
}

main();
