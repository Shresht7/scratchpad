Output demo/demo.gif

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
Type "printf 'INFO  app started\nERROR connection timeout\nINFO  retrying\nERROR permission denied\nINFO  shutting down\n' > app.log"
Enter
Type "clear"
Enter
Show

# First run: draft in editor, pipe to jq
Type "scratchpad | jq ."
Sleep 750ms
Enter

Sleep 1.5s
Type@120ms "{"
Sleep 300ms
Enter
Type@120ms `  "name": "v1",`
Sleep 300ms
Enter
Type@120ms `  "kind": "demo"`
Sleep 300ms
Enter
Type@120ms "}"
Sleep 1s

Ctrl+O
Sleep 400ms
Enter
Sleep 400ms
Ctrl+X

Sleep 2.5s

# Second run: reopen persisted scratchpad, edit, pipe again
Type "scratchpad | jq .name"
Sleep 750ms
Enter

Sleep 1.5s
Ctrl+W
Sleep 400ms
Type@120ms "v1"
Sleep 300ms
Enter
Sleep 400ms
Ctrl+D
Sleep 250ms
Ctrl+D
Sleep 400ms
Type@120ms "v2"
Sleep 1s

Ctrl+O
Sleep 400ms
Enter
Sleep 400ms
Ctrl+X

Sleep 2.5s

# Third run: reopen persisted scratchpad, edit, pipe again
Type "scratchpad | jq ."
Sleep 750ms
Enter

Sleep 1.5s
Ctrl+W
Sleep 400ms
Type@120ms "v2"
Sleep 300ms
Enter
Sleep 400ms
Ctrl+D
Sleep 250ms
Ctrl+D
Sleep 400ms
Type@120ms "v3"
Sleep 1s

Ctrl+O
Sleep 400ms
Enter
Sleep 400ms
Ctrl+X

Sleep 2.5s

# Pipeline: keep only ERROR lines in the editor
Type "cat app.log | scratchpad | wc -l"
Sleep 750ms
Enter

Sleep 1.5s
Ctrl+W
Sleep 400ms
Type@120ms "INFO"
Sleep 300ms
Enter
Sleep 400ms
Ctrl+K
Sleep 500ms

Ctrl+W
Sleep 400ms
Type@120ms "INFO"
Sleep 300ms
Enter
Sleep 400ms
Ctrl+K
Sleep 500ms

Ctrl+W
Sleep 400ms
Type@120ms "INFO"
Sleep 300ms
Enter
Sleep 400ms
Ctrl+K
Sleep 1s

Ctrl+O
Sleep 400ms
Enter
Sleep 400ms
Ctrl+X

Sleep 3s
