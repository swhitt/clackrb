# Clack

**Effortlessly beautiful CLI prompts for Ruby.**

A faithful Ruby port of [@clack/prompts](https://github.com/bombshell-dev/clack) - bringing that delightful terminal aesthetic to your Ruby projects.

```ruby
require "clack"

Clack.intro "Welcome to my-app"

name = Clack.text(message: "What's your name?")
exit if Clack.cancel?(name)

Clack.outro "Nice to meet you, #{name}!"
```

## Why Clack?

- **Zero dependencies** - Pure Ruby, stdlib only
- **Beautiful by default** - Thoughtfully designed prompts that just look right
- **Vim-friendly** - Navigate with `hjkl` or arrow keys
- **Accessible** - Graceful ASCII fallbacks for limited terminals
- **Composable** - Group prompts together with `Clack.group`

## Installation

```ruby
# Gemfile
gem "clack"

# Or from GitHub
gem "clack", github: "swhitt/clackrb"
```

```bash
# Or install directly
gem install clack
```

## Quick Start

```ruby
require "clack"

Clack.intro "project-setup"

result = Clack.group do |g|
  g.prompt(:name) { Clack.text(message: "Project name?", placeholder: "my-app") }
  g.prompt(:framework) do
    Clack.select(
      message: "Pick a framework",
      options: [
        { value: "rails", label: "Ruby on Rails", hint: "recommended" },
        { value: "sinatra", label: "Sinatra" },
        { value: "roda", label: "Roda" }
      ]
    )
  end
  g.prompt(:features) do
    Clack.multiselect(
      message: "Select features",
      options: %w[api auth admin websockets]
    )
  end
end

if Clack.cancel?(result)
  Clack.cancel("Setup cancelled")
  exit 1
end

Clack.outro "You're all set!"
```

## Demo

Try it yourself:

```bash
ruby examples/demo.rb
# or
clack-demo
```

<details>
<summary>Recording the demo GIF</summary>

Install [VHS](https://github.com/charmbracelet/vhs) and run:

```bash
vhs examples/demo.tape
```
</details>

## Prompts

All prompts return the user's input, or `Clack::CANCEL` if they pressed Escape/Ctrl+C.

```ruby
# Always check for cancellation
result = Clack.text(message: "Name?")
exit 1 if Clack.cancel?(result)
```

### Text

```ruby
name = Clack.text(
  message: "What is your project named?",
  placeholder: "my-project",       # Shown when empty (dim)
  default_value: "untitled",       # Used if submitted empty
  initial_value: "hello-world",    # Pre-filled, editable
  validate: ->(v) { "Required!" if v.empty? }
)
```

### Password

```ruby
secret = Clack.password(
  message: "Enter your API key",
  mask: "*"  # Default: "▪"
)
```

### Confirm

```ruby
proceed = Clack.confirm(
  message: "Deploy to production?",
  active: "Yes, ship it!",
  inactive: "No, abort",
  initial_value: false
)
```

### Select

Single selection with keyboard navigation.

```ruby
db = Clack.select(
  message: "Choose a database",
  options: [
    { value: "pg", label: "PostgreSQL", hint: "recommended" },
    { value: "mysql", label: "MySQL" },
    { value: "sqlite", label: "SQLite", disabled: true }
  ],
  initial_value: "pg",
  max_items: 5  # Enable scrolling
)
```

### Multiselect

Multiple selections with toggle controls.

```ruby
features = Clack.multiselect(
  message: "Select features to install",
  options: [
    { value: "api", label: "API Mode" },
    { value: "auth", label: "Authentication" },
    { value: "jobs", label: "Background Jobs" }
  ],
  initial_values: ["api"],
  required: true,     # Must select at least one
  max_items: 5        # Enable scrolling
)
```

**Shortcuts:** `Space` toggle | `a` all | `i` invert

### Autocomplete

Type to filter from a list of options.

```ruby
color = Clack.autocomplete(
  message: "Pick a color",
  options: %w[red orange yellow green blue indigo violet],
  placeholder: "Type to search..."
)
```

### Autocomplete Multiselect

Type to filter with multi-selection support.

```ruby
colors = Clack.autocomplete_multiselect(
  message: "Pick colors",
  options: %w[red orange yellow green blue indigo violet],
  placeholder: "Type to filter...",
  required: true,              # At least one selection required
  initial_values: ["red"]      # Pre-selected values
)
```

**Shortcuts:** `Space` toggle | `a` toggle all | `i` invert | `Enter` confirm

### Path

File/directory path selector with filesystem navigation.

```ruby
project_dir = Clack.path(
  message: "Where should we create your project?",
  only_directories: true,  # Only show directories
  root: "."               # Starting directory
)
```

**Navigation:** Type to filter | `Tab` to autocomplete | `↑↓` to select

### Select Key

Quick selection using keyboard shortcuts.

```ruby
action = Clack.select_key(
  message: "What would you like to do?",
  options: [
    { value: "create", label: "Create new project", key: "c" },
    { value: "open", label: "Open existing", key: "o" },
    { value: "quit", label: "Quit", key: "q" }
  ]
)
```

### Spinner

Non-blocking animated indicator for async work.

```ruby
spinner = Clack.spinner
spinner.start("Installing dependencies...")

# Do your work...
sleep 2

spinner.stop("Dependencies installed!")
# Or: spinner.error("Installation failed")
# Or: spinner.cancel("Cancelled")
```

### Progress

Visual progress bar for measurable operations.

```ruby
progress = Clack.progress(total: 100, message: "Downloading...")
progress.start

files.each_with_index do |file, i|
  download(file)
  progress.update(i + 1)
end

progress.stop("Download complete!")
```

### Tasks

Run multiple tasks with status indicators.

```ruby
results = Clack.tasks(tasks: [
  { title: "Checking dependencies", task: -> { check_deps } },
  { title: "Building project", task: -> { build } },
  { title: "Running tests", task: -> { run_tests } }
])
```

### Group Multiselect

Multiselect with options organized into groups.

```ruby
features = Clack.group_multiselect(
  message: "Select features",
  options: [
    {
      label: "Frontend",
      options: [
        { value: "react", label: "React" },
        { value: "vue", label: "Vue" }
      ]
    },
    {
      label: "Backend",
      options: [
        { value: "api", label: "REST API" },
        { value: "graphql", label: "GraphQL" }
      ]
    }
  ]
)
```

## Prompt Groups

Chain multiple prompts and collect results in a hash. Cancellation is handled automatically.

```ruby
result = Clack.group do |g|
  g.prompt(:name) { Clack.text(message: "Your name?") }
  g.prompt(:email) { Clack.text(message: "Your email?") }
  g.prompt(:confirm) { |r| Clack.confirm(message: "Create account for #{r[:email]}?") }
end

return if Clack.cancel?(result)

puts "Welcome, #{result[:name]}!"
```

Handle cancellation with a callback:

```ruby
Clack.group(on_cancel: ->(r) { cleanup(r) }) do |g|
  # prompts...
end
```

## Logging

Beautiful, consistent log messages.

```ruby
Clack.log.info("Starting build...")
Clack.log.success("Build completed!")
Clack.log.warn("Cache is stale")
Clack.log.error("Build failed")
Clack.log.step("Running migrations")
Clack.log.message("Custom message")
```

### Stream

Stream output from iterables, enumerables, or shell commands:

```ruby
# Stream from an array or enumerable
Clack.stream.info(["Line 1", "Line 2", "Line 3"])
Clack.stream.step(["Step 1", "Step 2", "Step 3"])

# Stream from a shell command (returns true/false for success)
success = Clack.stream.command("npm install", type: :info)

# Stream from any IO or StringIO
Clack.stream.success(io_stream)
```

## Note

Display important information in a box.

```ruby
Clack.note(<<~MSG, title: "Next Steps")
  cd my-project
  bundle install
  bin/rails server
MSG
```

### Box

Render a customizable bordered box.

```ruby
Clack.box("Hello, World!", title: "Greeting")

# With options
Clack.box(
  "Centered content",
  title: "My Box",
  content_align: :center,    # :left, :center, :right
  title_align: :center,
  width: 40,                 # or :auto to fit content
  rounded: true              # rounded or square corners
)
```

### Task Log

Streaming log that clears on success and shows full output on failure. Useful for build output.

```ruby
tl = Clack.task_log(title: "Building...", limit: 10)

tl.message("Compiling file 1...")
tl.message("Compiling file 2...")

# On success: clears the log
tl.success("Build complete!")

# On error: keeps the log visible
# tl.error("Build failed!")
```

## Session Markers

```ruby
Clack.intro("my-cli v1.0")  # ┌ my-cli v1.0
# ... your prompts ...
Clack.outro("Done!")        # └ Done!

# Or on error:
Clack.cancel("Aborted")     # └ Aborted (red)
```

## Requirements

- Ruby 3.2+
- No runtime dependencies

## Development

```bash
bundle install
bundle exec rake        # Lint + tests
bundle exec rake spec   # Tests only
COVERAGE=true bundle exec rake spec  # With coverage
```

## Credits

This is a Ruby port of [Clack](https://github.com/bombshell-dev/clack), created by [Nate Moore](https://github.com/natemoo-re) and the [Astro](https://astro.build) team.

## License

MIT - See [LICENSE](LICENSE)
