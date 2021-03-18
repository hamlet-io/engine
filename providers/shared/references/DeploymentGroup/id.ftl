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
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Priority",
            "Description" : "The priority this group has in deployment mode processing",
            "Types" : NUMBER_TYPE,
            "Default" : 100
        },
        {
            "Names" : "Level",
            "Description" : "The deployment level to use for template generation",
            "Types" : STRING_TYPE,
            "Values" : [ "", "account", "segment", "solution", "application" ],
            "Mandatory" : true
        },
        {
            "Names" : "OutputPrefix",
            "Description" : "Overrides the prefix used when generating outputs - Defaults to the Id of the Group",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "ResourceSets",
            "Description" : "Generate deployments based on resource labels across all units in the group",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "deployment:Unit",
                    "Description" : "The Deployment Unit",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "deployment:Priority",
                    "Description" : "The Deployment Priority",
                    "Types" : NUMBER_TYPE,
                    "Default" : 5
                },
                {
                    "Names" : "ResourceLabels",
                    "Description" : "The resource labels to include in the subset",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Mandatory" : true
                }
            ]
        },
        {
            "Names" : "CompositeTemplate",
            "Description" : "A composite template file to include for this group",
            "Types" : STRING_TYPE,
            "Default" : ""
        }
    ]
/]

[#function getDeploymentGroup ]
    [#local deploymentGroupDetails = getDeploymentGroupDetails(getCLODeploymentGroup())]
    [#return (deploymentGroupDetails.Name)!""]
[/#function]

[#function getDeploymentLevel ]
    [#local deploymentGroupDetails = getDeploymentGroupDetails(getCLODeploymentGroup())]
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

[#function getDeploymentGroupFromOutputPrefix outputPrefix ]
    [#local levelMatches = [] ]
    [#local groupMatches = []]

    [#list getDeploymentGroups()?keys as deploymentGroup ]
        [#local details = getDeploymentGroupDetails(deploymentGroup)]

        [#if (details.OutputPrefix)?? && details.OutputPrefix == outputPrefix ]
            [#local levelMatches = combineEntities( levelMatches, [ deploymentGroup ], UNIQUE_COMBINE_BEHAVIOUR ) ]
        [/#if]

        [#if deploymentGroup == outputPrefix ]
            [#local groupMatches = combineEntities( groupMatches, [ deploymentGroup ], UNIQUE_COMBINE_BEHAVIOUR ) ]
        [/#if]
    [/#list]

    [#if levelMatches?has_content ]
        [#return levelMatches ]
    [#else]
        [#return groupMatches![]]
    [/#if]
[/#function]

[#function getDeploymentGroups ]
    [#return getReferenceData(DEPLOYMENTGROUP_REFERENCE_TYPE) ]
[/#function]
