
Function Get-MfaStatus {

    <#
    .SYNOPSIS
    Returns the status of MultiFactor authentication as well as the forms that have been setup for a given user
    .DESCRIPTION
    This cmdlet appends two fields to the Microsoft.Online.Administration.User objects obtained from the Get-MsolUser command.
    The fields MfaStatus and AuthenticationMethods contain information about the status of MFA (active vs. not active) as well
    as the method types that are active. 
    .PARAMETER $UserPrincipalName
    Accepts an array of userprincipalnames (John.Doe@contoso.com). The groups are returned for these users. Defining this parameter
    will send a Get-Msol user query for each UserPrincipal name and is slow. It is recommended that the user use the 'All' switch
    when trying to get MFA for the entire tenant as it is much faster
    .PARAMETER $All
    This switch queries the entire Tenant
    .EXAMPLE
    Get-MfaStatus -UserPrincipalName John.Doe@contoso.com
    .EXAMPLE
    Get-MfaStatus -UserPrincipalName (Get-MsolUser).UserPrincipalName
    .EXAMPLE
    Get-MfaStatus -All
    .NOTES
    Automatically installs the msonline module if it is not already present
    #>

    [Cmdletbinding()]
    param(
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
                Write-Error -Message "Cannot install msonline module. Exiting cmdlet."
                exit
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
                Write-Error -Message "Cannot connect to msonline. Exiting cmdlet."
                exit
            } #Try    
        } #Try
    } #Begin

    PROCESS {

        $mfaCheckAccounts = @()

        if ($PSBoundParameters.ContainsKey('UserPrincipalName')){
            Foreach ($user in $UserPrincipalName){
                try {
                    $user = Get-MsolUser -UserPrincipalName $user -ErrorAction Stop
                    $mfaCheckAccounts += $user
                } catch {
                    Write-Verbose "$user not found"
                }
            }
        } 
        
        elseif ($PSBoundParameters.ContainsKey('All')){
            try {
                $mfaCheckAccounts = Get-MsolUser -All
            } catch {
                Write-Verbose "Unable to get MsolUsers"
                exit
            }
        }

        Foreach ($account in $mfaCheckAccounts){
            
            $user = $account.UserPrincipalName
            $authenticationMethods = ($account | Select-Object -Property StrongAuthenticationMethods).StrongAuthenticationMethods

            if ($authenticationMethods.count -eq 0){
                Write-Verbose -Message "MFA Not active for $user"
                $account | Add-Member -NotePropertyName 'MfaStatus' -NotePropertyValue 'Not Active'
            } else {
                Write-Verbose -Message "MFA active for $user"
                $account | Add-Member -NotePropertyName 'MfaStatus' -NotePropertyValue 'Active'
            }

            $authMethods = @()
            foreach ($method in $authenticationMethods){
                Write-Verbose -Message "$method active for $user"
                $method = $method.MethodType
                $authMethods+=$method
            }
            
            $account | Add-Member -NotePropertyName 'AuthenticationMethods' -NotePropertyValue $authMethods
            $account
        }
    }
}