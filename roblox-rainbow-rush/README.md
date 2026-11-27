# 🌈 Rainbow Rush Obby — Sky Carnival Edition 0.5

This is a separate Roblox game, made free to play with optional future upgrades. **Rainbow Rush 0.5** adds a colorful obby-style lobby, 12 sky-island obstacle themes, stage arches, beacons, an illuminated finish podium, animated coins, a race timer, and personal-best tracking. It is not yet published or fully playtested in Studio; Robux earnings are not guaranteed.

## What the game does

- Builds **12 themed sky-island stages** automatically: zigzags, lasers, speed boosts, vanishing platforms, moving clouds, tightrope, spinners, and a finish island. The original grey Baseplate is hidden.
- **Obby-style visuals:** rainbow arches, glowing checkpoint beacons, white platform trim, floating sky decorations, a welcome deck, rainbow flooring, rotating coin orbs, and a finale podium.
- **Race timer and personal best:** the HUD shows current race time and saved best completion time. A clean full-course run can earn a 100-coin personal-best bonus; using a paid stage skip disqualifies that run from the personal-best timing reward.
- Players jump across platforms, collect coins, unlock checkpoints, and respawn at their last stage.
- Stage completion gives **25 free Coins**, coin pickups give **5 free Coins**, and finishing the entire course gives **200 bonus Coins**.
- Shows a redesigned gradient HUD, stage theme labels, a stage progress bar, a live timer, leaderboard Coins and Wins, checkpoint messages, and an **11-item shop** that displays Coming Soon until Roblox IDs are added.
- **Practice Boost:** spend **40 earned Coins** for 15 seconds of speed. **Free replay:** finish all stages to restart while keeping your Coins and Wins. **Checkpoint button:** return to your saved stage without resetting progress.
- Players use normal Roblox chat. **No commands**.
- Permanent-pass slots: Rainbow Trail, Speed, Gravity, Double Coins and VIP. Repeatable-product slots: 1/3 stage skips, two coin packs, fireworks and checkpoint chaos. **All IDs are 0 by default, so paid purchases are disabled.**

## Already have the old game in Roblox Studio?

1. Click **Stop** if the game is playing.
2. Open **ServerScriptService → Script**. Copy the complete new [server script](ServerScriptService/RainbowRushServer.server.luau), select all existing code with **⌘A** and replace it with **⌘V**.
3. Open **StarterPlayer → StarterPlayerScripts → LocalScript**. Copy the complete new [client script](StarterPlayerScripts/RainbowRushClient.client.luau), and replace the old code the same way.
4. Press **Play**. You should spawn in the new purple-and-rainbow lobby, looking toward the stage-one arch. Check platform jumps, rotating coins, moving platforms, hazards, the stage timer, checkpoint reset, finish bonus and the shop. Open **Window → Output** if anything errors.
5. **Keep this as a private prototype** until the entire course and saved progress are tested. Do not add Robux product IDs before testing purchases in an appropriate test environment.

## Copy and paste in Roblox Studio

1. On a desktop computer open [Roblox Studio](https://create.roblox.com/) and sign in using a parent/guardian-managed account if needed.
2. Click **New → Baseplate**.
3. Turn on **Explorer** and **Properties** from Studio's View/Window controls.
4. In Explorer, find **ServerScriptService**. Click **+ → Script**, name it `RainbowRushServer`. Delete its starter code. Copy **all** of [RainbowRushServer.server.luau](ServerScriptService/RainbowRushServer.server.luau) into this Script.
5. Under **StarterPlayer → StarterPlayerScripts**, click **+ → LocalScript**, name it `RainbowRushClient`. Delete its starter code. Copy **all** of [RainbowRushClient.client.luau](StarterPlayerScripts/RainbowRushClient.client.luau) into this LocalScript.
6. Press **Play**. The arena should generate automatically. Test all 12 stages, collectibles, checkpoint respawns, the shop, and the leaderboard.
7. For multiplayer testing, use Studio's local **Server & Clients** test mode with two players. Confirm each player tracks their own coins and checkpoints.
8. When the game works, choose **File → Publish to Roblox**, enter an original name, description, and thumbnail, then use Creator Hub to configure who can play.

**Do not paste this code into the Roblox in-game chat.** It belongs in Roblox Studio's Script Editor. Never paste other people's code unless you trust it.

## Optional Robux earnings — only after publishing

Game Passes are permanent upgrades; Developer Products are repeatable purchases. The server includes configurable slots for both. The code is **not yet production purchase-tested** and the product receipt/save path requires further validation for reliability under retries and simultaneous saves. All IDs are left at 0 for this release.

1. In [Roblox Creator Hub](https://create.roblox.com/), select your published experience, then create a **Game Pass** with a Rainbow Trail image and an appropriate price.
2. Copy that Game Pass's **Asset ID**.
3. In the server script, replace the relevant `0` inside `GAME_PASSES` with the real pass ID only after private testing. For repeatable products, use real IDs inside `PRODUCTS`.
4. Save and republish the game from Studio.
5. Test purchase prompting and ownership in an appropriate Roblox test environment before making the experience public.
6. Roblox processes any purchase itself. Developer earnings are subject to Roblox's rules, fees, eligibility, and payout requirements; creating a game does not automatically earn Robux.

The client simply opens Roblox's official `PromptGamePassPurchase` prompt. The server checks ownership with `UserOwnsGamePassAsync` before applying the trail.

**Do not** promise free Robux, fake scarcity, force purchases, create fake buttons that mimic Roblox's official UI, or sell random prizes without following Roblox policy.

## Before launch

- Playtest at least two clients, each checkpoint and the finish reward. The server HUD wiring and stage jump distances were reviewed in source; this is **not** a substitute for a Roblox Studio physics playtest.
- Check platform gaps are reasonable on both computer and mobile.
- Inspect the **Output** window for script errors.
- Configure DataStore saving properly. Studio test saves can need a published experience and API access settings.
- Add original art, sounds and a custom icon. Do not use copyrighted or stolen Roblox assets.
- Have a parent or guardian review game settings and any paid products if you're under 18.

## Files

- `ServerScriptService/RainbowRushServer.server.luau`: map generation, stage unlocks, coins, saving and trail ownership.
- `StarterPlayerScripts/RainbowRushClient.client.luau`: UI, leaderboard display, shop and notifications.
- `default.project.json`: optional Rojo project for experienced creators.

You can build this entirely by **copying two scripts into Studio**. No external server, third-party chat commands, or complicated plugin setup is required.
