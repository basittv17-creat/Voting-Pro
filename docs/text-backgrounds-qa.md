# Text background and placement QA

The swatch handler already stored a color. The renderer used that color for a stroke just two pixels wider than the glyphs when expansion was zero, and a saved zero opacity could also survive color selection. New adjustments use a fitted plate with padding and restore visible opacity when a swatch is chosen at zero. Existing projects without a background-design key keep their glyph backgrounds until edited.

Saved and live text use the same renderer. Measured overlay bounds are clamped to the poster content area during layout and drag. RTL glyph layers reserve room for Nastaliq swashes before compositing gradients. Actual export still stops at the poster boundary.

The new direct toolbar action offers 16 offline plates. It keeps the existing Text Background action. Presets preserve the font and text color, and offer optional font and contrast controls. Existing advanced settings edit padding, corners, opacity, border and shadow. The design key participates in save/load, undo/redo, duplicate and overlay reindexing.

The automated coverage includes swatch activation from zero opacity, preset isolation and undo/redo, and moving an Urdu overlay away from a clamped top/right position at 320, 360, 393 and 412 dp in 16:9 and 4:3. The Android smoke test captures the plain text, swatch, premium picker, font previews and top edge. Font sources and license notices are in assets/fonts/licenses.
