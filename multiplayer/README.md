# DinoCraft 4.7 — Multiplayer Beta

This directory contains the **real WebSocket server** for DinoCraft's private online rooms. The game site remains on GitHub Pages; this Node service must run **separately**. Multiplayer is opt-in; the original single-player game works without it.

## Features

- Private eight-character invite codes and up to **8 players** per room.
- Co-op Survival and online PvP rooms (the world mode must match).
- Avatar positions (about 10 updates/second), player names, and join/leave notices.
- Host-created shared block-world snapshot; block breaking and placing are broadcast to room members.
- Host controls dinosaur movement/health; guests see synchronized creatures and contribute damage.
- Simple PvP melee-hit relay with server checks for distance and attack rate.
- Room data is held in memory until everyone leaves; a server restart clears all rooms and their worlds.
- Local single-player saves are not replaced with a guest's shared world.

## Run locally

Requires **Node.js 20+**.

```bash
cd multiplayer
npm install
npm start
```

The health endpoint is `http://localhost:3000/`. From a local development page you can enter `ws://localhost:3000/ws` in DinoCraft's **MULTIPLAYER** panel.

If playing the GitHub Pages HTTPS site, use a **hosted WSS endpoint** instead; insecure `ws://` connections are not accepted except localhost.

## Deploy to Render

1. Use a parent/guardian-managed hosting account if necessary. Open [Render](https://dashboard.render.com/) → **New → Web Service**.
2. Connect the GitHub repository **chloesoldit-ops/DINO-CRAFT**, branch `main`.
3. Set **Root Directory** to `multiplayer`, **Runtime** to Node, **Build Command** to `npm install` and **Start Command** to `npm start`.
4. Add environment variable **ALLOWED_ORIGINS** with value `https://chloesoldit-ops.github.io` (comma-separated origins for permitted test sites). Render configures `PORT`; the server binds `0.0.0.0`.
5. Deploy. The service must expose HTTPS/WSS. If its URL is `https://your-app.onrender.com`, the game uses `wss://your-app.onrender.com/ws`.
6. In DinoCraft, select **Survival** or **PvP**, enter the server URL in **🌐 MULTIPLAYER**, then **CREATE ROOM**. Share only the 8-character code with friends. They select the **same world mode**, enter the same server URL and code, and click **JOIN ROOM**.

The free hosting tier, if offered, may sleep when idle; startup delays, quotas, and pricing depend on the host.

## Basic acceptance test

Use two browser windows with the same deployed server:

1. Create a Survival room in Window A and join it from Window B.
2. Verify both avatars appear and move.
3. Place/break a block and verify the other player's world changes.
4. Fight a dinosaur together; its position and HP should follow the host.
5. Leave the room; verify the guest's own world returns.
6. Switch both windows to PvP and join a different room. Swing at the other player's avatar within melee range and check hit feedback.
7. Mute on one browser; verify its audio setting persists after reload.

## Security and limitations

**This is a multiplayer beta, not production-grade competitive networking.**

- Room codes are invitation tokens, **not accounts or passwords**. Anyone with the code and server URL can enter while the room exists.
- The server validates message size, room capacity, movement ranges, block coordinates, melee reach and rate limits. **It does not authenticate users or fully prevent cheats.**
- Avatar positions and shared PvP hits are only partially authoritative. A malicious modified browser client could forge movement, block actions, or attacks. Do not use real-money prizes or public ranked competitions.
- For co-op, the room host simulates dinosaur AI and sends snapshots; teammates relay damage to the host. Dino combat and score/loot attribution are not fully synchronized.
- PvP health, knockback, respawns, inventories, and hit precision are not fully server-authoritative.
- Room data is transient. There is no durable shared-world save, account service, moderation system or public matchmaking.
- Only share a **nickname**, not your real name, school, address, age or contact information. Set `ALLOWED_ORIGINS` on the server, use HTTPS/WSS, and host only for people you know.
- For a production release, the next steps are authoritative movement/combat, persistent room saves, identity and abuse controls, server-side enemy simulation, and end-to-end playtesting.

## Files

- `package.json` — Node 20+ and `ws` dependency.
- `server.js` — in-memory WebSocket room server.
- `test.js` — optional automated room smoke test (`npm test`, with the server running or test auto-start).

