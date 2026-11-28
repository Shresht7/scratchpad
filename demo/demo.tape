Output demo/demo.gif

Require nano
Require jq

Set Shell "bash"
Set FontSize 20
Set Width 1200
Set Height 600
Set Padding 24
Set Theme "Catppuccin Mocha"
Set WindowBar ColorfulRight
Set Margin 20
Set MarginFill "#7b7b7b"
Set BorderRadius 10
Set TypingSpeed 50ms

Env EDITOR "nano"
Env PS1 "$ "

Hide
Type "rm -rf /tmp/scratchpad-vhs-demo && mkdir -p /tmp/scratchpad-vhs-demo && cd /tmp/scratchpad-vhs-demo"
Enter
Type "printf 'INFO  app started\nERROR connection timeout\nINFO  retrying\nERROR permission denied\nINFO  shutting down\n' > app.log"
Enter
Type "clear"
Enter
Show

# First run: draft in editor, pipe to jq
Type "scratchpad | jq ."
Sleep 750ms
Enter

Sleep 1s
Type "{"
Enter
Type `  "name": "v1",`
Enter
Type `  "kind": "demo"`
Enter
Type "}"
Sleep 1s

Ctrl+O
Sleep 750ms
Enter
Sleep 750ms
Ctrl+X

Sleep 1s

# Second run: reopen persisted scratchpad, edit, pipe again
Type "scratchpad | jq .name"
Sleep 750ms
Enter

Sleep 1s
Ctrl+W
Sleep 500ms
Type@120ms "v1"
Sleep 500ms
Enter
Sleep 500ms
Ctrl+D
Sleep 250ms
Ctrl+D
Sleep 250ms
Type@120ms "v2"
Sleep 1s

Ctrl+O
Sleep 750ms
Enter
Sleep 750ms
Ctrl+X

Sleep 1s

# Third run: reopen persisted scratchpad, edit, pipe again
Type "scratchpad | jq ."
Sleep 750ms
Enter

Sleep 1s
Ctrl+W
Sleep 500ms
Type@120ms "v2"
Sleep 500ms
Enter
Sleep 500ms
Ctrl+D
Sleep 250ms
Ctrl+D
Sleep 250ms
Type@120ms "v3"
Sleep 1s

Ctrl+O
Sleep 750ms
Enter
Sleep 750ms
Ctrl+X

Sleep 1s

# Pipeline: keep only ERROR lines in the editor
Type "cat app.log | scratchpad | wc -l"
Sleep 750ms
Enter

Sleep 1s
Ctrl+W
Sleep 500ms
Type@120ms "INFO"
Sleep 500ms
Enter
Sleep 500ms
Ctrl+K
Sleep 500ms

Ctrl+W
Sleep 500ms
Type@120ms "INFO"
Sleep 500ms
Enter
Sleep 500ms
Ctrl+K
Sleep 500ms

Ctrl+W
Sleep 500ms
Type@120ms "INFO"
Sleep 500ms
Enter
Sleep 500ms
Ctrl+K
Sleep 1s

Ctrl+O
Sleep 750ms
Enter
Sleep 750ms
Ctrl+X

Sleep 2s
