# claude-code-blue-mega

Companion to [claude-code-blue](https://github.com/KurtStevenK/claude-code-blue). It makes the dividers between the parts of VSCodium a glowing VSCodium-blue strip at all times. By default VSCodium draws them only while you hover or drag them. They turn mint while you hover or resize. A strip of the same width runs along the top of the editor area, so the frame is closed.

Styled dividers:

- left (side bar | editor)
- right (editor | secondary side bar)
- bottom (editor | panel)
- middle (between two editor groups)
- top edge of the editor area (not draggable, always blue)

## Tested with

| Component | Version |
|---|---|
| VSCodium | 1.143.17232 (commit `c072cf642cbbadabefa22f39c58cc902a8b7427f`), user install in `%LOCALAPPDATA%\Programs\VSCodium` |
| Claude Code extension | 2.1.316 (`anthropic.claude-code-2.1.316-win32-x64`) |
| OS | Windows 11 |

Other versions may work. A VSCodium update replaces the workbench CSS, so run the script again after an update.

## Install

Install it with the [skills CLI](https://skills.sh/) (the same one `find-skills` uses):

```bash
npx skills add KurtStevenK/claude-code-blue-mega --skill claude-code-blue-mega
```

Then ask your agent to "make the VSCodium dividers blue".

Without the CLI, copy the folder `skills/claude-code-blue-mega` (it holds `SKILL.md` and the script) to `%USERPROFILE%\.claude\skills\`:

```powershell
Copy-Item .\skills\claude-code-blue-mega "$env:USERPROFILE\.claude\skills\" -Recurse -Force
```

The twin with the colors swapped (mint at rest, blue while resizing) is [claude-code-mint-mega](https://github.com/KurtStevenK/claude-code-mint-mega). Each `claude-code-*-mega` script (mint, blue, rgb) removes the others' patch, so only one is active at a time.

## Run the script yourself

The script is `skills/claude-code-blue-mega/make-blue-mega.ps1`. Run the commands below in that folder.

1. Change the settings at the top of `make-blue-mega.ps1` if you like:

   ```powershell
   $restColor = "#0078d4"    # dividers at rest (also set $restRgb)
   $dragColor = "#2ec767"    # while hovering / resizing (also set $dragRgb)
   $glow      = 6            # glow radius in px (0 = no glow)
   $stripSize = 2            # strip width in px (VSCodium default 4)
   $chatScrollbar = $false   # $true = thin Claude Code chat scrollbar in the resize color
   ```

2. Run it. VSCodium may stay open:

   ```powershell
   powershell -ExecutionPolicy Bypass -File ".\make-blue-mega.ps1"
   ```

3. Restart VSCodium completely (File → Exit, then start it again). A plain "Reload Window" is not enough.

The script can be run any number of times. Each run replaces its own block between `/* claude-code-blue-mega:start */` and `/* claude-code-blue-mega:end */`, and any other `claude-code-*-mega` block (mint, blue, rgb).

## What it changes

- `resources\app\out\vs\workbench\workbench.desktop.main.css` in the VSCodium install: the divider CSS is appended.
- `resources\app\product.json`: the checksum of that CSS file is updated, so VSCodium does not report a corrupt installation. Both files are copied to `*.orig` on the first run.
- `%APPDATA%\VSCodium\User\settings.json`: `workbench.colorCustomizations` → `sash.hoverBorder` is set to the resize color. The previous file is saved as `settings.json.bak`.
- Only if `$chatScrollbar = $true`: `webview\index.css` of the Claude Code extension gets a thin scrollbar for the chat.

## Undo

```powershell
powershell -ExecutionPolicy Bypass -File ".\make-blue-mega.ps1" -Undo
```

This removes the CSS blocks, recalculates the checksum and removes `sash.hoverBorder`. Then restart VSCodium.

## Notes

- This changes your local VSCodium install only. Nothing is redistributed.
- If a future VSCodium version changes the divider markup, open `Help → Toggle Developer Tools`, select a divider (`.monaco-sash`) and adjust `$selMain` / `$selEdit` in the script.
