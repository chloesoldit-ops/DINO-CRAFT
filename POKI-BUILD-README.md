# DinoCraft 3.4 — Improved Poki Inspector Build

**Status: TEST BUILD, NOT APPROVED BY POKI.**

Playable preview: https://chloesoldit-ops.github.io/DINO-CRAFT/poki/
Regular friends game (unchanged): https://chloesoldit-ops.github.io/DINO-CRAFT/

Download: DinoCraft-Poki-Test-Build.zip in this repository root.
ZIP contents: `index.html`, `three.min.js`, `THREE-LICENSE.txt`. The ZIP root starts with `index.html` (not another directory).
Poki Inspector: https://inspector.poki.dev/
Documentation: https://developers.poki.com/guide/sdk-html5

Implemented in this Poki test version:
- Official Poki SDK with loading, gameplayStart/gameplayStop and commercialBreak on resume from the Pause menu.
- Local Three.js r155 plus the upstream MIT license (the Poki SDK is the only approved remote script).
- Original Sporeburst and Void Moth models replacing recognizable borrowed creatures, plus Magma Depths and Void Realm.
- Creative/admin tools hidden and command-based cheat access blocked for public play. The friends edition still has the testing code.
- Fast entry: choosing a username is optional; clear mobile/desktop How to Play instructions replace cheat command help.
- Ads stop play input and audio; browser-hidden gameplay is not counted. No adblock gate.
- Private-browsing safe starter inventory, local-world saves, graphics presets, mobile touch and keyboard/mouse controls.

Next steps **before any public release**:
1. Upload the ZIP to Poki Inspector (or drag in the extracted build folder).
2. Inspect event order; test ads, sound muting/unmuting, keyboard, touch, and tablet controls.
3. Test 640x360, 836x470, and 1031x580 plus actual devices and Incognito.
4. Capture actual gameplay static AND animated thumbnail assets in Poki's specified dimensions.
5. Confirm originality, licensing, performance, loading and gameplay quality with Poki QA.
6. A parent/guardian should handle any developer account, agreement or payouts as appropriate.

**Important:** This package is not proof of passing Poki Inspector, and no Poki submission has been made. No money was spent.