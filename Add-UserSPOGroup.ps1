function Add-UserSPOGroup {
    param (
        [Parameter(Mandatory=$true)]
        [string]$URL,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Email,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Group,
        
        [Parameter(Mandatory=$true)]
        [string]$ClientID
    )
    
    begin {
        Write-Host "Starting..." -f Cyan
        $script:results = @()
        try {
            Connect-PnPOnline -Url $URL -Interactive -ClientId $ClientID
            Write-Host "Connected to $URL successfully." -f Green
        }
        catch {
            Write-Host "Failed to connect to $URL : $_" -f Red
            throw $_
        }
    }

    process {
        Write-Host "Processing..." -f Green
        
        foreach ($eml in $Email) {
            # Check if user exists
            $user = Get-PnPUser -Identity $eml -ErrorAction SilentlyContinue
            if ($null -eq $user) {
                Write-Host "User $eml does not exist. Skipping..." -f Red
                $script:results += [PSCustomObject]@{
                    Email = $eml
                    Group = $null
                    Status = "UserNotFound"
                    Message = "User does not exist in SharePoint"
                    Timestamp = (Get-Date)
                }
                continue
            }
            
            Write-Host "User $eml exists. Processing..." -f Green
            
            foreach ($grp in $Group) {
                # Check if group exists
                $group = Get-PnPGroup -Identity $grp -ErrorAction SilentlyContinue
                if ($null -eq $group) {
                    Write-Host "Group $grp does not exist. Skipping..." -f Red
                    $script:results += [PSCustomObject]@{
                        Email = $eml
                        Group = $grp
                        Status = "GroupNotFound"
                        Message = "Group does not exist in SharePoint"
                        Timestamp = (Get-Date)
                    }
                    continue
                }
                
                # Check if user is already a member
                $isMember = Get-PnPGroupMembers -Identity $grp -ErrorAction SilentlyContinue | 
                    Where-Object { $_.LoginName -eq $user.LoginName }
                
                if ($isMember) {
                    Write-Host "$eml is already a member of $grp. Skipping..." -f Yellow
                    $script:results += [PSCustomObject]@{
                        Email = $eml
                        Group = $grp
                        Status = "AlreadyMember"
                        Message = "User is already a member of this group"
                        Timestamp = (Get-Date)
                    }
                }
                else {
                    try {
                        Write-Host "$eml is not a member of $grp. Adding..." -f Green
                        Add-PnPUserToGroup -LoginName $user.LoginName -Identity $grp
                        Write-Host "$eml successfully added to $grp." -f Green
                        $script:results += [PSCustomObject]@{
                            Email = $eml
                            Group = $grp
                            Status = "Added"
                            Message = "User successfully added to group"
                            Timestamp = (Get-Date)
                        }
                    }
                    catch {
                        Write-Host "Failed to add $eml to $grp : $_" -f Red
                        $script:results += [PSCustomObject]@{
                            Email = $eml
                            Group = $grp
                            Status = "Failed"
                            Message = "Failed to add user to group"
                            Timestamp = (Get-Date)
                        }
                    }
                }
            }
        }
    }

    end {
        Disconnect-PnPOnline
        Write-Host "Finished." -f Cyan
        Write-Host ""
        Write-Host "=== Results Summary ===" -f Cyan
        Write-Host ""
        
        # Display results table
        $script:results | Format-Table -AutoSize
        
        # Return results
        return $script:results
    }
}