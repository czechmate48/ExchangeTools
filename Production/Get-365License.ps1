
function Get-365License {
    [CmdletBinding()]
    param (
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

        foreach ($user in $UserPrincipalName){
            $licenses = (Get-MsolUser -UserPrincipalName $user).licenseassignmentdetails

            if ($licenses.count -ne 0){
        
                foreach ($license in $licenses){
                    $obj = [PSCustomObject]@{
                        Name = $user
                        License = $license
                    }
                
                    $obj
                }
                
            } else {
                $obj = [PSCustomObject]@{
                    Name = $user
                    License='NO LICENSES'
                }
            
                $obj
            }
        }
    }
}

