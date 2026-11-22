# A/B Photo Tools

The implementation follows the updated master command and two approved visual references. The classic editor uses the original 68 dp toolbar content slot for Photo Tools. Back is pinned to the physical left. The photo outline is editor-only and stays above the name strip.

- Replace uses the existing picker and resets only the target side's transform and background. Cancellation leaves both photos intact.
- Zoom changes the selected side in 10% steps, with the existing 1×–5× classic limits. Ready-made templates retain their existing photo picker and separate pinch/pan behavior.
- Remove Background reuses the offline remover's mask, checkerboard preview, auto remove, manual erase and restore, reset, and mask history. Applying writes a PNG, checks that the original side and source are still active, and retains the selected side's transform.
- Backgrounds provides None, navy, mint, sunset and ocean. Only an image with transparency can pick a preset. The background is drawn behind the foreground, inside the photo frame, and is saved independently for A and B. Older saves default to None.
- Selection is transient. Text history remains separate from photo edits. The mask editor supports undo before applying a cutout.

The Android smoke workflow captures the original dock, both selections, the A background panel, B's inline remover and applied cutout, and the restored dock. It retains the separate normal-app launch check and standard APK artifact.

Local verification used Flutter 3.50.1. Analysis passed with informational diagnostics, all 69 Flutter tests passed, and `git diff --check` passed.
