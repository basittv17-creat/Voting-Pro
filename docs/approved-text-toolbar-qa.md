# Approved Text toolbar redesign QA

Baseline is main at `648c979361e01358e790e879d9e3bb4ce389a2f3`. The Gmail command and all three approved mockups were reviewed together before editing.

| Contract | Implementation or verification |
| --- | --- |
| One original bottom slot | The existing mode switch renders either the main toolbar or the Text row. Both retain the 68 dp content height and the same outer padding. |
| Back stays at the physical left | The Back tile is outside the horizontal viewport. The actions use the app's scroll direction in Urdu. |
| Tool coverage | All 38 actions retain their callbacks. Add, Edit, Color, Style and Font lead the row. |
| Settings placement | The existing inline settings render below the poster. Color, Glow and Style share the same panel location. Close and Android Back can dismiss settings while retaining Text mode. |
| Visual details | Navy cards, a gold active state and Back, and circular Color swatches follow the mockup. The two existing solid-color rows, original poster artwork and real gradient and preset actions use the app's existing values. |
| Android evidence | Android UI Smoke exercises the existing VS Styles flow and the Text workflow. The screenshot artifact covers main mode, Text, Color, Glow, Style, history, far scroll, and Back. Visual comparison requires reading the resulting screenshots. |

Merge after successful quality and Android runs and review of the screenshots. Device checks for system insets, keyboard, orientation, and persistence should be recorded with the final evidence.
