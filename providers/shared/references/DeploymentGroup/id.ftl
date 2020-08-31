[#ftl]

[@addReference
    type=DEPLOYMENTGROUP_REFERENCE_TYPE
    pluralType="DeploymentGroups"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collection of deployment units and their relationships"
            }
        ]
    attributes=[
        {
            "Names" : "Enabled",
            "Type" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Deployment",
            "Children" : [
                {
                    "Names" : "Level",
                    "Description" : "The deployment level to use for template generation",
                    "Type" : STRING_TYPE,
                    "Values" : [ "", "account", "segment", "solution", "application" ],
                    "Mandatory" : true
                },
                {
                    "Names" : "ResourceSets",
                    "Description" : "Generate deployments based on resource labels across all units in the group",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "DeploymentUnit",
                            "Description" : "The Deployment Unit for the subset deployment",
                            "Type" : STRING_TYPE,
                            "Mandatory" : true
                        },
                        {
                            "Names" : "ResourceLabels",
                            "Description" : "The resource labels to include in the subset",
                            "Type" : ARRAY_OF_STRING_TYPE,
                            "Mandatory" : true
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "CompositeTemplate",
            "Description" : "A composite template file to include for this group",
            "Type" : STRING_TYPE,
            "Default" : ""
        }
    ]
/]


[#function getDeploymentGroup deploymentGroup  ]
    [#local deploymentGroups = getReferenceData(DEPLOYMENTGROUP_REFERENCE_TYPE)]

    [#if ! (deploymentGroups[deploymentGroup]!{})?has_content ]
        [#return {}]
    [/#if]

    [#return
        mergeObjects(
            {
                "Id" : deploymentGroup,
                "Name" : (deploymentGroups[deploymentGroup].Name)!deploymentGroup
            },
            deploymentGroups[deploymentGroup]
        )
    ]
[/#function]
