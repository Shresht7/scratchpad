# Scratchpad Version
$manifestPath = Join-Path $PSScriptRoot 'scratchpad.psd1'
$script:ScratchpadVersion = (Import-PowerShellDataFile -Path $manifestPath).ModuleVersion

# Directory for scratchpad files
$script:ScratchpadDirectory = Join-Path $HOME ".cache" "scratchpad"

# Default scratchpad name
$script:DefaultScratchpad = "scratchpad"

<#
.SYNOPSIS
    TODO: Write the synopsis
.DESCRIPTION
    TODO: Write the description
.EXAMPLE
    TODO: Write examples
#>
function scratchpad {
    [CmdletBinding(DefaultParameterSetName = "Name")]
    param(
        [Parameter(Position = 0, ParameterSetName = "Name")]
        [string] $Name,

        # Get scratchpad directory
        [Parameter(ParameterSetName = "Directory")]
        [Alias("dir", "d")]
        [switch] $Directory,

        [Parameter(ParameterSetName = "List")]
        [Alias("l", "ls")]
        [switch] $List,

        # Show help message
        [Parameter(ParameterSetName = "Help")]
        [Alias("h")]
        [switch] $Help,

        # Show version
        [Parameter(ParameterSetName = "Version")]
        [Alias("v")]
        [switch] $Version
    )

    # Show help if requested
    if ($Help -or $Name -in @("help", "h", "?", "--help")) {
        Get-Help scratchpad
        return
    }

    # Show version if requested
    if ($Version -or $Name -in @("version", "v", "--version")) {
        Write-Output "v$script:ScratchpadVersion"
        return
    }

    # Show directory if requested
    if ($Directory -or $Name -in @("dir", "d", "--dir", "--directory")) {
        Write-Output $script:ScratchpadDirectory
        return
    }

    # List scratchpad items if requested
    if ($List -or $Name -in @("list", "ls", "--list")) {
        Get-Scratchpad
        return
    }

    # Open the scratchpad
    Open-Scratchpad -Name $Name
}

function Get-Scratchpad {
    if (Test-Path -LiteralPath $script:ScratchpadDirectory -PathType Container) {
        Get-ChildItem -LiteralPath $script:ScratchpadDirectory
    }
}

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

        if ($hasPipelineInput) {
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
