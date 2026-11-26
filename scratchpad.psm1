$script:ScratchpadVersion = 'v0.1.0'

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

    # TODO: Implement main logic
    Write-Output $Name

}
