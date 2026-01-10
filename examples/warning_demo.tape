# VHS Tape for Validation Warnings Demo
# Run: vhs examples/warning_demo.tape

Output examples/warning_demo.gif

Set Shell "bash"
Set FontSize 28
Set Width 900
Set Height 600
Set Theme "Catppuccin Mocha"
Set Padding 20
Set Framerate 30
Set PlaybackSpeed 0.6
Set TypingSpeed 60ms

Type "ruby examples/warning_demo.rb"
Enter
Sleep 1s

# 1. Password - type short password, see warning, confirm
Type "abc"
Sleep 400ms
Enter
Sleep 800ms
# Warning shown: "Weak password"
# Press Enter to confirm
Enter
Sleep 800ms

# 2. Output file - README.md exists, warning shown, confirm
Sleep 400ms
Enter
Sleep 800ms
# Warning: "File exists. Overwrite?"
Enter
Sleep 800ms

# 3. Description - type long text, see warning, confirm
Type "A Ruby CLI prompts library"
Sleep 400ms
Enter
Sleep 800ms
# Warning: "Consider keeping this shorter"
Enter
Sleep 800ms

# 4. Username - type with uppercase, see warning, fix it
Type "MyProject"
Sleep 400ms
Enter
Sleep 800ms
# Warning: "Lowercase recommended for compatibility"
# Fix it instead of confirming
Backspace@9
Sleep 300ms
Type "myproject"
Sleep 400ms
Enter
Sleep 1s

# Show final output
Sleep 2s
