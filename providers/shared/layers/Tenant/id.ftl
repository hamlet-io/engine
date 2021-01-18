[#ftl]

[@addLayer
    type=TENANT_LAYER_TYPE
    referenceLookupType=TENANT_LAYER_REFERENCE_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A instance of a product"
            }
        ]
    attributes=[
        {
            "Names" : "Id",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Name",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Title",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Description",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Modules",
            "Subobjects" : true,
            "Children"  : moduleReferenceConfiguration
        },
        {
            "Names" : "Plugins",
            "Subobjects" : true,
            "Children" : pluginReferenceConfiguration
        },
        {
            "Names" : "Profiles",
            "Children" : [
                {
                    "Names" : "Deployment",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Policy",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Placement",
                    "Types" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        },
        {
            "Names" : "CertificateBehaviours",
            "Children" : certificateBehaviourConfiguration
        },
                {
            "Names" : "DeploymentProfiles",
            "Children" : deploymentProfileConfiguration
        },
        {
            "Names" : "PolicyProfiles",
            "Children" : deploymentProfileConfiguration
        },
        {
            "Names" : "PlacementProfiles",
            "Children" : placementProfileConfiguration
        }
    ]
/]
