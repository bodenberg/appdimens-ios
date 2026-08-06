# Troubleshooting

## Values look unscaled
Ensure `.appDimens()` wraps the scene root, or use `AppDimensProvider`. The environment default is only a safe preview fallback.

## Two views produce different values
They should not when they belong to the same scene. Never construct configurations from child bounds. In UIKit, call `.current(in: view)` only to discover the hosting window.

## Text is too large
Do not combine `ssp`/`@ScaledDimension(text:)` with a second manual Dynamic Type multiplier.

## Split View does not update
Place the provider above navigation and presentation containers so its `GeometryReader` observes the root window allocation.

## Physical measurements are inaccurate
Points are typographic units, not guaranteed physical measurements. Supply known PPI when converting to pixels for calibrated hardware.

## CI SDK build fails
Run the exact `xcodebuild` destination from `.github/workflows/ci.yml`. SwiftPM tests on Linux cannot validate UIKit, SwiftUI SDK availability, or Metal framework signatures.
