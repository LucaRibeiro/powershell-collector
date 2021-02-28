#requires -RunAsAdministrator

#Define variables
$ReportExportPath = $PSScriptRoot
Get-WMIObject -Namespace "root\SMS" -Class "SMS_ProviderLocation" | foreach-object{if ($_.ProviderForLocalSite -eq $true){$SiteCode=$_.SiteCode}} 

#Import module
Import-Module(Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)

#Set location
Set-Location($SiteCode + ":") -ErrorAction Stop

#Get all deployed applications, packages and tasksequnces
$AllSoftware = [array](Get-CMApplication -Fast) + [array](Get-CMPackage)
$AllTaskSequences = Get-CMTaskSequence
$SoftwareCounter = 1

$SoftwareReport = @()
$DeploymentsReport = @()

Write-Host "Total number of software is '$($AllSoftware.count)'.."
Write-Host "Total number of Task Sequences is '$($AllTaskSequences.count)'.."

#Loop through all software
ForEach($Software in ($AllSoftware)){

    #Software specific variables
    if($Software.SmsProviderObjectPath -like "SMS_Application*"){

        #Application variables
        $Name = $Software.LocalizedDisplayName
        $SoftwareType = "Application"
        $DateCreated = $Software.DateCreated
        $DateLastModified = $Software.DateLastModified
        $IsDeployed = $Software.IsDeployed
        $Description = $Software.LocalizedDescription
        $NumberOfDevicesWithApp = $Software.NumberOfDevicesWithApp
        $NumberOfUsersWithApp = $Software.NumberOfUsersWithApp
        $NumberOfDependentTS = $Software.NumberOfDependentTS
        $UniqueAppID = $Software.CI_UniqueID
        $Deployments = (Get-CMDeployment -SoftwareName $Name)
    }Else{

        #Pacakage variables
        $Name = $Software.Name
        $DateCreated = $Software.DateCreated
        $SoftwareType = "Package"
        $DateLastModified = $Software.LastRefreshTime
        $IsDeployed = $Software.IsDeployed
        $Description = $Software.Description
        $NumberOfDevicesWithApp = $Software.NumberOfDevicesWithApp
        $NumberOfUsersWithApp = $Software.NumberOfUsersWithApp
        $NumberOfDependentTS = $Software.NumberOfDependentTS
        $UniqueAppID = $Software.PackageID
        $Deployments = (Get-CMDeployment -SoftwareName "$Name*") | Where-Object {$_.PackageID -eq $UniqueAppID}
    }

    #Shared variables
    $NumberOfDeployments = 0
    $DeploymentsWithTargets = "No"
    $ReferredInTaskSequence = "No"
    $ReferredTaskSequences = @()
    $DeploymentsCounter = 1

    #Write host
    Write-Host "[$($SoftwareCounter)/$($AllSoftware.Count)]Gathering information for $($SoftwareType.ToLower()) '$Name'..."

    #Loop through all tasksequences to se if there is any relations
    ForEach($TaskSequence in $AllTaskSequences){

        #Declare variables
        $TaskSequenceName = $TaskSequence.Name
        [array]$TaskSequenceReferenceIDs = $TaskSequence.References.Package

        #Some of the applications have a sourceversion suffix, so we cant use the -in comparer
        ForEach($TaskSequenceReferenceID in $TaskSequenceReferenceIDs){

            #Check for "match"
            if($UniqueAppID -like "$TaskSequenceReferenceID*"){
                #Write-Host "Match found for $TaskSequenceName"
                $ReferredInTaskSequence = "Yes"
                $ReferredTaskSequences += $TaskSequenceName
            }
        }
    }

    #Loop through all deployments and gather info
    ForEach($Deployment in $Deployments){

        #Deployment variables
        $DeploymentIntent = If ($Deployment.DeploymentIntent -eq 1){"Required"}Else{"Available"} # 2 = available, 1 = required
        $DesiredConfigType =If ($Deployment.DesiredConfigType -eq 1){"Install"}Else{"Uninstall"}# 2 = uninstall, 1 = install
        $DeploymentScope = If ($Deployment.SummaryType -eq 1){"Device"}Else{"User"}# 2 = User, 1 = Device
        $NumberOfTargets = $Deployment.NumberTargeted
        $CollectionName = $Deployment.CollectionName
        [array]$CollectionRules = (Get-CMCollection -Name $CollectionName).CollectionRules
        [array]$IncludedCollections = ($CollectionRules | Where-Object {$_.SmsProviderObjectPath -eq "SMS_CollectionRuleIncludeCollection"}).RuleName
        [array]$ExcludeCollections = ($CollectionRules | Where-Object {$_.SmsProviderObjectPath -eq "SMS_CollectionRuleExcludeCollection"}).RuleName
        $DeploymentTime = $Deployment.DeploymentTime
        $NumberOfDeployments += 1
        if($NumberOfTargets -ge 1){$DeploymentsWithTargets = "Yes"}

        #Add deployment to report array
        $depObj = [PSCustomObject]@{

            #Define the objet data
            Name = $Name
            SoftwareType = $SoftwareType
            DeploymentTime = $DeploymentTime
            DeploymentIntent = $DeploymentIntent
            DesiredConfigType = $DesiredConfigType
            DeploymentScope = $DeploymentScope
            NumberOfTargets = $NumberOfTargets
            CollectionName = $CollectionName
            IncludedCollections = $($IncludedCollections -join ", ")
            ExcludeCollections = $($ExcludeCollections -join ", ")
        }
        $DeploymentsReport += $depObj
        $DeploymentsCounter +=1
    }

    #Add software to software report array
    $appObj = [PSCustomObject]@{

        #Define the objet data
        Name = $Name
        SoftwareType = $SoftwareType
        DateCreated = $DateCreated
        DateLastModified = $DateLastModified
        IsDeployed = $IsDeployed
        NumberOfDevicesWithApp = $NumberOfDevicesWithApp
        NumberOfUsersWithApp = $NumberOfUsersWithApp
        NumberOfDeployments = $NumberOfDeployments
        DeploymentsWithTargets = $DeploymentsWithTargets
        ReferredInTaskSequence = $ReferredInTaskSequence
        NumberOfDependentTS = $NumberOfDependentTS
        ReferredTaskSequences = if($ReferredTaskSequences){$($ReferredTaskSequences -join ", ")};
        Description = $Description
    } 

    $SoftwareReport += $appObj
    $SoftwareCounter += 1
}

#Set location back to starting point
Set-Location ($PSScriptRoot) -ErrorAction Stop

#Export the result 
$SoftwareReport | Export-Csv -Path "$ReportExportPath\$($SiteCode)_SoftwareReport.csv" -Force -NoTypeInformation
$DeploymentsReport | Export-Csv -Path "$ReportExportPath\$($SiteCode)_SoftwareDeploymentsReport.csv" -Force -NoTypeInformation