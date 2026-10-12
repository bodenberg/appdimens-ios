# Troubleshooting

## Values look unscaled
Ensure `.appDimens()` wraps the scene root, or use `AppDimensProvider`. In UIKit or AppKit, call `AppDimens.startAutomaticUpdates()` once at launch. The environment default is only a safe preview fallback.

## Two views produce different values
They should not when they belong to the same scene. Never construct configurations from child bounds. In UIKit, call `DimensConfiguration.current(in: view)` only to discover the hosting window.

## Text is too large
Do not combine `ssp`/`@ScaledDimension(text:)` with a second manual Dynamic Type multiplier.

## Split View does not update
Place the provider above navigation and presentation containers so its `GeometryReader` observes the root window allocation.

## Physical measurements are inaccurate
Points are typographic units, not guaranteed physical measurements, and the default `pointsPerInch` is only an estimate for each device idiom. Pass a calibrated points-per-inch value (physical PPI divided by `displayScale`) to the `DimenPhysicalUnits` conversions when you need physical accuracy.

## CI SDK build fails
Run the exact `xcodebuild` destination from `.github/workflows/ci.yml`. SwiftPM tests on Linux cannot validate UIKit, SwiftUI SDK availability, or Metal framework signatures.
