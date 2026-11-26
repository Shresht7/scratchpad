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
.DESCRIPTION
    Lists files in the scratchpad directory
#>
function Get-Scratchpad {
    if (Test-Path -LiteralPath $script:ScratchpadDirectory -PathType Container) {
        Get-ChildItem -LiteralPath $script:ScratchpadDirectory
    }
}

<#
.SYNOPSIS
    Open scratchpad
.DESCRIPTION
    Opens a scratchpad file
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

<#
.SYNOPSIS
    Core logic
#>
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
    Uses $env:EDITOR to open the file.
.DESCRIPTION
    Opens a scratchpad file in the editor specified by $env:EDITOR
#>
function Invoke-ScratchpadEditor {
    param(
        # Path to the file to open
        [Parameter(Mandatory)]
        [string]$Path
    )

    # Get editor from environment
    $editor = $env:EDITOR
    if ([string]::IsNullOrWhiteSpace($editor)) {
        throw 'EDITOR is not set. Set it to the editor command to use.'
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

    # Check if editor exists
    if (-not (Get-Command -Name $editorExecutable -ErrorAction SilentlyContinue)) {
        throw "Editor not found: $editorExecutable"
    }

    # Build arguments for editor
    $arguments = @($editorArguments) + @($Path)

    # Run the editor with arguments
    & $editorExecutable @arguments
}

<#
.SYNOPSIS
    Show the contents of a scratchpad
.DESCRIPTION
    Shows the contents of a scratchpad file.
    If no name is given, fzf is used to select one.
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
.DESCRIPTION
    Deletes the specified scratchpad file
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
        # Validate name
        if ($Name -match '[/\\]' -or $Name -in @('.', '..')) {
            throw 'Name must be a filename, not a path'
        }

        # Build full path to scratchpad
        $path = Join-Path $script:ScratchpadDirectory $Name

        # Check if file exists
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Scratchpad not found: $Name"
        }

        # Confirm removal
        if ($PSCmdlet.ShouldProcess($path, 'Remove scratchpad')) {
            Remove-Item -LiteralPath $path -Confirm:$false
        }
    }
}

<#
.SYNOPSIS
    Open, list, view, or remove scratchpad notes.
.DESCRIPTION
    With no subcommand, opens the default or named scratchpad. Piped text replaces
    the selected note before it is opened; the saved contents are then sent to the
    PowerShell pipeline.
.EXAMPLE
    scratchpad
.EXAMPLE
    scratchpad meeting
.EXAMPLE
    git diff | scratchpad request
.EXAMPLE
    scratchpad list
.EXAMPLE
    scratchpad view meeting
.EXAMPLE
    scratchpad rm meeting
#>
function Invoke-Scratchpad {
    [CmdletBinding()]
    param(
        # A scratchpad name or positional subcommand such as `list`, `view`, or `rm`
        [Parameter(Position = 0)]
        [string]$Name,

        # The name argument for subcommands such as `view` and `rm`
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
        if ($Help -or $Name -in @('help', '--help', '-h', '?')) {
            Get-Help Open-Scratchpad
            return
        }

        if ($Version -or $Name -in @('version', '--version', '-v')) {
            $moduleVersion = $ExecutionContext.SessionState.Module.Version
            Write-Output "v$moduleVersion"
            return
        }

        if ($Directory -or $Name -in @('dir', '--dir', '-d', '--directory')) {
            Get-ScratchpadDirectory
            return
        }

        if ($List -or $Name -in @('list', 'ls', '--list', '-l')) {
            Get-Scratchpad
            return
        }

        if ($Name -in @('view', '--view')) {
            Show-Scratchpad -Name $Argument
            return
        }

        if ($Remove -or $Name -in @('rm', '--rm', '-r')) {
            if ($Name -in @('rm', '--rm', '-r')) {
                $removeName = $Argument
            }
            else {
                # For "scratchpad -r note", the note binds to $Name.
                $removeName = if ($Argument) { $Argument } else { $Name }
            }

            if ([string]::IsNullOrWhiteSpace($removeName)) {
                throw 'Specify a scratchpad name to remove.'
            }

            Remove-Scratchpad -Name $removeName
            return
        }

        # No subcommand: open the default or named scratchpad.
        Invoke-ScratchpadCore `
            -Name $Name `
            -HasPipelineInput $hasPipelineInput `
            -InputLines $inputLines.ToArray()
    }
}

Set-Alias -Name scratchpad -Value Invoke-Scratchpad
