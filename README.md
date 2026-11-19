# Fusion Bay — roblox-brainrot-01 entry

Fusion Bay is a 3D Steal-a-Brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty
(roblox-brainrot-01), built in a recorded agent session (v3.0 rebuild).

- Buy brainrots off the conveyor, earn coins per second in your own base.
- **Fusion Altar (the twist):** fuse 2 same-rarity brainrots into 1 brainrot one rarity higher, mutation
  guaranteed at least Golden (Mythic + Mythic = Mythic Rainbow). Fused brainrots wear a gold Neon crown.
- Steal from other players (fair-steal rules: cooldowns, spawn protection, auto-lock), slap thieves,
  survive the 90-second tsunami wave, and climb the rebirth ladder (income x2 / x3 / x4).
- 10 original characters, golden-hour beach map, 8 coloured bases, HUD + Shop / Fusion / Rebirth /
  Rank / Help panels.

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts with a dot (such as
  `.gitkeep` or `.DS_Store`, which fail an entry), and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`; `screenshots/` holds three
  captures of it; `PLAY.json` names no place yet, so the gate refuses the starter as it stands until it
  names your published one.
- One of your screenshots must also be your game's first thumbnail on Roblox: the same picture, uploaded on
  the Creator Dashboard with your game's icon.
- `TOUR.json` is an example of the optional tour: for each screenshot, the keys that bring the game to that
  screen.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt,
which gives every command in order (Before you submit, then Enter).
