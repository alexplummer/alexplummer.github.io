<#
.SYNOPSIS
  Adds (or updates) an app's landing page and privacy policy on this site.

.DESCRIPTION
  Writes <Slug>/index.html and <Slug>/privacy/index.html from templates/, converts the privacy
  policy Markdown to HTML without changing its text, copies the icon, and adds the app to the
  home page list. Safe to run again: it overwrites the app's pages and replaces its home entry.

.EXAMPLE
  .\scripts\new-app.ps1 -Slug interval-timer -Name 'Iron Interval' `
    -PrivacyMarkdown C:\Git\interval-timer\docs\privacy-policy.md `
    -Description (Get-Content C:\Git\interval-timer\app\src\main\play\listings\en-GB\short-description.txt -Raw) `
    -Icon C:\Git\interval-timer\app\src\main\play\listings\en-GB\graphics\icon\icon.png
#>
param(
  [Parameter(Mandatory)][ValidatePattern('^[a-z0-9]+(-[a-z0-9]+)*$')][string]$Slug,
  [Parameter(Mandatory)][string]$Name,
  [Parameter(Mandatory)][string]$PrivacyMarkdown,
  [string]$Description = '',
  [string]$Icon,
  # Google Play store URL; leave empty until the app is live to show "Coming soon".
  [string]$PlayUrl
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$utf8 = New-Object System.Text.UTF8Encoding $false
function Enc([string]$s) { [System.Net.WebUtility]::HtmlEncode($s) }
function Fill([string]$template, [hashtable]$values) {
  $html = [IO.File]::ReadAllText((Join-Path $root "templates\$template"), $utf8)
  foreach ($k in $values.Keys) { $html = $html.Replace("{{$k}}", $values[$k]) }
  $html
}

$Description = $Description.Trim()
$appDir = Join-Path $root $Slug
$privacyDir = Join-Path $appDir 'privacy'
New-Item -ItemType Directory -Force $privacyDir | Out-Null

if ($Icon) { Copy-Item $Icon (Join-Path $appDir 'icon.png') -Force }
$hasIcon = Test-Path (Join-Path $appDir 'icon.png')

# Landing page
$play = if ($PlayUrl) {
  "<a class=`"button`" href=`"$(Enc $PlayUrl)`">Get it on Google Play</a>"
} else {
  '<span class="button disabled">Coming soon to Google Play</span>'
}
$appHtml = Fill 'app.html' @{
  NAME        = Enc $Name
  DESCRIPTION = Enc $Description
  ICON        = if ($hasIcon) { '<img src="icon.png" alt="" width="96" height="96">' } else { '' }
  FAVICON     = if ($hasIcon) { '<link rel="icon" href="icon.png">' } else { '' }
  PLAY        = $play
}
[IO.File]::WriteAllText((Join-Path $appDir 'index.html'), $appHtml, $utf8)

# Privacy policy: Markdown converted as-is; the page title comes from its first heading.
$markdown = [IO.File]::ReadAllText((Resolve-Path $PrivacyMarkdown), $utf8)
$body = (ConvertFrom-Markdown -InputObject $markdown).Html.Trim()
$title = if ($markdown -match '(?m)^#\s+(.+?)\s*$') { $Matches[1] } else { "$Name – Privacy Policy" }
$privacyHtml = Fill 'privacy.html' @{
  TITLE   = Enc $title
  NAME    = Enc $Name
  FAVICON = if ($hasIcon) { '<link rel="icon" href="../icon.png">' } else { '' }
  BODY    = $body
}
[IO.File]::WriteAllText((Join-Path $privacyDir 'index.html'), $privacyHtml, $utf8)

# Home page entry: one line per app, tagged with its slug so a rerun replaces it.
$img = if ($hasIcon) { "<img src=`"$Slug/icon.png`" alt=`"`" width=`"56`" height=`"56`">" } else { '' }
$entry = "<li data-slug=`"$Slug`"><a class=`"app-card`" href=`"$Slug/`">$img<span><strong>$(Enc $Name)</strong><span>$(Enc $Description)</span></span></a></li>"
$homePath = Join-Path $root 'index.html'
$lines = [Collections.Generic.List[string]]([IO.File]::ReadAllLines($homePath, $utf8))
$existing = $lines.FindIndex({ param($l) $l.StartsWith("<li data-slug=`"$Slug`">") })
if ($existing -ge 0) {
  $lines[$existing] = $entry
} else {
  $end = $lines.FindIndex({ param($l) $l.Trim() -eq '<!-- /apps -->' })
  if ($end -lt 0) { throw "index.html has no <!-- /apps --> marker" }
  $lines.Insert($end, $entry)
}
[IO.File]::WriteAllText($homePath, ($lines -join "`n") + "`n", $utf8)

Write-Host "Wrote $Slug/index.html and $Slug/privacy/index.html"
Write-Host "Privacy policy URL: https://$(Split-Path $root -Leaf)/$Slug/privacy/ (live after you commit and push)"
