# 🌈 Rainbow Rush Obby — Roblox Studio 0.1

This is a **brand-new Roblox game** (not DinoCraft), made to be free to play with optional cosmetic Robux purchases. This starter prototype is not yet published or tested in Roblox Studio. It does not guarantee Roblox earnings.

## What the game does

- Builds 12 bright obstacle-course stages automatically, so you don't need to hand-place hundreds of parts.
- Players jump across platforms, collect coins, unlock checkpoints, and respawn at their last stage.
- Stage completion gives **25 free Coins**, coin pickups give **5 free Coins**, and finishing the entire course gives **200 bonus Coins**.
- Shows a stage tracker, leaderboard Coins and Wins, notification messages, and a cosmetic shop.
- Players use normal Roblox chat. **No commands**.
- Optional paid **Rainbow Trail** Game Pass leaves a colorful trail. It does not help players win. The ID is set to **0 by default**, so the purchase is **disabled** until you set it up.

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

The Rainbow Trail is a **Game Pass**: the buyer keeps access to the cosmetic across visits. It is not required to complete any stage.

1. In [Roblox Creator Hub](https://create.roblox.com/), select your published experience, then create a **Game Pass** with a Rainbow Trail image and an appropriate price.
2. Copy that Game Pass's **Asset ID**.
3. In the server script, change `local RAINBOW_TRAIL_PASS_ID=0` to your actual ID.
4. Save and republish the game from Studio.
5. Test purchase prompting and ownership in an appropriate Roblox test environment before making the experience public.
6. Roblox processes any purchase itself. Developer earnings are subject to Roblox's rules, fees, eligibility, and payout requirements; creating a game does not automatically earn Robux.

The client simply opens Roblox's official `PromptGamePassPurchase` prompt. The server checks ownership with `UserOwnsGamePassAsync` before applying the trail.

**Do not** promise free Robux, fake scarcity, force purchases, create fake buttons that mimic Roblox's official UI, or sell random prizes without following Roblox policy.

## Before launch

- Playtest at least two clients, each checkpoint and the finish reward.
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
