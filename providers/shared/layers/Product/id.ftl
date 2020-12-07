[#ftl]

[@addLayer
    type=PRODUCT_LAYER_TYPE
    referenceLookupType=PRODUCT_LAYER_REFERENCE_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A product layer"
            }
        ]
    attributes=[
        {
            "Names" : "Id",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Name",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Title",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Description",
            "Type" : STRING_TYPE
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
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Policy",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Placement",
                    "Type" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        },
        {
            "Names" : "CertificateBehaviours",
            "Children" : certificateBehaviourConfiguration
        },
        {
            "Names" : "Builds",
            "Children" : [
                {
                    "Names" : "Data",
                    "Children" : [
                        {
                            "Names" : "Environment",
                            "Type" : STRING_TYPE
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "SES",
            "Children" : [
                {
                    "Names" : "Region",
                    "Type" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        },
        {
            "Names" : "Domain",
            "Type" : STRING_TYPE,
            "Default" : ""
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
