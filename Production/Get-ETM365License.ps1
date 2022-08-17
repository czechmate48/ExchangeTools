
function Get-ETM365License {

    <#
    .SYNOPSIS
    Returns the status of a user's licenses as well as the licenses assigned to the user. 
    .DESCRIPTION
    This cmdlet appends two fields to the Microsoft.Online.Administration.User objects obtained from the Get-MsolUser command.
    The fields LicenseStatus and ActiveLicenses contain information about the status of licenses (active vs. not active) as well
    as the licenses that are active.
    .PARAMETER $UserPrincipalName
    Accepts an array of userprincipalnames (John.Doe@contoso.com). The groups are returned for these users. Defining this parameter
    will send a Get-Msol user query for each UserPrincipal name and is slow. It is recommended that the user use the 'All' switch
    when trying to get MFA for the entire tenant as it is much faster
    .PARAMETER $All
    This switch queries the entire Tenant
    .EXAMPLE
    Get-ETM365License -UserPrincipalName John.Doe@contoso.com
    .EXAMPLE
    Get-ETM365License -UserPrincipalName (Get-MsolUser).UserPrincipalName
    .EXAMPLE
    Get-ETM365License -All
    .NOTES
    Automatically installs the msonline module if it is not already present
    #>

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, ParameterSetName = 'UserPrincipalName')]
        [String[]] $UserPrincipalName,
        [Parameter(ValueFromPipeline=$true, ParameterSetName = 'Tenant')]
        [Switch] $All
    )

    BEGIN {

        # Install Msonline Module
        Write-Verbose -Message "Determining whether msonline module is installed or not"
        $msolInstalled = Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules\MSOnline'
        if ($msolInstalled -eq $false){
            Write-Verbose -Message "msonline module is not installed"
            Try {
                Write-Verbose -Message "Attempting to install msonline module"
                Install-Module -name 'msonline' -Force -ErrorAction Stop
            } Catch {
                Write-Verbose -Message "Unable to install msonline"
                Write-Error -Message "Cannot install msonline module."
            } #Try
        } else {
            Write-Verbose -Message "msonline module is installed"
        }
        
        # Connect to Msonline MsolService
        Try {
            Write-Verbose -Message "Running Get-MsolDomain to determine whether powershell is already connected to Msonline service or not"
            Get-msoldomain -ErrorAction Stop | Out-Null 
            Write-Verbose -Message "Powershell is already connected to Msonline service"
        } Catch {
            Write-Verbose -Message "Powershell is not connected to the Msonline service"
            
            Try {
                Write-Verbose -Message "Running 'Connect-MsolService' cmdlet to trigger login"
                Connect-msolservice -ErrorAction Stop
            } Catch {
                Write-Verbose -Message "Unable to connect to msolservice"
                Write-Error -Message "Cannot connect to msonline."
            } #Try    
        } #Try
    } #Begin

    PROCESS {

        $licenseCheckAccounts = @()

        if ($PSBoundParameters.ContainsKey('UserPrincipalName')){
            Foreach ($user in $UserPrincipalName){
                try {
                    $user = Get-MsolUser -UserPrincipalName $user -ErrorAction Stop
                    $licenseCheckAccounts += $user
                } catch {
                    Write-Verbose "$user not found"
                }
            }
        } 
        
        elseif ($PSBoundParameters.ContainsKey('All')){
            try {
                $licenseCheckAccounts = Get-MsolUser -All
            } catch {
                Write-Verbose "Unable to get MsolUsers"
            }
        }

        foreach ($account in $licenseCheckAccounts){

            $user = $account.UserPrincipalName
            $licenses = $account.licenseassignmentdetails

            if ($licenses.count -eq 0){
                Write-Verbose -Message "No active licenses found for $user"
                $account | Add-Member -NotePropertyName 'LicenseStatus' -NotePropertyValue 'Not Active'
            } else {
                Write-Verbose -Message "Active licenses found for $user"
                $account | Add-Member -NotePropertyName 'LicenseStatus' -NotePropertyValue 'Active'
            }

            $active_licenses = @()
            foreach ($license in $licenses){
                Write-Verbose -Message "$license active for $user"
                $active_licenses += $license
            }

            $account | Add-Member -NotePropertyName 'ActiveLicenses' -NotePropertyValue $active_licenses
            $account
        }
    }
}

