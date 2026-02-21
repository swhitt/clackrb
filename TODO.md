# Clack Ruby — TODO

Findings from 5-agent review (Ruby Master, Anti-Overengineering Architect, API Design Expert, New User, Terminal/CLI UX Specialist). Last updated: 2026-02-21.

## v1.0 API Changes

- [ ] Rename Confirm labels: `active/inactive` → `yes_label/no_label` (breaking)
- [ ] Add `cursor_at` to Select and Autocomplete for consistency with Multiselect
- [ ] Document `initial_value` (singular) vs `initial_values` (plural) convention clearly
- [ ] Standardize `max_items` defaults (nil for show-all vs 5 for autocomplete) — at minimum document why

## Code Quality

- [ ] Cursor/Colors check `$stdout.tty?` not actual output stream — refactor to accept stream param
- [ ] CI mode checks `$stdin` only, ignores custom input stream — same refactor
- [ ] SIGWINCH handler not re-entrance safe — set flag instead of calling methods directly
- [ ] Merge OptionsHelper + ScrollHelper into single ListNavigationHelper (reduce cognitive load)
- [ ] Remove Transformer getter methods (pure indirection — symbol shortcuts are the idiomatic API)
- [ ] Simplify Path prompt cache and validation flow

## Documentation

- [ ] Add "Why Clack?" comparison section vs tty-prompt/highline in README
- [ ] Add quick reference table of all prompt types with key options and defaults
- [ ] Document Ctrl+D for multiline_text submission prominently (non-standard gesture)
- [ ] Document cancellation helper pattern for long flows
- [ ] Add `examples/migration_from_tty_prompt.rb`
- [ ] Add TL;DR at top of README

## Edge Cases

- [ ] Silent filtering of invalid `initial_values` in Multiselect — consider warning
- [ ] KeyReader escape timeouts hardcoded at 50ms — add env var tuning for slow SSH
- [ ] Display width calculation for CJK/emoji (grapheme clusters ≠ display columns)
- [ ] Test edge case: empty options array passed to Select/Multiselect
