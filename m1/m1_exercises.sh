#Log into Azure with CLI
az login
az account set --subscription "SUB_NAME"

id=$(((RANDOM%9999+1)))
prefix="csp"
location="eastus"
resource_group="$prefix-$id"

# Create a resource group in the current subscription
rg1=$(az group create -n "$resource_group-1" -l $location)
rg2=$(az group create -n "$resource_group-2" -l $location)

# Create a new policy definition

az policy definition create --name "AppendTagResourceGroup" \
  --display-name "Append Tag to Resource Group" \
  --description "Add tag to a resource group" \
  --rules 'append_rg_tag.json' \
  --params 'append_tag_parameters.json' \
  --metadata category=Tags


# Create an initiative for disallowed VMs families

polDefId=$(az policy definition show --name AppendTagResourceGroup | jq .id -r)

cat << EOF > polDef.json
[
    {
        "policyDefinitionId": "$polDefId",
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
EOF

az policy set-definition create --name "AppendTagsSetResourceGroups" \
  --display-name "Append Tags Set for Resource Groups" \
  --definitions "polDef.json" \
  --description "Append Tags to Resource Groups." \
  --metadata "category=Tags" \
  --params "{ \"SecurityOwner\": { \"type\": \"string\" } }"

# Cleanup

rm polDef.json

# # Assign the initiave to the subscription, excluding the first resource group

subId=$(az account show | jq .id -r)

rgId=$(echo $rg1 | jq .id -r)

az policy assignment create --display-name "Security Tags for Resource Groups" \
  --name "SecTagsResourceGroups" \
  --policy-set-definition "AppendTagsSetResourceGroups" \
  --scope "/subscriptions/$subId" \
  --not-scope "$rgId" \
  --params "{ \"SecurityOwner\": { \"value\": \"Adrian Godin\"} }"

# Start a compliance scan

az policy state trigger-scan

# Create a new resource group

rg3=$(az group create -n "$resource_group-3" -l $location)