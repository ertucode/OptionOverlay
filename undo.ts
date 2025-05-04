import { $ } from "bun";
import { quitApp, scheme } from "./common";

function removeFromLoginItems() {
  const script = `
    tell application "System Events"
      if exists login item "${scheme}" then
        delete login item "${scheme}"
      end if
    end tell
  `;
  $`osascript -e ${script}`;
}

async function main() {
  await quitApp();
  removeFromLoginItems();
}

main();
