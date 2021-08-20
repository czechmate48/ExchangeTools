
Function Get-MfaStatus {

    <#
    .SYNOPSIS
    Returns the forms of MultiFactor authentication that have been setup for a given user
    .DESCRIPTION
    This cmdlet works with the msonline module to identify what forms of MultiFactor authentication have been configured
    for the user.
    .PARAMETER $UserPrincipalName
    Accepts an array of userprincipalnames (John.Doe@contoso.com). The groups are returned for these users. 
    .EXAMPLE
    Get-MfaStatus -UserPrincipalName John.Doe@contoso.com
    .EXAMPLE
    Get-MfaStatus -UserPrincipalName (Get-MsolUser).UserPrincipalName
    .NOTES
    Automatically installs the msonline module if it is not already present
    #>

    [Cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Mandatory=$True)]
        [String[]] $UserPrincipalName
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

        Foreach ($user in $UserPrincipalName){

            try {
                $account = Get-MsolUser -UserPrincipalName $user -ErrorAction Stop
            } catch {
                Write-Verbose "$user not found"
                break
            }
            
            $authenticationMethods = ($account | Select-Object -Property StrongAuthenticationMethods).StrongAuthenticationMethods

            if ($authenticationMethods.count -eq 0){
                $result = [PSCustomObject]@{
                    Name = $user
                    AuthenticationMethod = 'MFA NOT SETUP'
                }
                $result
            }
            
            foreach ($method in $authenticationMethods){
                $method = $method.MethodType
                $result = [PSCustomObject]@{
                    Name = $user
                    AuthenticationMethod = $method
                }
                $result
            }  
        }
    }
}