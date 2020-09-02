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
            "Names" : "Priority",
            "Description" : "The priority this group has in deployment mode processing",
            "Type" : NUMBER_TYPE,
            "Default" : 100
        },
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
                    "Names" : "deployment:Unit",
                    "Description" : "The Deployment Unit",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "deployment:Priority",
                    "Description" : "The Deployment Priority",
                    "Type" : NUMBER_TYPE,
                    "Default" : 5
                },
                {
                    "Names" : "ResourceLabels",
                    "Description" : "The resource labels to include in the subset",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Mandatory" : true
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

[#function getDeploymentGroup ]
    [#local deploymentGroupDetails = getDeploymentGroupDetails(commandLineOptions.Deployment.Group.Name)]
    [#return (deploymentGroupDetails.Name)!""]
[/#function]

[#function getDeploymentLevel ]
    [#local deploymentGroupDetails = getDeploymentGroupDetails(commandLineOptions.Deployment.Group.Name)]
    [#return (deploymentGroupDetails.Level)!""]
[/#function]

[#function getDeploymentGroupDetails deploymentGroup  ]
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

[#function getDeploymentGroups ]
    [#return getReferenceData(DEPLOYMENTGROUP_REFERENCE_TYPE) ]
[/#function]
