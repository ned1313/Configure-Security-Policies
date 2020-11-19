#Prefix for resources
$prefix = "csp"

#Basic variables
$location = "eastus"
$id = Get-Random -Minimum 1000 -Maximum 9999

#Log into Azure
Add-AzAccount

#Select the correct subscription
Get-AzSubscription -SubscriptionName "SUB_NAME" | Select-AzSubscription

# Now let's create a policy

Register-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights'

# Create resource groups in the current subscription
$rg1 = New-AzResourceGroup -Name "$prefix-$id-1" -Location $location
$rg2 = New-AzResourceGroup -Name "$prefix-$id-2" -Location $location

# Create a new policy definition

$defParams = @{
    Name = "AppendTagResourceGroup"
    DisplayName = "Append Tag to Resource Group"
    Description = "Add tag to a resource group"
    Metadata = '{"category":"Tags"}'
    Parameter = "append_tag_parameters.json"
    Policy = "append_rg_tag.json"
}

$definition = New-AzPolicyDefinition @defParams

# Create an initiative for security tags

$PolicyDefinition = @"
[
    {
        "policyDefinitionId": "$($definition.ResourceId)",
        "parameters": {
            "tagName": {
                "value": "Security Owner"
            },
            "tagValue": {
                "value": "[parameters('SecurityOwner')]"
            }
        }
    }
]
"@

$initiativeParams = @{
    Name = "AppendTagsSetResourceGroups"
    DisplayName = "Append Tags Set for Resource Groups"
    Description = "Append Tags to Resource Groups."
    Metadata = '{"category":"Tags"}'
    Parameter = '{ "SecurityOwner": { "type": "string" } }'
    PolicyDefinition = $PolicyDefinition
}

$initiative = New-AzPolicySetDefinition @initiativeParams

# Assign the initiave to the subscription, excluding the resource group

$assignParams = @{
    Name = "SecTagsResourceGroups"
    DisplayName = "Security Tags for Resource Groups"
    Scope = "/subscriptions/$((Get-AzContext).Subscription.Id)"
    NotScope = $rg1.ResourceId
    PolicyParameterObject = @{'SecurityOwner'='Adrian Godin'}
    PolicySetDefinition = $initiative
}

New-AzPolicyAssignment @assignParams

Start-AzPolicyComplianceScan

# Create a new resource group

$rg3 = New-AzResourceGroup -Name "$prefix-$id-3" -Location $location

# Create storage policy and storage account

$defParams = @{
    Name = "ModifyPublicStorageAccountAccess"
    DisplayName = "Modify Public Storage Account Access"
    Description = "Removes public access from storage accounts"
    Metadata = '{"category":"Storage"}'
    Policy = "storage_policy_rule.json"
}

$definition = New-AzPolicyDefinition @defParams

#Create a new storage account
$saAccountParameters = @{
    Name = "$($prefix)sa$id"
    ResourceGroupName = $rg1.ResourceGroupName
    Location = $location
    SkuName = "Standard_LRS"
    AllowBlobPublicAccess = $true
}

$storageAccount = New-AzStorageAccount @saAccountParameters

# Now apply the policy to RG1 in the portal

# Once applied you can force an evaluation
Start-AzPolicyComplianceScan -ResourceGroupName $rg1.ResourceGroupName