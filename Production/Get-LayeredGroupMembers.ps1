function Get-LayeredGroupMembers {
    
    <#
    .SYNOPSIS
    Digs down into layered distribution list email groups and returns all members in all groups
    .DESCRIPTION
    This cmdlet works with the exchange online powershell module by getting all groups within a distribution list and recursively finding members of
    all child groups. 
    .PARAMETER $emailGroup
    Accepts the 'identity' of the email group. Any value accepted by 'Get-DistributionGroupMember' will work. 
    .EXAMPLE
    Get-LayeredGroupMembers -emailgroup MyGroup@contoso.com
    .NOTES
    Requires Exchange Online Powershell V2 module
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [String]$emailGroup,
        [Parameter(Mandatory=$false)]
        [System.Collections.ArrayList] $members = @()
    )

    Process {
        $emailGroupMembers = Get-DistributionGroupMember -Identity $emailGroup
        Write-Verbose "Checking email group: $emailGroup"

        foreach ($emailGroupMember in $emailGroupMembers){
            

            if ($emailGroupMember.RecipientType -eq 'UserMailbox') {
                
                $dontAddMember = $false
                foreach ($member in $members){
                    if ($emailGroupMember.identity -eq $member.identity){
                        $dontAddMember = $true
                        break
                    } 
                }

                if ($dontAddMember -eq $false){
                    Write-Verbose -message "Unique value: $emailGroupMember"
                    $members.Add($emailGroupMember) | Out-null
                } else {
                    Write-Verbose -Message "Duplicate value: $emailGroupMember"
                }
                
            } else {
                Get-LayeredGroupMembers -emailGroup $emailGroupMember.identity -members $members | Out-Null
            }
        }

        $members | Select-object Name,Title
    }

    End {}

}