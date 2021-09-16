[#ftl]

[@addComponentDeployment
    type=SUBSCRIPTION_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=SUBSCRIPTION_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Primary unit for hosting of resources"
            }
        ]
    attributes=[]
/]

[@addResourceGroupInformation
    type=SUBSCRIPTION_COMPONENT_TYPE
    attributes=
        [
            {
                "Names" : "external:Provider",
                "Description" : "The provider owning the subscription",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "external:ProviderId",
                "Description" : "The provider identifier for the subscription",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "external:DeploymentFramework",
                "Description" : "The default deployment framework for the subscription",
                "Types" : STRING_TYPE
            }
        ]
    provider=SHARED_PROVIDER
    resourceGroup=DEFAULT_RESOURCE_GROUP
    services=[
        SHARED_EXTERNAL_SERVICE
    ]
    locations={
        [#-- A link to a subscription is required if not importing the provider --]
        DEFAULT_RESOURCE_GROUP : {
            "Mandatory" : false,
            "TargetComponentTypes" : [
                SUBSCRIPTION_COMPONENT_TYPE
            ]
        }
    }
/]