# Changelog

## [Unreleased]

## [0.1.4] - 2026-01-23

### Added
- Warning validation: Validators can return `Clack::Warning.new(message)` for soft failures that allow user confirmation
- Built-in warning validators: `Validators.file_exists_warning` and `Validators.as_warning(validator)`
- Test coverage for warning state machine and multiselect keyboard shortcuts

### Changed
- Simplified Multiselect implementation by using base class warning/error handling (37 lines → 12 lines)
- Unified validation message rendering across all prompt types

## [0.1.2]

### Added
- `multiline_text` prompt for multi-line input (Ctrl+D to submit)
- `help:` option on all prompts for contextual help text
- Documentation for blocking validation (database/API calls work out of the box)

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
