# AppsMenu V10 — App icon

Šī versija saglabā V9 iestatījumu logu un pievieno pilnvērtīgu macOS lietotnes ikonu.

## Jaunumi

- `AppsMenu.app` satur `Resources/AppIcon.icns`.
- `Info.plist` satur `CFBundleIconFile`.
- Instalēšanas laikā lietotne tiek lokāli ad-hoc parakstīta.
- Launch Services tiek atsvaidzināts, lai Finder un Applications parādītu jauno ikonu.
- Lietotāja kategoriju iestatījumi turpina glabāties `UserDefaults` un pārinstalējot nepazūd.

## Instalēšana

```bash
cd ~/Downloads
rm -rf AppsMenuV10-Icon
unzip AppsMenuV10-Icon.zip
cd AppsMenuV10-Icon
chmod +x install.sh uninstall.sh
./install.sh
```

Ja Finder uzreiz nerāda jauno ikonu, aizver un atver Finder logu vai izraksties un pieslēdzies no jauna. Parasti `lsregister` atsvaidzināšana instalācijas skriptā ir pietiekama.
