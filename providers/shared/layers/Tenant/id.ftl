[#ftl]

[@addLayer
    type=TENANT_LAYER_TYPE
    referenceLookupType=TENANT_LAYER_REFERENCE_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A tenant layer"
            }
        ]
    inputFilterAttributes=[
            {
                "Id" : TENANT_LAYER_TYPE,
                "Description" : "The tenant"
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
            "Names" : "Region",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Modules",
            "SubObjects" : true,
            "Children"  : moduleReferenceConfiguration
        },
        {
            "Names" : "Plugins",
            "SubObjects" : true,
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
            "SubObjects" : true,
            "Children" : deploymentProfileConfiguration
        },
        {
            "Names" : "PolicyProfiles",
            "SubObjects" : true,
            "Children" : deploymentProfileConfiguration
        },
        {
            "Names" : "PlacementProfiles",
            "SubObjects" : true,
            "Children" : placementProfileConfiguration
        }
    ]
/]
