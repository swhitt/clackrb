# Clack

Beautiful, minimal CLI prompts for Ruby.

A Ruby port of [Clack](https://github.com/bombshell-dev/clack) by [Nate Moore](https://github.com/natemoo-re) and contributors.

## Installation

Add to your Gemfile:

```ruby
gem "clack"
```

Or install directly:

```bash
gem install clack
```

## Quick Start

```ruby
require "clack"

Clack.intro "my-app"

name = Clack.text(message: "What is your name?", placeholder: "Anonymous")
exit 0 if Clack.cancel?(name)

framework = Clack.select(
  message: "Pick a framework",
  options: [
    { value: "rails", label: "Ruby on Rails", hint: "recommended" },
    { value: "sinatra", label: "Sinatra" }
  ]
)

Clack.outro "You're all set!"
```

## Demo

Run the interactive demo:

```bash
clack-demo
```

Or from code:

```ruby
require "clack"
Clack.demo
```

## API Reference

### Session Markers

```ruby
Clack.intro("App Title")   # Start session with ┌
Clack.outro("Done!")       # End session with └
Clack.cancel("Cancelled")  # End with red message
```

### Prompts

All prompts return the value or `Clack::CANCEL` if the user pressed Ctrl+C.

```ruby
# Check for cancellation
if Clack.cancel?(result)
  puts "User cancelled"
  exit 1
end
```

#### Text Input

```ruby
name = Clack.text(
  message: "Project name?",
  placeholder: "my-app",          # Shown when empty
  default_value: "untitled",      # Used if submitted empty
  initial_value: "hello",         # Pre-filled value
  validate: ->(v) { "Required" if v.empty? }
)
```

#### Password

```ruby
secret = Clack.password(
  message: "Enter password",
  mask: "*"  # Character to show (default: ▪)
)
```

#### Confirm

```ruby
confirmed = Clack.confirm(
  message: "Continue?",
  active: "Yes",        # Text for true (default: "Yes")
  inactive: "No",       # Text for false (default: "No")
  initial_value: true   # Default selection
)
```

#### Select

```ruby
choice = Clack.select(
  message: "Pick a framework",
  options: [
    { value: "rails", label: "Ruby on Rails", hint: "recommended" },
    { value: "sinatra", label: "Sinatra" },
    { value: "disabled", label: "Coming Soon", disabled: true }
  ],
  initial_value: "rails",  # Pre-selected value
  max_items: 5             # Scroll if more options
)
```

#### Multiselect

```ruby
features = Clack.multiselect(
  message: "Select features",
  options: [
    { value: "api", label: "API Mode" },
    { value: "auth", label: "Authentication" },
    { value: "admin", label: "Admin Panel" }
  ],
  initial_values: ["api"],  # Pre-selected values
  required: true,           # Must select at least one (default: true)
  max_items: 5              # Scroll if more options
)
```

**Keyboard shortcuts:**
- `Space` - Toggle selection
- `a` - Select/deselect all
- `i` - Invert selection

#### Spinner

```ruby
s = Clack.spinner
s.start("Installing...")
# Do work...
s.message("Configuring...")  # Update message
# Do more work...
s.stop("Done!")              # Success
# Or: s.error("Failed!")     # Error
# Or: s.cancel("Cancelled")  # Cancelled
```

### Logging

```ruby
Clack.log.info("Information")
Clack.log.success("Success!")
Clack.log.step("Step completed")
Clack.log.warn("Warning")
Clack.log.error("Error")
Clack.log.message("Custom message")
```

### Note Box

```ruby
Clack.note("Welcome to your new project!", title: "Next Steps")
```

## Requirements

- Ruby 3.1+
- No runtime dependencies

## Development

```bash
bundle install
bundle exec rake          # Run lints and tests
bundle exec rake spec     # Tests only
bundle exec rake standard # Lint only
```

## Credits

This is a Ruby port of [Clack](https://github.com/bombshell-dev/clack), originally created by [Nate Moore](https://github.com/natemoo-re) and the [Astro](https://astro.build) team. The beautiful CLI aesthetic was pioneered by projects like [Astro](https://astro.build) and [Vercel](https://vercel.com).

## License

MIT License. See [LICENSE](LICENSE) for details.

This project is a port of Clack, which is also MIT licensed.
