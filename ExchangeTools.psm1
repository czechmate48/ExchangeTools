$Cmdlets = @(Get-ChildItem -Path "$PSScriptRoot\Production\" -include '*.ps1' -recurse -ErrorAction SilentlyContinue)

foreach ($cmdlet in $cmdlets){
    try {
        . $cmdlet.fullname
    } catch {
        Write-Error -Message "Failed to import cmdlet $($cmdlet.fullname): $_"
    }
}

Export-ModuleMember -Function $cmdlets.BaseName