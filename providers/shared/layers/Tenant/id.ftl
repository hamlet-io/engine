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
            "Names" : "Providers",
            "Subobjects" : true,
            "Children" : providerReferenceConfiguration
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
