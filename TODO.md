# Clack Ruby — TODO

Consolidated from 5-agent review + 4-agent iterative reviews. Last updated: 2026-02-22.

## Done (v0.4.4+)

- [x] Fix `a`/`i` shortcuts hijacking search in AutocompleteMultiselect
- [x] Fix `j`/`k`/`h`/`l` vim aliases hijacking search in both Autocomplete prompts
- [x] Add disabled option guard to AutocompleteMultiselect `toggle_current`
- [x] Add regression tests for a/i/j/k as search chars
- [x] Add cross-filter selection retention test
- [x] Document shortcut asymmetry in docstring + README
- [x] Add `examples/showcase.rb` demo

## v1.0 API Changes

- [ ] Rename Confirm labels: `active/inactive` → `yes_label/no_label` (breaking)
- [ ] Add `cursor_at` to Select and Autocomplete for consistency with Multiselect
- [ ] Document `initial_value` (singular) vs `initial_values` (plural) convention clearly
- [ ] Standardize `max_items` defaults (nil for show-all vs 5 for autocomplete) — at minimum document why
- [ ] Wizard mode — declarative multi-step flows with back navigation (`Clack.wizard`)

## Internal Consistency (AutocompleteMultiselect ↔ Multiselect alignment)

- [x] Unify `build_frame` validation: use `if @state in :error | :warning` pattern (not `lines[-1]` splice)
- [x] Change `initial_values` default from `nil` to `[]` to match Multiselect/GroupMultiselect
- [x] Rename `submit_selection` → override `submit` (match Multiselect pattern)
- [x] Rename `@selected_values` → `@selected` (match Multiselect naming)
- [x] Rename `instructions` → `keyboard_hints` (match Multiselect method name)
- [ ] Extract shared toggle-membership idiom from Multiselect + AutocompleteMultiselect

## Code Quality

- [ ] Cursor/Colors check `$stdout.tty?` not actual output stream — refactor to accept stream param
- [ ] CI mode checks `$stdin` only, ignores custom input stream — same refactor
- [ ] SIGWINCH handler not re-entrance safe — set flag instead of calling methods directly
- [ ] Merge OptionsHelper + ScrollHelper into single ListNavigationHelper (reduce cognitive load)
- [ ] Remove Transformer getter methods (pure indirection — symbol shortcuts are the idiomatic API)
- [ ] Simplify Path prompt cache and validation flow

## Documentation

- [x] Add "Why Clack?" comparison section vs tty-prompt/highline in README
- [x] Add quick reference table of all prompt types with key options and defaults
- [x] Document Ctrl+D for multiline_text submission prominently (in quick ref table)
- [ ] Document cancellation helper pattern for long flows
- [x] Add j/k unavailable note to Autocomplete README section (not just AutocompleteMultiselect)
- [x] Document `max_items` default (5) in autocomplete README sections
- [x] Add `examples/migration_from_tty_prompt.rb`
- [x] Add TL;DR at top of README

## Test Coverage Gaps

- [x] `h`/`l` vim aliases as text input chars (both autocomplete specs)
- [x] Cancel-while-no-filter-results in Autocomplete
- [x] `@selected_index` reset on filter change
- [x] Match count `"0 matches"` string format when filter is empty
- [x] Empty `options: []` → raises ArgumentError (tested)
- [x] Warning validation state in AutocompleteMultiselect
- [x] Removed unused `let(:input)` from autocomplete_spec

## Edge Cases

- [ ] Silent filtering of invalid `initial_values` in Multiselect — consider warning
- [ ] KeyReader escape timeouts hardcoded at 50ms — add env var tuning for slow SSH
- [ ] Display width calculation for CJK/emoji (grapheme clusters ≠ display columns)
- [ ] Test edge case: empty options array passed to Select/Multiselect
