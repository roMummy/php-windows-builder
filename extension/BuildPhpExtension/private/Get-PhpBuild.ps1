function Get-PhpBuild {
    <#
    .SYNOPSIS
        Get the PHP build.
    .PARAMETER Config
        Extension Configuration
    .PARAMETER BuildDetails
        PHP Build Details
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position=0, HelpMessage='Configuration for the extension')]
        [PSCustomObject] $Config,
        [Parameter(Mandatory = $true, Position=1, HelpMessage='Php Build Details')]
        [PSCustomObject] $BuildDetails
    )
    begin {
    }
    process {
        try {
            Add-StepLog "Adding release build for PHP $( $Config.php_version )"
            Add-Type -Assembly "System.IO.Compression.Filesystem"
            $phpSemver, $baseUrl = $BuildDetails.phpSemver, $BuildDetails.baseUrl
            $tsPart = if ($Config.ts -eq "nts") { "nts-Win32" } else { "Win32" }
            $binZipFile = "php-$phpSemver-$tsPart-$( $Config.vs_version )-$( $Config.arch ).zip"
            $binUrl = "$baseUrl/$binZipFile"

            $fallBackUrl = "$baseUrl/archives/$binZipFile"

            if ($Config.php_version -lt '7.4') {
                $fallBackUrl = $fallBackUrl.replace("vc", "VC")
            }

            try {
                Invoke-WebRequest $binUrl -OutFile $binZipFile
            } catch {
                try {
                    Invoke-WebRequest $fallBackUrl -OutFile $binZipFile
                } catch {
                    throw "Failed to download the build for PHP version $( $Config.php_version )."
                }
            }

            $currentDirectory = (Get-Location).Path
            $binZipFilePath = Join-Path $currentDirectory $binZipFile
            $binDirectoryPath = Join-Path $currentDirectory php-bin

            [System.IO.Compression.ZipFile]::ExtractToDirectory($binZipFilePath, $binDirectoryPath)
            Add-Path -PathItem $binDirectoryPath
            Add-Content -Path $binDirectoryPath\php.ini -Value "extension_dir=$binDirectoryPath\ext"
            Add-BuildLog tick PHP "PHP release build added successfully"
            return $binDirectoryPath
        } catch {
            Add-BuildLog cross PHP "Failed to download the PHP release build"
            throw
        }
    }
    end {
    }
}