
Function Get-MfaStatus {
    [Cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Mandatory=$True)]
        [String[]] $UserPrincipalName
    )

    BEGIN {
        $msolInstalled = Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules'
        if ($msolInstalled -eq $false){
            Install-Module -name 'msonline' -Force
        }
        Connect-msolservice
    }

    PROCESS {
        Foreach ($user in $UserPrincipalName){
            $account = Get-MsolUser -UserPrincipalName $user
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