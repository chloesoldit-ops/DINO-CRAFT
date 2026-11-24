# 🦖 DinoCraft Roblox Edition 0.1 — Roblox Studio Starter

This is a **separate Roblox (Luau) version** of DinoCraft, not a conversion of the HTML/Three.js Classic game. The browser Classic version remains in the repository root at `index.html`, currently v4.8.

## What the Roblox edition includes

- Real multiplayer through Roblox's own game servers — no separate WebSocket URL or invite server required.
- A generated dinosaur arena with walls, trees, a spawn point and blocky dinosaurs.
- Raptors and recurring **Tyrant Rex boss waves** with scaling health.
- Desktop click/F attack and a large mobile **ATTACK** button.
- **Opt-in PvP duels:** both participants must turn on PvP in the HUD before players can damage one another; the server validates hits.
- Server-validated dinosaur damage, coins for kills, and coin persistence (DataStore).
- Leaderboard stats `DinoCoins` and `DinoKills`.
- An optional cosmetic shop: **Blue Glow (60 earned DinoCoins)**, and optional **celebration fireworks** as a Developer Product when configured.

This is a working-code **starter prototype**. It is not yet a complete port of all six Classic worlds, multiplayer modes, crafting, animations or terrain.

## Import into Roblox Studio — simplest way

1. Open **Roblox Studio** (desktop), sign in to a suitable creator account and choose **Baseplate**.
2. In **View → Explorer**, find **ServerScriptService**. Insert a **Script** named `DinoCraftServer`. Open `ServerScriptService/DinoCraftServer.server.luau` in GitHub, copy the entire text and paste it into this Script.
3. In Explorer, open **StarterPlayer → StarterPlayerScripts**. Insert a **LocalScript** named `DinoCraftClient`. Paste the contents of `StarterPlayerScripts/DinoCraftClient.client.luau` into it.
4. Press **Play**. The server script builds the arena and dinosaur waves. Move with Roblox movement keys, aim at dinosaurs, click/F or use the mobile ATTACK button.
5. For a local multiplayer test, use Roblox Studio's **Test → Clients and Servers** controls and launch two or more clients. Verify that both players see the same dinos, waves and leaderboard. Also turn **PvP: ON** for both players, test a duel, then turn it off for one player and verify attacks no longer hurt that player.
6. Publish through **File → Publish to Roblox** when testing is satisfactory. Set the correct content maturity and privacy settings in Creator Hub.

Alternatively use [Rojo](https://rojo.space/) to sync the `roblox/default.project.json` project with Studio. Rojo is optional; manual paste is enough.

## What to type in the Roblox chat

Open the normal Roblox in-game chat **after pressing Play**. The following commands are already implemented using Roblox's `TextChatService`:

| Type this | What happens |
|---|---|
| `/dinohelp` | Shows available DinoCraft commands |
| `/wave` | Tells you the current dinosaur wave |
| `/coins` | Shows your earned DinoCoins balance |
| `/duel` | Toggles opt-in player-vs-player duels on or off |
| `/heal` | Spend 15 earned DinoCoins to restore up to 35 HP |

These are **gameplay chat commands**, not code installation commands. Do NOT paste server scripts into public Roblox chat. All commands are processed server-side; chat command feedback appears in the in-game message HUD.

### Exact copy-and-paste setup

1. Open [Roblox Studio](https://create.roblox.com/). Choose **Baseplate**.
2. In **Explorer**, click **ServerScriptService** → **+** → **Script**. Delete the starter `print("Hello world!")` text. Copy all of [DinoCraftServer.server.luau](ServerScriptService/DinoCraftServer.server.luau) and paste it in.
3. In **Explorer**, open **StarterPlayer → StarterPlayerScripts** → **+** → **LocalScript**. Delete its starter code. Copy all of [DinoCraftClient.client.luau](StarterPlayerScripts/DinoCraftClient.client.luau) and paste it in.
4. Press the Studio **Play** button. The server creates the arena; the client creates the combat, shop and PvP buttons.
5. Click the normal Roblox **Chat** icon and enter `/dinohelp`. You should see the commands in the on-screen HUD.
6. Test `/wave` and `/coins`, fight a dinosaur with mouse click, `F`, or **ATTACK**, and test `/heal` after earning coins.
7. To test true Roblox multiplayer, use Studio **Test → Clients and Servers** to run two clients. Both users must enable **PVP: ON** or type `/duel` for duels.

The client and server must be in their **correct** locations. Do not insert both as ordinary Workspace scripts.

## Optional Robux product (disabled by default)

The script intentionally uses:

```lua
local FIREWORK_PRODUCT_ID = 0
```

With this value **no Robux purchase is offered**. To enable cosmetic fireworks:

1. Publish your Roblox experience first.
2. In the experience's Roblox Creator Hub, create a **Developer Product** named something like *Celebration Fireworks* and set its price in Roblox's dashboard.
3. Copy the actual product ID from the dashboard and replace `0` above in the **server** script.
4. Test purchases in Studio's appropriate test environment before publicly enabling. The client reads the ID from the server and calls `MarketplaceService:PromptProductPurchase`.
5. The server handles the transaction in `MarketplaceService.ProcessReceipt`, checks the product ID, and stores the purchase receipt before returning `PurchaseGranted`. Do **not** grant items based only on the button click or the purchase prompt closing.

**Fair play:** every dinosaur, wave and battle remains free. Robux purchases are cosmetics only, with no better weapons or combat advantages. The current Blue Glow option uses earned DinoCoins instead of Robux.

## Known limits and necessary tests

- Studio playtests and actual Roblox publication **have not** been performed from this environment.
- The dinosaurs currently use procedural Roblox Parts and simple chase AI, not custom imported animated meshes.
- Blue Glow is active for the current character life and requires another earned-coin purchase after respawning.
- World generation is currently an arena, not the Classic six-world block sandbox.
- Coin persistence uses Roblox DataStoreService; make sure API services, Studio permissions and publishing are properly configured. Avoid using live production saves for testing.
- Developer Product receipts are recorded server-side, but a production store should add fulfillment/retry audit logs, customer support handling and purchase testing.
- Roblox has its own hosting, moderation and platform rules. Do not try to upload an HTML file to Roblox Studio as though it were a Roblox place.
- Avoid publishing private room codes, server details or personal contact information in Roblox chat.

## Project files

- `ServerScriptService/DinoCraftServer.server.luau` — server-authoritative waves, dinosaur attacks and cosmetics.
- `StarterPlayerScripts/DinoCraftClient.client.luau` — the player HUD, controls and optional shop.
- `default.project.json` — optional Rojo project map.

## Suggested next milestones

1. Test two clients in Studio and fix any runtime errors.
2. Improve dinosaur rigging, animation, and boss battle presentation.
3. Add co-op building, inventory, crafting and save slots.
4. Extend opt-in PvP with hit effects, round rules, clearer respawns and stronger anti-exploit protection.
5. Publish a private test experience first, then decide whether to make it public.
