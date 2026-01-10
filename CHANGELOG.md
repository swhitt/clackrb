# Changelog

## [Unreleased]

## [0.2.0] - 2026-01-10

### Added
- Validation warnings: validators can return `Clack::Warning.new("message")` for soft validation that allows users to proceed with confirmation
- `Clack.warning("message")` helper for creating warnings
- `Clack::Validators.file_exists_warning` validator for file overwrite confirmation
- `Clack::Validators.as_warning(validator)` to convert any validator to return warnings instead of errors

### Fixed
- Path prompt no longer duplicates warning state handling logic

## [0.1.1]

### Fixed
- Path prompt now correctly rejects paths outside root (fixed boundary check bug)
- Password backspace properly removes Unicode grapheme clusters, not just bytes
- Terminal cleanup handles closed output streams gracefully
- SIGWINCH handler uses explicit signal check instead of rescue

### Added
- Terminal resize support via SIGWINCH signal handling

## [0.1.0]

Initial release with full prompt library.
