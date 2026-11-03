# claude-code-blue-mega
# Makes the VSCodium layout dividers (sashes: left, right, bottom, between editor groups)
# and a strip along the top of the editor a glowing blue strip at all times,
# and mint while hovering / resizing.
# Usage:
#   powershell -ExecutionPolicy Bypass -File make-blue-mega.ps1          # apply
#   powershell -ExecutionPolicy Bypass -File make-blue-mega.ps1 -Undo    # remove
# Replaces a claude-code-mint-mega patch too, so only one of the two is active.

param([switch]$Undo)

# ---- colors -------------------------------------------------------------
$name      = "claude-code-blue-mega"
$restColor = "#0078d4"         # dividers at rest (VSCodium focus blue, same as claude-code-blue)
$restRgb   = "0,120,212"
$dragColor = "#2ec767"         # while hovering / resizing (mint)
$dragRgb   = "46,199,103"
$glow      = 6                 # glow radius in px (0 = no glow)
$stripSize = 2                 # strip width in px (VSCodium default 4)
$chatScrollbar = $false        # $true = restyle the Claude Code chat scrollbar; $false = original look
$scrollbarSize = 5             # Claude Code chat scrollbar width in px (VSCodium default 10)
$thumbRgb  = $dragRgb          # chat scrollbar thumb color (RGB)
# ------------------------------------------------------------------------

$ErrorActionPreference = "Stop"
$markStart = "/* ${name}:start */"
$markEnd   = "/* ${name}:end */"
$cssRel    = "vs/workbench/workbench.desktop.main.css"

$roots = @(
    "$env:LOCALAPPDATA\Programs\VSCodium",
    "$env:ProgramFiles\VSCodium"
) | Where-Object { Test-Path (Join-Path $_ "resources\app\out\$cssRel") }

if (-not $roots) { Write-Host "VSCodium installation not found." -ForegroundColor Red; exit 1 }

# main layout dividers (left / right / bottom) and dividers between editor groups (middle)
$selMain = ".monaco-workbench>.monaco-grid-view .monaco-sash:not(.part .monaco-sash):not(.disabled)"
$selEdit = ".monaco-workbench .part.editor>.content .monaco-grid-view .monaco-sash:not(.editor-instance .monaco-sash):not(.disabled)"
$rest  = "background:$restColor;box-shadow:0 0 ${glow}px 1px rgba($restRgb,.55);transition:background-color .15s ease-out,box-shadow .15s ease-out"
$hover = "background:var(--vscode-sash-hoverBorder,$dragColor);box-shadow:0 0 $($glow+2)px 2px rgba($dragRgb,.6)"
# top strip: closes the frame along the top edge of the editor area
$block = @"
$markStart
$selMain,$selEdit,.monaco-workbench .part.editor{--vscode-sash-hover-size:${stripSize}px}
$selMain`:before,$selEdit`:before{$rest}
$selMain.hover:before,$selMain.active:before,$selEdit.hover:before,$selEdit.active:before{$hover}
.monaco-workbench .part.editor:before{content:"";position:absolute;top:0;left:0;right:0;height:var(--vscode-sash-hover-size,4px);z-index:36;pointer-events:none;$rest}
$markEnd
"@

$utf8 = New-Object System.Text.UTF8Encoding($false)
# matches the block of this skill and of its twin (claude-code-mint-mega / claude-code-blue-mega)
$anyStart = '/\* claude-code-(?:mint|blue)-mega:start \*/'
$pattern = "(?s)\r?\n?" + $anyStart + '.*?/\* claude-code-(?:mint|blue)-mega:end \*/' + "\r?\n?"

foreach ($root in $roots) {
    $app = Join-Path $root "resources\app"
    $cssPath = Join-Path $app "out\$cssRel"
    $productPath = Join-Path $app "product.json"
    Write-Host "VSCodium: $root"

    $css = [System.IO.File]::ReadAllText($cssPath, $utf8)
    if ($css -notmatch $anyStart) {
        Copy-Item $cssPath "$cssPath.orig" -Force           # fresh (or updated) install: keep original
        Copy-Item $productPath "$productPath.orig" -Force
    }
    $css = [regex]::Replace($css, $pattern, "")
    if (-not $Undo) { $css = $css.TrimEnd() + "`n" + $block + "`n" }
    [System.IO.File]::WriteAllText($cssPath, $css, $utf8)

    # update the checksum so VSCodium does not report a corrupt installation
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = [Convert]::ToBase64String($sha.ComputeHash([System.IO.File]::ReadAllBytes($cssPath))).TrimEnd('=')
    $product = [System.IO.File]::ReadAllText($productPath, $utf8)
    $keyPattern = '("' + [regex]::Escape($cssRel) + '"\s*:\s*")[^"]*(")'
    if ($product -match $keyPattern) {
        $product = [regex]::Replace($product, $keyPattern, "`${1}$hash`${2}")
        [System.IO.File]::WriteAllText($productPath, $product, $utf8)
        Write-Host "  checksum updated"
    } else {
        Write-Host "  no checksum entry for the CSS (nothing to update)"
    }
    if ($Undo) { Write-Host "  divider patch removed" -ForegroundColor Yellow }
    else       { Write-Host "  divider patch applied (rest $restColor, resize $dragColor)" -ForegroundColor Green }
}

# ---- Claude Code chat scrollbar (optional) -----------------------------
# The chat container sets `scrollbar-color`, which makes Chromium ignore all
# ::-webkit-scrollbar rules, so it is reset to auto first.
# Thumb: 60 % at rest, 85 % on hover, solid while dragging. Track transparent.
$sbBlock = @"
$markStart
*{scrollbar-color:auto!important}
::-webkit-scrollbar{width:${scrollbarSize}px!important;height:${scrollbarSize}px!important}
::-webkit-scrollbar-track,::-webkit-scrollbar-corner{background:transparent!important}
::-webkit-scrollbar-thumb{background-color:rgba($thumbRgb,.6)!important;border-radius:${scrollbarSize}px}
::-webkit-scrollbar-thumb:hover{background-color:rgba($thumbRgb,.85)!important}
::-webkit-scrollbar-thumb:active{background-color:rgb($thumbRgb)!important}
$markEnd
"@
$extRoots = @("$env:USERPROFILE\.vscode-oss\extensions", "$env:USERPROFILE\.vscodium\extensions") | Where-Object { Test-Path $_ }
foreach ($er in $extRoots) {
    Get-ChildItem $er -Directory -Filter "anthropic.claude-code-*" | ForEach-Object {
        $wc = Join-Path $_.FullName "webview\index.css"
        if (-not (Test-Path $wc)) { return }
        if (-not (Test-Path "$wc.orig")) { Copy-Item $wc "$wc.orig" }   # claude-code-mint / -blue may already have one
        $c = [System.IO.File]::ReadAllText($wc, $utf8)
        $c = [regex]::Replace($c, $pattern, "")
        $on = $chatScrollbar -and -not $Undo
        if ($on) { $c = $c.TrimEnd() + "`n" + $sbBlock + "`n" }
        [System.IO.File]::WriteAllText($wc, $c, $utf8)
        Write-Host "Chat scrollbar: $($_.Name) $(if ($on) {"${scrollbarSize}px, custom thumb"} else {'original'})"
    }
}

# ---- settings.json: hover/resize color for all sashes -----------------
$settingsPath = "$env:APPDATA\VSCodium\User\settings.json"
if (Test-Path $settingsPath) {
    Copy-Item $settingsPath "$settingsPath.bak" -Force
    $s = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $s.'workbench.colorCustomizations') {
        $s | Add-Member -NotePropertyName 'workbench.colorCustomizations' -NotePropertyValue ([pscustomobject]@{})
    }
    $cc = $s.'workbench.colorCustomizations'
    if ($Undo) { $cc.PSObject.Properties.Remove('sash.hoverBorder') }
    else { $cc | Add-Member -NotePropertyName 'sash.hoverBorder' -NotePropertyValue $dragColor -Force }
    [System.IO.File]::WriteAllText($settingsPath, ($s | ConvertTo-Json -Depth 20), $utf8)
    Write-Host "settings.json updated (sash.hoverBorder = $(if ($Undo) {'removed'} else {$dragColor}))"
}

Write-Host "Done. Restart VSCodium completely (File > Exit, then start again)."
