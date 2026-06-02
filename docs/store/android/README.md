# Play Store assets — Android

Versioned source assets for the Google Play store listing (task **15.7**).

## Contents

| Asset | File | Spec |
|---|---|---|
| App icon | `icon-512.png` | 512×512 PNG (exported from `assets/icon/icon.png`) |
| Phone screenshots | `screenshots/<locale>/<palette>/NN-screen.png` | 1080×2256 PNG |
| Feature graphic | _pending_ | 1024×500, no alpha |

## Screenshots

Captured on a real Android device (Galaxy S20 FE, 1080×2400) via an
`integration_test` harness running in **profile** mode (no debug banner).

The full matrix is **10 locales × 7 palettes × 5 screens = 350 images**:

- **Locales:** `de en es fr it ja ko pt-BR ru zh-Hans`
- **Palettes:** `macClassic macBeige gameBoy c64 zxSpectrum appleIIGreen appleIIeAmber`
- **Screens:** `01-home-rolled 02-dice-type-sheet 03-history 04-presets 05-settings`

For the store listing itself, pick ~5–6 per locale you want to publish — the
`macClassic` set plus one alternate palette (e.g. `gameBoy`) reads well.

### Regenerating

```bash
flutter drive --profile \
  --driver=integration_test/test_driver/integration_test.dart \
  --target=integration_test/store_screenshots_test.dart \
  -d <android-device-id>
```

The harness lives in `integration_test/store_screenshots_test.dart`; the driver
writes each frame to `docs/store/android/screenshots/<locale>/<palette>/`.

## Notes

- Screenshots are 24-bit RGB **with** an alpha channel and a ~2.09:1 ratio.
  Google Play accepts them as-is; if a stricter check ever rejects them,
  flatten alpha and pad to ≤2:1.
- The **feature graphic** (1024×500) is a marketing/design asset and still
  needs to be produced.
