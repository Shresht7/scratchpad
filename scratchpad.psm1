# Directory for scratchpad files
$script:ScratchpadDirectory = Join-Path $HOME ".cache" "scratchpad"

# Default scratchpad name
$script:DefaultScratchpad = "scratchpad"

<#
.SYNOPSIS
    Output scratchpad directory
#>
function Get-ScratchpadDirectory {
    Write-Output $script:ScratchpadDirectory
}

<#
.SYNOPSIS
    Get scratchpad files
#>
function Get-Scratchpad {
    if (Test-Path -LiteralPath $script:ScratchpadDirectory -PathType Container) {
        Get-ChildItem -LiteralPath $script:ScratchpadDirectory
    }
}

<#
.SYNOPSIS
    Open scratchpad
.EXAMPLE
    Open-Scratchpad
    Opens the default scratchpad file
.EXAMPLE
    Open-Scratchpad -Name notes
    Opens the notes scratchpad
.EXAMPLE
    git diff | Open-Scratchpad | Out-File -FilePath scratch.txt
    Opens with piped input and write output to file
#>
function Open-Scratchpad {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Name,

        [Parameter(ValueFromPipeline)]
        [AllowNull()]
        [object]$InputObject
    )

    begin {
        $hasPipelineInput = $MyInvocation.ExpectingInput
        $InputLines = [System.Collections.Generic.List[string]]::new()
    }

    process {
        if ($hasPipelineInput) {
            $InputLines.Add([string]$InputObject)
        }
    }

    end {
        Invoke-ScratchpadCore -Name $Name -HasPipelineInput $hasPipelineInput -InputLines $InputLines.ToArray()
    }
}

function Invoke-ScratchpadCore {
    param(
        [string]$Name,
        [bool]$HasPipelineInput,
        [string[]]$InputLines = @()
    )

    # Use default name if none provided
    if ([string]::IsNullOrEmpty($Name)) {
        $Name = $script:DefaultScratchpad
    }

    # Keep names to a single file inside the scratchpad directory
    if ($Name -match '[/\\]' -or $Name -in @('.', '..')) {
        throw 'Name must be a filename, not path'
    }

    # Ensure scratchpad directory exists
    if (-not (Test-Path $script:ScratchpadDirectory)) {
        New-Item -ItemType Directory -Path $script:ScratchpadDirectory | Out-Null
    }

    # Get full path to scratchpad file
    $ScratchpadFile = Join-Path $script:ScratchpadDirectory $Name

    if ($HasPipelineInput) {
        $inputText = [string]::Join([System.Environment]::NewLine, $InputLines)
        if ($InputLines.Count -gt 0) {
            $inputText += [System.Environment]::NewLine
        }
        # Piped text replaces the selected scratchpad's content
        [System.IO.File]::WriteAllText($ScratchpadFile, $inputText)
    }
    elseif (-not (Test-Path -LiteralPath $ScratchpadFile -PathType Leaf)) {
        # Create an empty file only for interactive use
        [System.IO.File]::WriteAllText($ScratchpadFile, '')
    }

    # Open the file in the editor
    Invoke-ScratchpadEditor -Path $ScratchpadFile

    # Return the saved text to the PowerShell pipeline
    Get-Content -LiteralPath $ScratchpadFile -Raw
}

<#
.SYNOPSIS
    Uses $env:SCRATCHPAD_EDITOR, $env:EDITOR or $env:VISUAL to open the file.
#>
function Invoke-ScratchpadEditor {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $editor = $env:SCRATCHPAD_EDITOR
    if ([string]::IsNullOrWhiteSpace($editor)) {
        $editor = $env:EDITOR
    }
    if ([string]::IsNullOrWhiteSpace($editor)) {
        $editor = $env:VISUAL
    }
    if ([string]::IsNullOrWhiteSpace($editor)) {
        throw 'No editor configured. Set $Env:SCRATCHPAD_EDITOR, $Env:EDITOR or $Env:VISUAL (e.g. $Env:EDITOR="code --wait")'
    }

    # Split editor into command and args if needed
    $editorExecutable = $editor
    $editorArguments = @()

    # Allow either an executable path or a simple command with arguments, such as "code --wait"
    if (-not (Get-Command -Name $editorExecutable -ErrorAction SilentlyContinue)) {
        $editorParts = $editor -split '\s+'
        $editorExecutable = $editorParts[0]
        if ($editorParts.Count -gt 1) {
            $editorArguments = @($editorParts[1..($editorParts.Count - 1)])
        }
    }

    if (-not (Get-Command -Name $editorExecutable -ErrorAction SilentlyContinue)) {
        throw "Editor not found: $editorExecutable"
    }

    # Run the editor with arguments
    $arguments = @($editorArguments) + @($Path)
    & $editorExecutable @arguments
}

<#
.SYNOPSIS
    Show the contents of a scratchpad
.DESCRIPTION
    Shows the contents of a scratchpad file.
    If no name is given, an interactive fzf picker is used (requires fzf)
#>
function Show-Scratchpad {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Name
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $entries = @(
            Get-Scratchpad | ForEach-Object {
                "$($_.Name)`t$($_.FullName)"
            }
        )

        if ($entries.Count -eq 0) {
            return
        }

        $fzfCommand = Get-Command -Name fzf -CommandType Application -ErrorAction SilentlyContinue
        if (-not $fzfCommand) {
            throw 'fzf is required to choose a scratchpad when no name is provided.'
        }

        $batCommand = Get-Command -Name bat -CommandType Application -ErrorAction SilentlyContinue
        if ($batCommand) {
            $previewCommand = 'bat --color=always --style=plain --paging=never -- {2}'
        }
        elseif ($IsWindows -and $env:SHELL -notmatch '(?i)(bash|sh|zsh)') {
            $previewCommand = 'type {2}'
        }
        else {
            $previewCommand = 'cat -- {2}'
        }

        $fzfExecutable = $fzfCommand.Source
        $selection = $entries |
        & $fzfExecutable `
            --reverse `
            --delimiter "`t" `
            --with-nth 1 `
            --preview $previewCommand `
            --preview-window 'right:75%'

        $fzfExitCode = $LASTEXITCODE

        # No selection or cancelled
        if ($fzfExitCode -in @(1, 130) -or [string]::IsNullOrWhiteSpace($selection)) {
            return
        }

        if ($fzfExitCode -ne 0) {
            throw "fzf exited with code $fzfExitCode"
        }

        $Name = ($selection -split "`t", 2)[0]
    }

    if ($Name -match '[/\\]' -or $Name -in @('.', '..')) {
        throw 'Name must be a filename, not a path'
    }

    $path = Join-Path $script:ScratchpadDirectory $Name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Scratchpad not found: $Name"
    }

    Get-Content -LiteralPath $path -Raw
}

<#
.SYNOPSIS
    Remove a scratchpad file
.EXAMPLE
    Remove-Scratchpad -Name notes
    # Deletes the notes scratchpad
.EXAMPLE
    Get-Scratchpad | Where-Object { $_.Name -like '*temp*' } | Remove-Scratchpad
    # Supports pipeline input
#>
function Remove-Scratchpad {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name
    )

    process {
        if ($Name -match '[/\\]' -or $Name -in @('.', '..')) {
            throw 'Name must be a filename, not a path'
        }

        $path = Join-Path $script:ScratchpadDirectory $Name

        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Scratchpad not found: $Name"
        }

        if ($PSCmdlet.ShouldProcess($path, 'Remove scratchpad')) {
            Remove-Item -LiteralPath $path -Confirm:$false
        }
    }
}

<#
.SYNOPSIS
    Open, list, view, or remove scratchpad notes.
.DESCRIPTION
    With no action flag, opens the default or named scratchpad. Piped text replaces
    the selected note before it is opened; the saved contents are then sent to the
    PowerShell pipeline.

    Editor Resolution: $Env:SCRATCHPAD_EDITOR > $Env:EDITOR > $Env:VISUAL
.EXAMPLE
    scratchpad
.EXAMPLE
    scratchpad test.json
.EXAMPLE
    git log --oneline | scratchpad gitlog | wc -l
.EXAMPLE
    scratchpad --list
.EXAMPLE
    scratchpad --view test.json
.EXAMPLE
    scratchpad --remove test.json
#>
function Invoke-Scratchpad {
    [CmdletBinding()]
    param(
        # A scratchpad name or an action flag such as --list/--show/--remove
        [Parameter(Position = 0)]
        [string]$Name,

        # The name argument for flags such as `--show` and `--remove`
        [Parameter(Position = 1)]
        [string]$Argument,

        # Input from pipeline
        [Parameter(ValueFromPipeline = $true)]
        [AllowNull()]
        [object]$InputObject,

        # Print the scratchpad directory
        [Alias('d')]
        [switch]$Directory,

        # List available scratchpads
        [Alias('l', 'ls')]
        [switch]$List,

        # Show a scratchpad, or open the picker when no name is given
        [Alias('View', 's')]
        [switch]$Show,

        # Show command help
        [Alias('h')]
        [switch]$Help,

        # Show the module version
        [Alias('v')]
        [switch]$Version,

        # Remove a scratchpad. Provide its name as the positional argument.
        [Alias('r')]
        [switch]$Remove
    )

    begin {
        $hasPipelineInput = $MyInvocation.ExpectingInput
        $inputLines = [System.Collections.Generic.List[string]]::new()
    }

    process {
        if ($hasPipelineInput) {
            $inputLines.Add([string]$InputObject)
        }
    }

    end {
        $nameIsFlag = -not [string]::IsNullOrEmpty($Name) -and ($Name -like '-*')
        $actionName = if ($nameIsFlag) { $Name.ToLowerInvariant() } else { $null }

        if ($Help -or $actionName -in @('--help', '-h')) {
            Get-Help Invoke-Scratchpad -Detailed
            return
        }

        if ($Version -or $actionName -in @('--version', '-v')) {
            Write-Output "v$($ExecutionContext.SessionState.Module.Version)"
            return
        }

        if ($Directory -or $actionName -in @('--dir', '--directory', '-d')) {
            Get-ScratchpadDirectory
            return
        }

        if ($List -or $actionName -in @('--list', '-l')) {
            Get-Scratchpad
            return
        }

        if ($Show -or $actionName -in @('--show', '--view', '-s')) {
            $viewName = if ($actionName) { $Argument } else { $Name }
            Show-Scratchpad -Name $viewName
            return
        }

        if ($Remove -or $actionName -in @('--remove', '--rm', '-r')) {
            $removeName = if ($actionName) { $Argument } else { $Name }
            if ([string]::IsNullOrWhiteSpace($removeName)) {
                throw "Name required for remove"
            }
            Remove-Scratchpad -Name $removeName
            return
        }

        if ($nameIsFlag) {
            throw "Unknown option: $Name"
        }

        if (-not [string]::IsNullOrEmpty($Argument)) {
            throw "Expected at most one scratchpad name"
        }

        # Open the scratchpad
        Invoke-ScratchpadCore `
            -Name $Name `
            -HasPipelineInput $hasPipelineInput `
            -InputLines $inputLines.ToArray()
    }
}

Set-Alias -Name scratchpad -Value Invoke-Scratchpad

# ------------------
# ARGUMENT COMPLETER
# ------------------

$ScratchpadCompleter = {
    param($cmdName, $paramName, $wordToComplete, $commandAst, $fbParams)

    $prefix = ([string]$wordToComplete).Trim([char[]]@([char]39, [char]34))
    $candidates = [System.Collections.Generic.List[string]]::new()

    $notes = @(
        Get-Scratchpad |
        Where-Object { -not $_.PSIsContainer -and -not $_.Name.StartsWith('-') } |
        ForEach-Object { $_.Name }
    )

    $actions = @(
        '--help', '-h',
        '--version', '-v',
        '--dir', '--directory', '-d',
        '--list', '-l',
        '--show', '--view', '-s',
        '--remove', '--rm', '-r'
    )

    $isDispatcher = $cmdName -in @('Invoke-Scratchpad', 'scratchpad')
    $nameVal = [string]$fbParams['Name']
    $isShow = $fbParams.ContainsKey('Show') -or $nameVal -in ('--show', '--view', '-s')
    $isRemove = $fbParams.ContainsKey('Remove') -or $nameVal -in ('--remove', '--rm', '-r')

    if ($isDispatcher -and $paramName -eq 'Name') {
        foreach ($name in $notes) { $candidates.Add($name) }
        if ($prefix.StartsWith('-') -or $notes.Count -eq 0) {
            foreach ($action in $actions) { $candidates.Add($action) }
        }
    }
    elseif ($paramName -eq 'Name' -and -not $isDispatcher) {
        foreach ($name in $notes) { $candidates.Add($name) }
    }
    elseif ($isDispatcher -and $paramName -eq 'Argument' -and ($isShow -or $isRemove)) {
        foreach ($name in $notes) { $candidates.Add($name) }
    }

    $candidates = $candidates | Sort-Object -Unique

    foreach ($candidate in $candidates) {
        if ($candidate.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $completionText = $candidate
            if ($candidate -match '\s') {
                $completionText = "'" + $candidate.Replace("'", "''") + "'"
            }

            [System.Management.Automation.CompletionResult]::new(
                $completionText,
                $candidate,
                [System.Management.Automation.CompletionResultType]::ParameterValue,
                $candidate
            )
        }
    }
}

Register-ArgumentCompleter `
    -CommandName 'Open-Scratchpad', 'Show-Scratchpad', 'Remove-Scratchpad' `
    -ParameterName 'Name' `
    -ScriptBlock $ScratchpadCompleter

Register-ArgumentCompleter `
    -CommandName 'Invoke-Scratchpad', 'scratchpad' `
    -ParameterName 'Name' `
    -ScriptBlock $ScratchpadCompleter

Register-ArgumentCompleter `
    -CommandName 'Invoke-Scratchpad', 'scratchpad' `
    -ParameterName 'Argument' `
    -ScriptBlock $ScratchpadCompleter
