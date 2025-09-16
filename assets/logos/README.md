# App icons placement

Put the following files here for launcher icon generation:

- `app_icon.png` — 1024x1024 PNG, transparent background (used as fallback for both platforms)
- `ic_foreground.png` — 432x432 PNG for Android adaptive icon foreground (logo glyph only, no background)
- `ic_monochrome.png` — 432x432 PNG for Android 13+ monochrome (single-color)

Optional:
- If you prefer an image background instead of a solid color for Android adaptive icon, add `ic_bg.png` and set `adaptive_icon_background: assets/logos/ic_bg.png` in `pubspec.yaml`.

After placing images, run:

```
flutter pub get
flutter pub run flutter_launcher_icons
``` 