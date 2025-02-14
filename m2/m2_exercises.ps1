# Install the Az.Blueprint module if it is not installed
Install-Module -Name Az.Blueprint

# Log into Azure
Add-AzAccount

# Select the appropriate subscription
# Change SUB_NAME to your subscription name
Get-AzSubscription -SubscriptionName "SUB_NAME" | Select-AzSubscription

# Create the Blueprint item
cd ./blueprint
$blueprint = New-AzBlueprint -Name "Default-Setup" -BlueprintFile "blueprint.json" -ManagementGroupId "Contoso"

# Add the Blueprint artifacts
New-AzBlueprintArtifact -Blueprint $blueprint -Name 'envPolicyTags' -ArtifactFile ".\artifacts\environmentTags.json"
New-AzBlueprintArtifact -Blueprint $blueprint -Name 'secPolicyTags' -ArtifactFile ".\artifacts\securityOwnerTags.json"
New-AzBlueprintArtifact -Blueprint $blueprint -Name 'SecRBAC' -ArtifactFile ".\artifacts\securityOwners.json"
New-AzBlueprintArtifact -Blueprint $blueprint -Name 'NetRBAC' -ArtifactFile ".\artifacts\networkOwners.json"
New-AzBlueprintArtifact -Blueprint $blueprint -Name 'ContribRBAC' -ArtifactFile ".\artifacts\subscriptionContributors.json"

# Add vnet template
$templateParameters = @{
    Blueprint = $blueprint
    Type = "TemplateArtifact"
    Name = "vnetTemplate"
    TemplateFile = ".\artifacts\vnetTemplate.json"
    TemplateParameterFile = ".\artifacts\vnetTemplateParameters.json"
    ResourceGroupName = "Networking"
}

New-AzBlueprintArtifact @templateParameters

# Publish the Blueprint
Publish-AzBlueprint -Blueprint $blueprint -Version '1.0'

# Assign the Blueprint in the portal
