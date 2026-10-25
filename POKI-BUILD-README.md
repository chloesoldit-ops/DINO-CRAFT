# DinoCraft — Poki Inspector QA Build 3.7

**Status: Build prepared; Inspector tests and Poki review have NOT been completed.**

- **Preview:** https://chloesoldit-ops.github.io/DINO-CRAFT/poki/
- **Inspector:** https://inspector.poki.dev/
- **Upload file:** `DinoCraft-Poki-Test-Build.zip` in this repository root, with `index.html` at ZIP root.
- **Regular game:** https://chloesoldit-ops.github.io/DINO-CRAFT/ (separate friends edition, no Poki SDK)
- **Source folder:** `poki/`

## Implemented for Inspector QA

1. **commercialBreak():** triggered when resuming a paused game. Not guaranteed to display an ad each time; Poki decides.
2. **rewardedBreak():** optional, labelled +150 DinoCoins in Pause. Reward only if SDK resolves `true`. Never needed for normal play.
3. **Audio safety:** game audio muted and WebAudio suspended during the break, with restoration afterward.
4. **Input safety:** keyboard including Space, game buttons and gameplay simulation disabled during ads.
5. **Pointer lock:** released explicitly before both commercial and rewarded ads.
6. **SDK events:** gameLoadingFinished once; gameplayStart / gameplayStop only on gameplay state transitions.
7. **Controls:** choose Automatic, Mobile / Touch or Computer / Mouse in Settings or on title screen.
8. **Local dependency:** Three.js r155 packaged in the build, MIT license included. Poki SDK is its sole external script.
9. **Original content:** Sporeburst and Void Moth replace distinctive borrowed foes; rebranded worlds.
10. **Incognito:** guarded first-time starter-kit storage. The app stays playable without functioning local storage.

## Tests still required before submitting a release

- Open the ZIP in Poki Inspector and **manually** verify event order, commercial/rewarded ads, audio, Space/keyboard, pointer lock and all five ad QA questions.
- Test on a real phone/tablet and desktop, narrow viewports, incognito and with an ad blocker.
- Create and validate gameplay thumbnails and get Poki's copyright/quality review.
- Games can be rejected even if code checks pass. This build is **not** an approved or published Poki listing.

Do not mistake static and mocked SDK tests for a real Inspector run.
