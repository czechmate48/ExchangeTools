
function Get-LayeredGroupMembers {
    
    param (
        [String]$emailGroup,
        [System.Collections.ArrayList]$members
    )

    $emailGroupMembers = Get-DistributionGroupMember -Identity $emailGroup

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
                $members.Add($emailGroupMember)
            }
            
        } else {
            Get-LayeredGroupMembers -emailGroup $emailGroupMember.identity -members $members
        }
    }
}

Connect-Exchangeonline
$members = [System.Collections.ArrayList] @()
Get-LayeredGroupMembers -emailGroup 'allstaff@hopva.org' -members $members