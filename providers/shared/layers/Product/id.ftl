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
    inputFilterAttributes=[
            {
                "Id" : PRODUCT_LAYER_TYPE,
                "Description" : "The product"
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
            "AttributeSet" : MODULE_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "Plugins",
            "SubObjects" : true,
            "AttributeSet" : PLUGIN_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "LinkRefs",
            "SubObjects" : true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
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
        },
        {
            "Names" : "TagSet",
            "Description" : "The TagSet to apply",
            "Type" : STRING_TYPE,
            "Default" : "default"
        }
    ]
/]

[#-- Temporary function --]
[#-- TODO(mfl) remove once integrated into the input pipeline --]
[#function getProductLayerRegion ]
    [#local product = getActiveLayer(PRODUCT_LAYER_TYPE) ]
    [#return (product[getCLODeploymentUnit()].Region)!product.Region!"" ]
[/#function]

[#function getProductLayerFilters filter]
    [#local result = filter ]

    [#-- Special defaulting for region --]
    [#if ! isFilterAttribute(filter, "Region") ]
        [#local result += attributeIfContent("Region", getProductLayerRegion()) ]
    [/#if]

    [#return result ]
[/#function]
