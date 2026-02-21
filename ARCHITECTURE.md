# Architecture

> How Clack-Ruby works under the hood.

This is a Ruby port of [Clack](https://github.com/bombshell-dev/clack), designed to be idiomatic Ruby while preserving the original's elegant UX.

## Project Structure

```
lib/
├── clack.rb                 # Public API - all user-facing methods
└── clack/
    ├── version.rb           # Gem version
    ├── colors.rb            # ANSI color helpers
    ├── environment.rb       # Terminal environment detection
    ├── symbols.rb           # Unicode/ASCII symbols
    ├── transformers.rb      # Input transformers (symbol shortcuts or procs)
    ├── utils.rb             # Text manipulation helpers (ANSI stripping, wrapping, truncation)
    ├── validators.rb        # Built-in validation helpers
    ├── core/
    │   ├── prompt.rb        # Base prompt class (state machine, rendering)
    │   ├── ci_mode.rb       # Non-interactive CI/piped-input mode
    │   ├── cursor.rb        # ANSI cursor control sequences
    │   ├── fuzzy_matcher.rb # Scored fuzzy matching for autocomplete
    │   ├── key_reader.rb    # Raw terminal input handling
    │   ├── options_helper.rb # Shared logic for Select/Multiselect
    │   ├── scroll_helper.rb # Scroll/filter behavior for dynamic lists
    │   ├── settings.rb      # Key mappings and constants
    │   └── text_input_helper.rb # Shared cursor/placeholder for text inputs
    ├── prompts/
    │   ├── text.rb          # Text input with cursor navigation
    │   ├── password.rb      # Masked input
    │   ├── confirm.rb       # Yes/No toggle
    │   ├── select.rb        # Single choice from list
    │   ├── select_key.rb    # Single choice via key press
    │   ├── multiselect.rb   # Multiple choice with toggle/invert
    │   ├── multiline_text.rb # Multi-line text input
    │   ├── group_multiselect.rb # Grouped multiple choice
    │   ├── autocomplete.rb  # Type-to-filter single select
    │   ├── autocomplete_multiselect.rb # Type-to-filter multi select
    │   ├── date.rb          # Date picker prompt
    │   ├── path.rb          # File/directory path input
    │   ├── range.rb         # Range/slider numeric selection
    │   ├── spinner.rb       # Threaded animation
    │   ├── progress.rb      # Progress bar
    │   └── tasks.rb         # Sequential task runner
    ├── group.rb             # Prompt orchestration
    ├── log.rb               # Styled logging (info, warn, error, etc.)
    ├── note.rb              # Boxed messages
    ├── box.rb               # Customizable box rendering
    ├── stream.rb            # Streaming output with symbols
    ├── task_log.rb          # Build-style streaming log
    └── testing.rb           # Test helpers (loaded on demand)
```

## Core Concepts

### State Machine

Every prompt follows this state flow:

```
initial → active → submit
                 ↘ cancel
         ↖ error ↙
         ↖ warning → (Enter confirms → submit)
```

- **initial**: First render, cursor hidden
- **active**: Accepting user input
- **error**: Validation failed (returns to active on next input)
- **warning**: Soft validation warning, user can press Enter to confirm or edit to clear
- **submit**: User confirmed, value captured
- **cancel**: User pressed Escape/Ctrl+C

### Rendering

Prompts use **differential rendering** - only redrawing when the frame changes:

```ruby
def render
  frame = build_frame
  return if frame == @prev_frame  # Skip if unchanged

  restore_cursor   # Move up to overwrite previous frame
  clear_below      # Erase stale content
  print frame
  @prev_frame = frame
end
```

The cursor restoration calculates line count from the previous frame:

```ruby
def restore_cursor
  lines = @prev_frame.to_s.count("\n")
  print Cursor.up(lines) if lines > 0
  print Cursor.column(1)
end
```

### Input Handling

Uses Ruby's `io/console` for raw terminal input (no dependencies):

```ruby
def read_key
  IO.console.raw do |io|
    char = io.getc
    return char unless char == "\e"

    # Handle escape sequences (arrow keys, etc.)
    return char unless IO.select([io], nil, nil, 0.05)
    char += io.getc.to_s
    char += io.getc.to_s if char == "\e["
    char
  end
end
```

#### Two-Layer Key Dispatch

The prompt loop calls `dispatch_key` rather than `handle_key` directly. This separation keeps warning confirmation and error clearing in the base class so every prompt participates automatically:

- **`dispatch_key(key)`** — manages warning state (Enter confirms, Escape cancels, any other input clears the warning and falls through), clears error state on any keypress, then delegates to `handle_key`.
- **`handle_key(key)`** — prompt-specific input handling. Subclasses override this (or the simpler `handle_input`) to customize behavior without worrying about warning/error transitions.

**Key mappings** (defined in `Settings`):

| Key | Action |
|-----|--------|
| `↑` `k` | up |
| `↓` `j` | down |
| `←` `h` | left |
| `→` `l` | right |
| `Enter` | submit |
| `Escape` `Ctrl+C` | cancel |
| `Space` | toggle (multiselect) |

### Cancellation

Uses a frozen sentinel object (not `nil` or `false`):

```ruby
module Clack
  CANCEL = Object.new.freeze

  def self.cancel?(value)
    value.equal?(CANCEL)
  end
end
```

This lets prompts return `nil` or `false` as valid values.

### Validation & Transformation

User input flows through a pipeline before the prompt submits:

```
User Input → Validate (raw value) → Transform (if valid) → Final Value
```

**Validation** (`validate:` option) receives the raw value and returns:
- `nil` — passes, prompt submits
- `String` — hard error, prompt enters `:error` state
- `Clack::Warning` — soft warning, prompt enters `:warning` state (user can press Enter to confirm or edit to clear)

Built-in validators live in `Clack::Validators` (required, min_length, format, email, etc.) and can be composed with `Validators.combine`. Any validator can be wrapped with `Validators.as_warning` to make it soft.

**Transformers** (`transform:` option) run after validation passes. They accept a symbol shortcut (`:strip`, `:downcase`, `:to_integer`, etc.) or a proc. Multiple transforms can be chained with `Transformers.chain(:strip, :downcase)`.

## Visual Design

### Symbols

Unicode with ASCII fallbacks for limited terminals:

```ruby
module Symbols
  def self.unicode?
    return @unicode if defined?(@unicode)
    @unicode = ENV["CLACK_UNICODE"] == "1" ||
      ($stdout.tty? && ENV["TERM"] != "dumb" && !ENV["NO_COLOR"])
  end

  S_STEP_ACTIVE = unicode? ? "◆" : "*"
  S_STEP_SUBMIT = unicode? ? "◇" : "o"
  S_STEP_CANCEL = unicode? ? "■" : "x"
  S_BAR         = unicode? ? "│" : "|"
  # ...
end
```

### Colors

ANSI escape codes with automatic disabling for non-TTY:

```ruby
module Colors
  def self.enabled?
    return true if ENV["FORCE_COLOR"] && ENV["FORCE_COLOR"] != "0"
    return false if ENV["NO_COLOR"]
    $stdout.tty?
  end

  def self.cyan(text)
    return text.to_s unless enabled?
    "\e[36m#{text}\e[0m"
  end
end
```

### State Indicators

| State | Symbol | Color |
|-------|--------|-------|
| active | ◆ | cyan |
| submit | ◇ | green |
| cancel | ■ | red |
| error | ▲ | yellow |
| warning | ▲ | yellow |

## Shared Components

### OptionsHelper

`Select` and `Multiselect` share common functionality via a mixin:

```ruby
module Core::OptionsHelper
  def normalize_options(options)   # Convert strings to hashes
  def find_next_enabled(from, delta)  # Skip disabled options
  def move_cursor(delta)           # Navigation with wrapping
  def visible_options              # Scrolling support
  def update_scroll                # Keep cursor in view
  def find_initial_cursor(value)   # Initial selection
end
```

### ScrollHelper

A mixin for scroll/filter behavior used by `Autocomplete`, `AutocompleteMultiselect`, and `Path`. These prompts display a dynamically filtered list that changes as the user types.

Including classes implement `scroll_items` to return their current filterable list. The helper provides:

- **`visible_items`** — returns the visible slice based on `@scroll_offset` and `@max_items`
- **`move_selection(delta)`** — moves `@selected_index` with wrapping
- **`update_selection_scroll`** — adjusts `@scroll_offset` to keep the selection visible

Uses `@max_items`, `@selected_index`, and `@scroll_offset` instance variables from the including class.

### FuzzyMatcher

Pure utility module for scored fuzzy matching. Used as the default filter for `Autocomplete` and `AutocompleteMultiselect`.

Matches query characters in order within the target string, scoring higher for better positions:

- `START_BONUS` — match at position zero
- `CONSECUTIVE_BONUS` — match immediately after the previous match
- `BOUNDARY_BONUS` — match at a word boundary (after space, `_`, `-`, `/`)

API:

- **`match?(query, target)`** — boolean check (characters appear in order)
- **`score(query, target)`** — numeric relevance score (0 = no match)
- **`filter(options, query)`** — filter and sort option hashes by best score across label, value, and hint

### TextInputHelper

Shared cursor, placeholder rendering, and text manipulation for prompts that accept typed input (`Text`, `Password`, `Autocomplete`, `AutocompleteMultiselect`, `Path`).

By default operates on `@value` and `@cursor`. Override `text_value` / `text_value=` to redirect to a different backing store (e.g. `@search_text` in `AutocompleteMultiselect`).

Key responsibilities:

- **`input_display`** — renders the value with an inverse cursor or a dimmed placeholder
- **`handle_text_input(key)`** — backspace, printable character insertion, cursor advancement
- Uses grapheme clusters for proper Unicode/emoji handling

### Spinner Threading

The spinner runs in a background thread. All shared state is protected by `@mutex`, and a `@finished` flag guards against double-finish:

```ruby
class Spinner
  def start(message)
    @mutex.synchronize { @running = true; @finished = false }
    @thread = Thread.new { spin_loop }
  end

  def finish(state, message)
    thread_to_join = nil
    @mutex.synchronize do
      return if @finished
      @finished = true
      @running = false
      thread_to_join = @thread
    end
    thread_to_join&.join        # join outside the mutex
    render_final(state, message)
  end
end
```

The `thread_to_join` pattern avoids holding the mutex during `Thread#join`. Reads of `@cancelled` are also mutex-protected.

## Terminal Safety

Always restore terminal state, even on interrupts:

```ruby
def run
  setup_terminal    # Hide cursor, raw mode
  # ... prompt loop ...
ensure
  cleanup_terminal  # Show cursor, cooked mode
end

# Global safety net
at_exit { print "\e[?25h" }  # Show cursor
```

A `MIN_TERMINAL_WIDTH = 40` constant is defined on `Prompt`. Before entering the input loop, `warn_narrow_terminal` prints a non-blocking yellow warning if the terminal is narrower than this threshold. The prompt continues to run regardless.

## CI Mode

`CiMode` allows prompts to run non-interactively in CI pipelines or when stdin is piped.

At the top of `Prompt#run`, `CiMode.active?` is checked before any terminal setup. When active, the prompt calls `submit` (reusing the subclass default/validation logic) and returns `@value` immediately.

Activation via settings:

- **`ci_mode: true`** — always active
- **`ci_mode: :auto`** — active when stdin is not a TTY or a CI environment variable is detected

If validation fails in CI mode, a warning is printed to the output but the value is still returned since there is no interactive way to fix the input.

## Testing

`Clack::Testing` provides first-class test helpers loaded on demand:

```ruby
require "clack/testing"
```

Two entry points:

- **`simulate(prompt_method, **kwargs, &block)`** — returns the prompt result
- **`simulate_with_output(prompt_method, **kwargs, &block)`** — returns `[result, output_string]`

The block receives a `PromptDriver` DSL for scripting interactions:

```ruby
result = Clack::Testing.simulate(Clack.method(:text), message: "Name?") do |p|
  p.type("Alice")
  p.submit
end
```

`PromptDriver` methods: `type`, `submit`, `cancel`, `up`, `down`, `left`, `right`, `toggle`, `tab`, `backspace`, `ctrl_d`, `key`.

Under the hood, `simulate` stubs `KeyReader.read` with a queue of pre-programmed inputs and directs prompt output to a `StringIO`. A safety counter raises after 100 reads to catch infinite loops.

## Prompt Implementations

### Range

Range/slider prompt for numeric selection. Displays a horizontal track using Unicode characters (`━` track, `●` handle) with the current value shown to the right. Navigate with arrow keys; step size and min/max bounds are configurable. Values are clamped and snapped to the step grid.

## API Surface

All functionality exposed through module methods:

```ruby
module Clack
  def self.text(message:, **opts)
    Prompts::Text.new(message:, **opts).run
  end

  def self.group(on_cancel: nil, &block)
    Group.new(on_cancel:).run(&block)
  end

  # ... etc
end
```

This provides a clean, discoverable API without requiring users to know the class hierarchy.

## Dependencies

**Zero runtime dependencies** - stdlib only:
- `io/console` - Raw terminal input
- `thread` - Spinner animation

Dev dependencies are for testing and code quality only.
