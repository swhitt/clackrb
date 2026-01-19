# VHS Tape file for recording Clack Ruby demo
# Install VHS: brew install vhs
# Run: vhs examples/demo.tape

Output demo.gif
Output demo.webm

Set Shell "bash"
Set FontSize 26
Set Width 1280
Set Height 960
Set Theme {"name":"VSCode Dark","black":"#000000","red":"#f44747","green":"#6a9955","yellow":"#dcdcaa","blue":"#569cd6","magenta":"#c586c0","cyan":"#4ec9b0","white":"#d4d4d4","brightBlack":"#808080","brightRed":"#f44747","brightGreen":"#6a9955","brightYellow":"#dcdcaa","brightBlue":"#569cd6","brightMagenta":"#c586c0","brightCyan":"#4ec9b0","brightWhite":"#ffffff","background":"#000000","foreground":"#d4d4d4","selection":"#264f78","cursor":"#ffffff"}
Set Padding 20
Set Framerate 30
Set PlaybackSpeed 0.5
Set TypingSpeed 80ms
Set WaitTimeout 30s

# Run the full demo
Type "ruby examples/full_demo.rb"
Enter
Sleep 1.5s

# Text - project name
Type "acme"
Sleep 100ms
Type "-api"
Sleep 400ms
Enter
Sleep 800ms

# Password - API key
Type "sk_live"
Sleep 80ms
Type "_abc123"
Sleep 400ms
Enter
Sleep 800ms

# Multiline text - project description
Type "A fast API for the"
Sleep 200ms
Enter
Sleep 100ms
Type "ACME corporation."
Sleep 400ms
Ctrl+d
Sleep 800ms

# Confirm - Use Rails? Yes (default)
Sleep 300ms
Enter
Sleep 800ms

# Select Ruby version - pick 3.3 (down 1)
Sleep 300ms
Down
Sleep 300ms
Enter
Sleep 800ms

# Multiselect gems - pick sidekiq, rspec, rubocop
Sleep 300ms
Space
Sleep 200ms
Down
Down
Sleep 200ms
Space
Sleep 200ms
Down
Sleep 200ms
Space
Sleep 300ms
Enter
Sleep 800ms

# Select key - database: "p" for PostgreSQL
Sleep 400ms
Type "p"
Sleep 800ms

# Autocomplete template - type to filter for "API"
Type "api"
Sleep 500ms
Enter
Sleep 800ms

# Autocomplete multiselect services - pick Stripe and Sentry
Type "str"
Sleep 400ms
Space
Sleep 300ms
Backspace
Backspace
Backspace
Sleep 200ms
Type "sen"
Sleep 400ms
Space
Sleep 300ms
Enter
Sleep 800ms

# Path picker - accept current dir
Sleep 400ms
Enter
Sleep 800ms

# Group multiselect - pick Tailwind, FactoryBot, GitHub Actions
Sleep 300ms
Down
Down
Sleep 200ms
Space
Sleep 200ms
Down
Down
Sleep 200ms
Space
Sleep 200ms
Down
Down
Down
Sleep 200ms
Space
Sleep 300ms
Enter
Sleep 800ms

# Progress bar
Sleep 1500ms

# Tasks
Sleep 2500ms

# Spinner
Sleep 3000ms

# Summary and outro
Sleep 4000ms
