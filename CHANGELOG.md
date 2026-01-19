# Changelog

## [Unreleased]

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
