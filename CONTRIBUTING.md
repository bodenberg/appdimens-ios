# Contributing to AppDimens Dynamic for Apple

Thank you for improving the Apple port. Contributions must preserve deterministic behavior and remain easy to interpret for Android AppDimens users.

## Before changing code

1. Read `Documentation/PRINCIPAL-PARITY.md` and the relevant strategy page.
2. Open an issue for breaking API or mathematical changes.
3. Keep the current-window/scene configuration as the global scaling source. A child view may locate a window but must not redefine the baseline.
4. Prefer value-semantic, `Sendable`, allocation-free calculations in hot paths.

## Development

```bash
swift package dump-package
swift test --parallel
swift test --sanitize=thread
swift build -c release
python3 .github/scripts/validate_repository.py
```

Apple framework changes must also pass the SDK matrix in `.github/workflows/ci.yml`. Do not commit build products, generated Xcode user data, credentials, images, or other binary assets.

## Pull requests

Keep each pull request focused. Explain the Android behavior, the Apple adaptation, formulas affected, multi-window and Dynamic Type implications, performance impact, and tests. Update public documentation whenever an API changes.

## Style

Use clear Swift names while retaining recognizable AppDimens terminology. Avoid global mutable caches, hidden screen singletons, unnecessary `GeometryReader` instances, per-frame allocation, and double Dynamic Type scaling.
