import { join } from "path";
import { $ } from "bun";

export const scheme = "OptionOverlay";
export const config = "Release";
export const appName = "OptionOverlay.app";
export const appBundlePath = `/Applications/${appName}`;
export const derivedDataPath = "./build";
export const builtAppPath = join(
  derivedDataPath,
  "Build",
  "Products",
  config,
  appName,
);

// Step 1: Quit the app if running
export async function quitApp() {
  console.log("🛑 Quitting running instance...");
  await $`osascript -e 'tell application "${scheme}" to quit'`;
}
