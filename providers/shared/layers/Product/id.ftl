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
            "Names" : "*",
            "Description" : "Individual deployment-unit configuration overrides. Attribute must match the DeploymentUnit value.",
            "Types" : OBJECT_TYPE,
            "Children" : [
                {
                    "Names" : "Region",
                    "Description" : "An override of the Region for a single DeploymentUnit.",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Region",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Domain",
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
            "Names" : "Builds",
            "Children" : [
                {
                    "Names" : "Data",
                    "Children" : [
                        {
                            "Names" : "Environment",
                            "Types" : STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "Code",
                    "Children" : [
                        {
                            "Names" : "Environment",
                            "Types" : STRING_TYPE
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
                    "Types" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        },
        {
            "Names" : "Domain",
            "Types" : STRING_TYPE,
            "Default" : ""
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
