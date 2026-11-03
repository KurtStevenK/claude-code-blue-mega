---
name: claude-code-blue-mega
description: Make the VSCodium layout dividers (the resize strips between side bar, editor, editor groups, secondary side bar and bottom panel, plus a strip along the top of the editor area) a glowing VSCodium-blue strip at all times and mint while hovering or resizing. Optionally (off by default) restyles the Claude Code chat scrollbar. Use when the user wants blue dividers, sashes, borders or panel edges, or when these turned back to normal after a VSCodium or Claude Code update. For mint dividers that turn blue, use claude-code-mint-mega.
---

# claude-code-blue-mega

Companion to `claude-code-blue`. That skill recolors the Claude Code extension. This one styles VSCodium itself:

1. **Layout dividers (sashes).** By default VSCodium draws the strips between side bar, editor, secondary side bar and bottom panel, and between two editor groups (the middle one), only while you hover or drag them. This skill draws them all the time as a glowing blue strip (`#0078d4`). While you hover or resize, they turn mint (`#2ec767`).
2. **Top strip.** A blue strip of the same width runs along the top edge of the editor area, so the frame is closed. It is not draggable and stays blue.
3. **Claude Code chat scrollbar (off by default).** With `$chatScrollbar = $false` each run removes any old scrollbar block. With `$true` the scrollbar goes from 10px to 5px wide, with a transparent track and a thumb in the resize color: 60 % at rest, 85 % on hover, solid while dragging. The chat container sets `scrollbar-color`, which makes Chromium ignore `::-webkit-scrollbar` rules, so the script resets it to `auto`.

No setting controls the resting color of the dividers, so the script edits VSCodium's own workbench CSS and updates its checksum in `product.json`. Without that update, VSCodium would report the installation as corrupt.

**Twin:** `claude-code-mint-mega` is the same script with the colors swapped (mint at rest, blue while resizing). Each one removes the other's patch, so only one is active at a time.

## Tested with

- VSCodium **1.143.17232** (user install in `%LOCALAPPDATA%\Programs\VSCodium`), Windows
- Claude Code extension **2.1.316**

## What to do

1. **Colors / sizes (optional).** The top of `make-blue-mega.ps1` in this skill folder holds `$restColor`/`$restRgb` (dividers at rest), `$dragColor`/`$dragRgb` (while resizing), `$glow` (glow radius in px, 0 = none), `$stripSize` (strip width in px, default 2; VSCodium's own is 4), `$chatScrollbar`, `$scrollbarSize` (px) and `$thumbRgb` (scrollbar thumb color). Keep `$restColor` equal to the color used by `claude-code-blue`.
2. **Run the script** from this skill folder. VSCodium may stay open:
   ```powershell
   powershell -ExecutionPolicy Bypass -File ".\make-blue-mega.ps1"
   ```
   It can be run any number of times. Each run replaces its own block (and a `claude-code-mint-mega` block), which sits between `/* claude-code-blue-mega:start */` and `/* claude-code-blue-mega:end */`. It:
   - appends the divider CSS to `resources\app\out\vs\workbench\workbench.desktop.main.css` and updates that file's checksum in `resources\app\product.json`. On the first run it copies both files to `*.orig`;
   - only with `$chatScrollbar = $true`: appends the scrollbar CSS to `webview\index.css` of every `anthropic.claude-code-*` extension folder;
   - sets `workbench.colorCustomizations` → `sash.hoverBorder` to the resize color (mint) in `%APPDATA%\VSCodium\User\settings.json` (with a backup in `settings.json.bak`).
3. **Ask the user to restart VSCodium completely** (File → Exit, then start it again). A plain "Reload Window" is not enough for the checksum.
4. **Check:** the strips on the left, right, bottom, in the middle and along the top glow blue, and the draggable ones turn mint while you drag them.

## Order with claude-code-blue

If both skills are run, run `claude-code-blue` first and this one second. Both can edit the extension's `webview\index.css`.

## Undo

```powershell
powershell -ExecutionPolicy Bypass -File ".\make-blue-mega.ps1" -Undo
```
This removes the CSS blocks, recalculates the checksum and removes `sash.hoverBorder`. Then restart VSCodium.

## Notes

- Run the script again after every VSCodium update, because the update replaces the workbench CSS. Also run it after every Claude Code update, which installs a new extension folder.
- Styled are the main layout dividers (`$selMain`) and the dividers between editor groups (`$selEdit`). Dividers inside views (for example in a diff or merge editor) keep the default look, but they also take the resize color on hover.
- The top strip is the `:before` element of `.part.editor`. VSCodium uses only `:after` there, for the light-theme shadow.
- If a future VSCodium version changes the markup, open `Help → Toggle Developer Tools`, select a divider (`.monaco-sash`) and adjust `$selMain` / `$selEdit` in the script.
