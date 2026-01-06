# VHS Tape file for recording Clack Ruby demo
# Install VHS: go install github.com/charmbracelet/vhs@latest
# Run: vhs examples/demo.tape

Output demo.gif
Output demo.mp4

Set Shell "bash"
Set FontSize 16
Set Width 800
Set Height 600
Set Theme "Catppuccin Mocha"
Set Padding 20
Set TypingSpeed 50ms

# Run the demo
Type "ruby examples/demo.rb"
Enter
Sleep 500ms

# Text prompt - enter name
Type "Alice"
Sleep 300ms
Enter
Sleep 500ms

# Password prompt - enter password
Type "secret123"
Sleep 300ms
Enter
Sleep 500ms

# Confirm prompt - press Enter for Yes
Enter
Sleep 500ms

# Select prompt - use arrow down to select Python, then Enter
Down
Sleep 200ms
Enter
Sleep 500ms

# Multiselect - space to toggle, down, space to add another, Enter
Space
Sleep 200ms
Down
Down
Sleep 200ms
Space
Sleep 200ms
Enter
Sleep 500ms

# Wait for spinner to complete
Sleep 2000ms

# Show final result
Sleep 2000ms
