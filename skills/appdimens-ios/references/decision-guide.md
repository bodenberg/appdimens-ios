# Strategy decision guide

1. Use scaled for ordinary spacing, sizing, and type.
2. Use width/height qualifiers when the design is explicitly axis-driven.
3. Use fit for contain behavior; fill for cover behavior.
4. Use fluid for bounded interpolation across a specified viewport band.
5. Use percent for literal fractions of a window axis.
6. Use power/logarithmic/interpolated only with a curve requirement and visual QA.
7. Use diagonal/perimeter only for canvas or unusual form-factor requirements.
8. Use density only for pixel-aware legacy behavior.
9. Use physical units only for calibrated/print-like requirements.
10. Use resize only when a monotonic predicate determines whether a candidate fits.
