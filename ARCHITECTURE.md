# Clack-Ruby Architecture

Port of [Clack](https://github.com/bombshell-dev/clack) to idiomatic Ruby.

## Package Structure

```
lib/
├── clack.rb              # Main entry point, public API
└── clack/
    ├── version.rb        # VERSION constant
    ├── core/
    │   ├── prompt.rb     # Base prompt class (state machine, events, rendering)
    │   ├── cursor.rb     # Cursor navigation utilities
    │   └── settings.rb   # Global settings, key aliases
    ├── prompts/
    │   ├── text.rb       # Text input
    │   ├── password.rb   # Masked input
    │   ├── confirm.rb    # Yes/No
    │   ├── select.rb     # Single choice
    │   ├── multiselect.rb # Multiple choice
    │   └── spinner.rb    # Animated loading
    ├── log.rb            # log.info, log.warn, etc.
    ├── note.rb           # Boxed note
    ├── intro.rb          # Session start
    ├── outro.rb          # Session end
    └── symbols.rb        # Unicode symbols with ASCII fallbacks
```

## Core Concepts

### 1. State Machine

States: `initial` → `active` → `submit` | `cancel` | `error`

```ruby
module Clack::Core
  STATES = %i[initial active cancel submit error].freeze
end
```

Transitions:
- `initial` → `active`: After first render
- `active` → `submit`: Enter pressed + validation passes
- `active` → `error`: Validation fails (returns to `active` on next input)
- `active` → `cancel`: Ctrl+C or Escape pressed

### 2. Rendering Model

**Differential updates** - only redraw changed lines:

```ruby
def render
  frame = build_frame
  return if frame == @prev_frame

  restore_cursor          # Move up by number of previous lines
  clear_below             # Erase from cursor to end
  print frame
  @prev_frame = frame
end

def restore_cursor
  lines = @prev_frame.to_s.lines.count
  print "\e[#{lines}A" if lines > 0
end
```

### 3. Key Handling

Use `io/console` for raw input (no external deps):

```ruby
require 'io/console'

def read_key
  IO.console.raw do |io|
    char = io.getc
    return char unless char == "\e"

    # Read escape sequence
    return char unless IO.select([io], nil, nil, 0.05)
    char += io.getc.to_s
    char += io.getc.to_s if char == "\e["
    char
  end
end
```

Key mappings:
- `\e[A` / `k` → up
- `\e[B` / `j` → down
- `\e[C` / `l` → right
- `\e[D` / `h` → left
- `\r` → enter/submit
- `\e` / `\x03` → cancel

### 4. Cancellation Pattern

Use a unique symbol (like JS Clack):

```ruby
module Clack
  CANCEL = Object.new.freeze

  def self.cancel?(value)
    value.equal?(CANCEL)
  end
end
```

## Visual Language

### Symbols (with ASCII fallbacks)

```ruby
module Clack::Symbols
  UNICODE = $stdout.tty? && ENV['TERM'] != 'dumb'

  S_STEP_ACTIVE   = UNICODE ? '◆' : '*'
  S_STEP_CANCEL   = UNICODE ? '■' : 'x'
  S_STEP_ERROR    = UNICODE ? '▲' : 'x'
  S_STEP_SUBMIT   = UNICODE ? '◇' : 'o'

  S_RADIO_ACTIVE   = UNICODE ? '●' : '>'
  S_RADIO_INACTIVE = UNICODE ? '○' : ' '

  S_CHECKBOX_ACTIVE   = UNICODE ? '◻' : '[•]'
  S_CHECKBOX_SELECTED = UNICODE ? '◼' : '[+]'
  S_CHECKBOX_INACTIVE = UNICODE ? '◻' : '[ ]'

  S_BAR       = UNICODE ? '│' : '|'
  S_BAR_START = UNICODE ? '┌' : 'T'
  S_BAR_END   = UNICODE ? '└' : '-'

  S_INFO    = UNICODE ? '●' : '•'
  S_SUCCESS = UNICODE ? '◆' : '*'
  S_WARN    = UNICODE ? '▲' : '!'
  S_ERROR   = UNICODE ? '■' : 'x'

  # Spinner frames
  SPINNER_FRAMES = UNICODE ? %w[◒ ◐ ◓ ◑] : %w[• o O 0]
end
```

### Colors (ANSI codes)

```ruby
module Clack::Colors
  def self.gray(text)   = "\e[90m#{text}\e[0m"
  def self.cyan(text)   = "\e[36m#{text}\e[0m"
  def self.green(text)  = "\e[32m#{text}\e[0m"
  def self.yellow(text) = "\e[33m#{text}\e[0m"
  def self.red(text)    = "\e[31m#{text}\e[0m"
  def self.blue(text)   = "\e[34m#{text}\e[0m"
  def self.dim(text)    = "\e[2m#{text}\e[0m"
  def self.bold(text)   = "\e[1m#{text}\e[0m"
  def self.inverse(text) = "\e[7m#{text}\e[0m"
  def self.strikethrough(text) = "\e[9m#{text}\e[0m"
  def self.hidden(text) = "\e[8m#{text}\e[0m"
end
```

### State → Symbol/Color Mapping

| State | Symbol | Color |
|-------|--------|-------|
| initial/active | ◆ | cyan |
| submit | ◇ | green |
| cancel | ■ | red |
| error | ▲ | yellow |

## Spinner Threading

Use Ruby `Thread` (proven pattern from tty-spinner, cli-ui):

```ruby
class Spinner
  def start(message = nil)
    @message = message
    @running = true
    @thread = Thread.new { spin_loop }
  end

  def stop(message = nil)
    @running = false
    @thread&.join
    render_final(:success, message)
  end

  private

  def spin_loop
    frame_idx = 0
    while @running
      render_frame(SPINNER_FRAMES[frame_idx])
      frame_idx = (frame_idx + 1) % SPINNER_FRAMES.size
      sleep 0.08
    end
  end
end
```

## Terminal Cleanup

Always restore terminal state on exit:

```ruby
at_exit do
  print "\e[?25h"  # Show cursor
  IO.console&.cooked!
end

trap('INT') do
  print "\e[?25h"
  IO.console&.cooked!
  exit 130
end
```

## API Design

All prompts accessible via module methods:

```ruby
module Clack
  def self.text(message:, **opts)
    Prompts::Text.new(message:, **opts).run
  end

  def self.select(message:, options:, **opts)
    Prompts::Select.new(message:, options:, **opts).run
  end

  def self.spinner
    Prompts::Spinner.new
  end

  # ... etc
end
```

## Dependencies

**Zero runtime dependencies** - stdlib only:
- `io/console` - raw terminal input
- `stringio` - output buffering (if needed)

Dev dependencies for testing/quality only.
