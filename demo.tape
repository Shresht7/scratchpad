Output demo.gif

Require nano
Require jq

Set Shell "bash"
Set FontSize 20
Set Width 1200
Set Height 600
Set Padding 24
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms

Env EDITOR "nano"
Env PS1 "$ "

Hide
Type "rm -rf /tmp/scratchpad-vhs-demo && mkdir -p /tmp/scratchpad-vhs-demo && cd /tmp/scratchpad-vhs-demo"
Enter
Type "clear"
Enter
Show

# First run: draft in editor, pipe to jq
Type "scratchpad | jq ."
Sleep 500ms
Enter
Sleep 1s

# Edit the JSON in nano
Type "{"
Enter
Type `  "name": "v1",`
Enter
Type `  "kind": "demo"`
Enter
Type "}"
Sleep 500ms

# Save and quit nano
Ctrl+O
Enter
Ctrl+X

# jq prints the edited JSON
Sleep 2s

# Second run: Run the same command again but pipe to jq .name this time
Type "scratchpad | jq .name"
Sleep 500ms
Enter

Sleep 1s
Ctrl+W
Type "v1"
Enter
Ctrl+D
Ctrl+D
Type "v2"
Sleep 500ms

Ctrl+O
Enter
Ctrl+X

# Third run: reopen persisted scratchpad, edit, pipe again
Sleep 1s
Type "scratchpad | jq ."
Sleep 500ms
Enter

Sleep 1s
Ctrl+W
Type "v2"
Enter
Ctrl+D
Ctrl+D
Type "v3"
Sleep 500ms

Ctrl+O
Enter
Ctrl+X

# Wait a while at the end
Sleep 2s
