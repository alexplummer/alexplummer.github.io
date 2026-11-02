# alexplummer.github.io

Public website for my Android apps, served by GitHub Pages at <https://alexplummer.github.io/>.
Each app gets a landing page and the privacy policy URL that Google Play asks for:

| App | Landing page | Privacy policy |
|-----|--------------|----------------|
| Iron Interval | <https://alexplummer.github.io/interval-timer/> | <https://alexplummer.github.io/interval-timer/privacy/> |

Plain HTML and one stylesheet (`assets/style.css`, light and dark), no build step. `.nojekyll` makes Pages serve
the files as they are.

## Layout

```
index.html                  home page, lists every app between the <!-- apps --> markers
assets/style.css
templates/app.html          landing page template
templates/privacy.html      privacy policy template
<slug>/index.html           generated landing page
<slug>/icon.png             512×512 Play icon
<slug>/privacy/index.html   generated privacy policy
scripts/new-app.ps1
```

## Adding or updating an app

```powershell
.\scripts\new-app.ps1 -Slug <slug> -Name '<App name>' -PrivacyMarkdown <path to privacy-policy.md> `
  [-Description '<one line>'] [-Icon <path to icon.png>] [-PlayUrl <Google Play URL>]
```

- Needs PowerShell 7 (uses the built-in `ConvertFrom-Markdown`; the policy text is converted, not edited).
- `-Description` is usually the Play `short-description.txt`, `-Icon` the Play `graphics/icon/icon.png`.
- Without `-PlayUrl` the landing page says "Coming soon to Google Play". Once the app is live, rerun with
  `-PlayUrl https://play.google.com/store/apps/details?id=<package>`.
- Rerunning is safe: it rewrites that app's pages (keeping its icon if `-Icon` is left out) and replaces its home
  page entry. Rerun it whenever the app's privacy policy changes.

Then commit and push; Pages publishes in a minute or two. The privacy URL is `https://alexplummer.github.io/<slug>/privacy/`.

Example (Iron Interval, which keeps its original `interval-timer` slug so the Play Console URL never changed):

```powershell
$play = 'C:\Git\interval-timer\app\src\main\play\listings\en-GB'
.\scripts\new-app.ps1 -Slug interval-timer -Name 'Iron Interval' `
  -PrivacyMarkdown C:\Git\interval-timer\docs\privacy-policy.md `
  -Description (Get-Content "$play\short-description.txt" -Raw) -Icon "$play\graphics\icon\icon.png"
```
