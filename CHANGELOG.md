# Changelog

## Unreleased — complete direct port

- Ported the principal common/core/plain/scaled API with a stable window/scene configuration.
- Ported all Android satellite modules: auto, density, diagonal, fill, fit, fluid, interpolated, logarithmic, percent, perimeter, power, resize and units.
- Added aggregate `AppDimensDynamic` and Apple-specific `AppDimensMetal` products.
- Added automatic SwiftUI/UIKit window discovery and cross-module parity tests.
- Expanded the README and dedicated API, strategy, Apple integration, and performance documentation.
- Replaced the invalid package scheme CI invocation with the aggregate `AppDimensDynamic` scheme and added SDK matrices for all supported Apple platforms.
- Added workflow linting and removed unavailable `UIScreen`/user-interface-idiom paths from visionOS and Catalyst builds.
