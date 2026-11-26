# Scratchpad Version
$script:ScratchpadVersion = 'v0.1.0'

# Directory for scratchpad files
$script:ScratchpadDirectory = Join-Path $env:USERPROFILE ".cache" "scratchpad"

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
    if ($Help -or $Name -in @("help", "h", "?")) {
        Get-Help scratchpad
        return
    }

    # Show version if requested
    if ($Version -or $Name -in @("version", "v")) {
        Write-Output $script:ScratchpadVersion
        return
    }

    # Show directory if requested
    if ($Directory) {
        Write-Output $script:ScratchpadDirectory
        return
    }

    # List scratchpad items if requested
    if ($List -or $Name -in @("list", "ls")) {
        Get-Scratchpad
        return
    }

    # TODO: Implement main logic
    Write-Output $Name

}

function Get-Scratchpad {
    if (Test-Path $script:ScratchpadDirectory -PathType Container) {
        Get-ChildItem $script:ScratchpadDirectory
    }
}
