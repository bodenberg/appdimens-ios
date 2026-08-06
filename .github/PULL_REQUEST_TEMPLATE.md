## Summary

- What changed?
- Why is it needed?

## Compatibility

- [ ] Preserves the single window/scene configuration invariant.
- [ ] Documents Android → Apple semantic differences.
- [ ] Avoids child-view bounds as the global scaling source.
- [ ] Updates public documentation for API changes.

## Validation

- [ ] `swift package dump-package`
- [ ] `swift test --parallel`
- [ ] `swift test --sanitize=thread`
- [ ] `swift build -c release`
- [ ] Relevant Apple SDK `xcodebuild` validation
- [ ] `python3 .github/scripts/validate_repository.py`
