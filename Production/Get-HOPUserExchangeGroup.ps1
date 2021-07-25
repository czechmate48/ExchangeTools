function Get-HOPUserExchangeGroup{
<#
.SYNOPSIS
Returns the user's exchange group memberships
.DESCRIPTION
This cmdlet works with the powershell V2 module to obtain a list of exchange groups for a given user. You can obtain a list of 
unified groups, distribution groups, or both (by default). The user can only be identified by the userprincipalname (john.doe@contoso.com).
.PARAMETER $UserPrincipalName
Accepts an array of userprincipalnames (John.Doe@contoso.com). The groups are returned for these users. 
.PARAMETER $GroupType
Accepts 'unified','distribution', or 'all'. These are the types of groups you wish to identify for the user. By default, the commandlet searches
through all groups types.
.EXAMPLE
Get-HOPUserExchangeGroup -userprincipalname John.Doe@contoso.com -GroupType Unified
.EXAMPLE
(Get-AZADUser).UserPrincipalName | Get-HOPUserExchangeGroup
.NOTES
Requires Exchange Online Powershell V2 module
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('upn')]
        [String[]] $UserPrincipalName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [ValidateSet('Unified','Distribution','All')]
        [string] $GroupType = 'All'
    )

    BEGIN{}

    PROCESS{

        try {
            If ($GroupType -eq 'All' -or $GroupType -eq 'Unified'){
                Write-Verbose -Message 'Querying Exchange for all Unified Groups'
                $AllUnifiedGroups = Get-UnifiedGroup -ErrorAction Stop
            }
    
            If ($GroupType -eq 'All' -or $GroupType -eq 'Distribution'){
                Write-Verbose -Message 'Querying Exchange for all Distribution Groups'
                $AllDistributionGroups = Get-DistributionGroup -ErrorAction Stop
            }
        } catch {
            Write-Warning "Unable to obtain a list of exchange groups. Please make sure the Exchange Online Powershell Version 2 module is installed and you have connected to your microsoft tenant"
            Write-Warning "Import-Module ExchangeOnlinePowershell; Connect-ExchangeOnline"
            Write-Verbose -Message 'Exiting Command'
        }
        
        ForEach ($upn in $UserPrincipalName){

            try {
                $user = (Get-Exomailbox $upn -ErrorAction Stop).Name 
            } catch {
                Write-Warning "$upn not found"
                continue
            }
            
            Write-Verbose -Message "Finding groups for $user"
            $userGroups = @() #An array of a single user and their groups
            
            If ($GroupType -eq 'All' -or $GroupType -eq 'Unified'){

                Write-Verbose -Message "Querying Exchange for $user Unified Groups"

                # Use $group.alias when searching through groups as $group.name contains extemporaneous information
                ForEach ($group in $AllUnifiedGroups){

                    if ((Get-UnifiedGroupLinks -identity $group.alias -linktype 'member').name -contains $user){

                        # Add property to the object only once else you will receive an error
                        if ('User' -notin (Get-Member -InputObject $group).Name){
                            Write-Verbose -Message "Adding 'User' property to $group"
                            Add-Member -InputObject $group -Name 'User' -Value $user -MemberType "NoteProperty"
                        }

                        Write-Verbose -Message "$user is a member of $group unified group"
                        $group.User = $user
                        $userGroups += $group

                    } # if
                } # foreach
            } # if

            If ($GroupType -eq 'All' -or $GroupType -eq 'Distribution'){

                Write-Verbose -Message "Querying Exchange for $user Distribution Groups"

                ForEach ($group in $AllDistributionGroups){

                    if ((Get-DistributionGroupMember -identity $group.alias).Name -contains $user){

                        # Add property to the object only once else you will receive an error
                        if ('User' -notin (Get-Member -InputObject $group).Name){
                            Write-Verbose -Message "Adding 'User' property to $group"
                            Add-Member -InputObject $group -Name 'User' -Value $user -MemberType "NoteProperty"
                        }

                        Write-Verbose -Message "$user is a member of $group Distribution group"
                        $group.User = $user
                        $userGroups += $group

                    } # if
                } # foreach
            } # if

            Write-Verbose -Message "Finished finding groups for $user"
            Write-Output $userGroups

        } # forEach
    }

    END {}
} # function