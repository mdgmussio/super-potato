function Get-mmDirectoryListing {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline,
                    ValueFromPipelineByPropertyName)] 
        [string]$Path = "."
    )
    Get-ChildItem -Path $Path | ForEach-Object {
        if ($_.PSIsContainer) {
            $dirSize = (Get-ChildItem -Path $_.FullName | Measure-Object -Property Length -Sum).Sum / 1MB
            [PSCustomObject]@{
                Mode = $_.Mode
                Name = $_.Name
                SizeMB = [math]::round($dirSize, 2)
            }
        } else {
            [PSCustomObject]@{
                Mode = $_.Mode
                Name = $_.Name
                SizeMB = [math]::round($_.Length / 1MB, 2)
            }
        }
    } | Sort-Object Mode, SizeMB -Descending | Format-Table -AutoSize
}
