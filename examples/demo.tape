# Clack Ruby Demo
# Run: vhs examples/demo.tape

Output examples/demo.gif

Set Shell "bash"
Set FontSize 24
Set Width 1000
Set Height 700
Set Theme "Catppuccin Mocha"
Set Padding 20
Set Framerate 30
Set PlaybackSpeed 0.5
Set TypingSpeed 50ms

Type "ruby examples/full_demo.rb"
Enter
Sleep 800ms

# Project name - just type a valid one
Type "my-app"
Sleep 200ms
Enter
Sleep 500ms

# Password - triggers entropy warning, pause to read, then confirm
Type "secretpw1"
Sleep 200ms
Enter
Sleep 600ms
# Warning: "This password may be easy to guess"
Sleep 1.2s
Enter
Sleep 500ms

# TypeScript? Yes
Enter
Sleep 400ms

# Framework - pick Rails (default)
Enter
Sleep 400ms

# Database - "p" for PostgreSQL
Type "p"
Sleep 400ms

# Dependencies - pick RSpec and RuboCop
Space
Down@3
Space
Sleep 200ms
Enter
Sleep 400ms

# Autocomplete - type "api"
Type "api"
Sleep 300ms
Enter
Sleep 400ms

# Group multiselect - GitHub Actions + Docker
Down
Space
Down@3
Space
Sleep 200ms
Enter
Sleep 400ms

# Config file - accept default, confirm overwrite warning
Enter
Sleep 500ms
Enter
Sleep 400ms

# Watch progress/tasks
Sleep 2.5s

# Final output
Sleep 1.5s
