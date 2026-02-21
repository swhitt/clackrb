# Changelog

## [0.4.3] - 2026-02-21

### Fixed
- Multiselect variants now ignore `initial_values` that don't match any option (prevents phantom values in return)
- SIGWINCH handler now uses `.dup` for safe array iteration inside signal trap
- `GroupMultiselect` propagates `:hint` into flat items so hints actually render

### Changed
- `AutocompleteMultiselect` final frame now shows selected labels instead of "N items selected", matching `Multiselect` behavior
- Removed dead `@mutex` from `Testing` module
- Removed unused `raw:` parameter from `TaskLog` and `TaskLogGroup` message methods

## [0.4.2] - 2026-02-20

### Fixed
- `GroupMultiselect` now preserves `:hint` on options (was silently dropped during normalization)
- `GroupMultiselect` renders hints on active options, matching `Select` behavior
- `Spinner` no longer raises when finished in timer mode before the animation thread starts
- YARD docs: corrected `selectable_groups` default from `true` to `false`

### Changed
- `Range` prompt now accepts `initial_value:` for consistency with all other prompts (`default:` still works)
- README: corrected Range example to use `initial_value:` and tab completion description

## [0.4.1] - 2026-02-20

### Fixed
- `AutocompleteMultiselect` now renders warning validation messages (was error-only)
- CI mode no longer writes ANSI escape codes to non-TTY output
- CI mode prints a warning when validation fails instead of silently returning
- Spinner animation restarts from frame 0 when reused
- `Environment.raw_mode_supported?` catches specific exceptions instead of bare rescue
- `FuzzyMatcher.filter` pre-computes downcased query (performance optimization for large lists)
- Removed dead instance variables in Path, Testing, and Spinner
- Simplified `Range#clamp` by removing unreachable branch

### Changed
- Updated gem dependencies (rubocop 1.84, standard 1.54, prism 1.9, bigdecimal 4.0)
- Autocomplete YARD docs corrected: default filter is fuzzy matching, not substring
- Expanded YARD `@option` documentation for spinner, multiselect, group_multiselect, path, tasks
- README and ARCHITECTURE.md updated to cover all v0.3.0-v0.4.0 features

## [0.4.0] - 2026-02-19

### Added
- `range` slider prompt for numeric selection (`Clack.range(message:, min:, max:, step:, initial_value:)`)
- Tab completion on `text` prompt via `completions:` parameter (array or proc)
- Minimum terminal width warning (non-blocking, 40 columns)

### Changed
- Path prompt caches directory listings to avoid repeated filesystem scans on every keystroke

## [0.3.0] - 2026-02-19

### Added
- `Clack::Testing` module with first-class test helpers (`simulate`, `simulate_with_output`, `PromptDriver`)
- `Clack::Core::FuzzyMatcher` with scored fuzzy matching (consecutive/boundary/start bonuses)
- CI / non-interactive mode: `Clack.update_settings(ci_mode: true)` or `:auto` to auto-detect
- `autocomplete_multiselect` now accepts `filter:` proc for custom matching logic

### Changed
- Autocomplete prompts default to fuzzy matching instead of substring matching
- Spinner is now thread-safe: guards against double-finish, protects `@cancelled` reads with mutex

## [0.2.1] - 2026-02-19

### Added
- `Core::ScrollHelper` mixin extracted from scroll/filter logic across 3 prompts

### Changed
- `TextInputHelper` parameterized via `text_value`/`text_value=` for custom backing stores
- Tasks prompt now reuses `Core::Spinner` instead of inline spinner implementation
- Removed redundant `@value = nil` from SelectKey

## [0.2.0] - 2026-02-19

### Added
- `date` prompt for inline segmented date selection with Tab/arrow navigation and digit typing
- Date min/max enforcement: clamps values to bounds during navigation
- Date-specific validators: `Validators.future_date`, `Validators.past_date`, `Validators.date_range`
- `autocomplete` now accepts `filter:` proc for custom matching logic
- `tasks` now passes a message-update proc to task callbacks for mid-task status updates
- `tasks` now supports `enabled:` flag to conditionally skip tasks
- 100% YARD documentation coverage (was 79%)
- 30 new edge-case tests covering warning validation, transforms, date boundaries, and more

### Changed
- `Transformers.resolve` now accepts any object responding to `#call` (not just Proc)
- Standardized required-validation error messages across multiselect variants
- Extracted `dispatch_key` from `handle_key` in base `Prompt` so warning/error state transitions are handled centrally for all prompts
- Ruby idiom improvements: pattern matching, endless methods, guard clauses, `find_index`
- Gemspec now excludes dev-only files (cast, exp, gif, svg) from the gem package
- Examples include `require "clack"` alternative comment for gem users

### Fixed
- `Password#handle_input` now correctly handles backspace (was unreachable due to guard order)
- `Validators.as_warning` no longer double-wraps values that are already `Warning` instances
- `AutocompleteMultiselect` backspace was dead code (printable guard blocked it)
- `MultilineText` and `Autocomplete` now render warning validation messages (was error-only)
- Removed dead `@buffer` and `@name` instance variables from `TaskLogGroup`

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
