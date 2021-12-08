[#ftl]

[@addReference
    type=DEPLOYMENTMODE_REFERENCE_TYPE
    pluralType="DeploymentModes"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collection of deployment groups which are executed in a defined order"
            }
        ]
    attributes=[
        {
            "Names" : "Enabled",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Operations",
            "Description" : "The deployment operations to complete for each deployment",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Values" : [ "create", "update", "delete" ],
            "Default" : [ "update" ]
        },
        {
            "Names" : "ExecutionPolicy",
            "Description" : "Defines how groups can be used in this deployment mode",
            "Types" : STRING_TYPE,
            "Values" : [ "Required", "Optional" ],
            "Default" : "Optional"
        },
        {
            "Names" : "Membership",
            "Description" : "How deployment groups are included in the mode and their ordering",
            "Types" : STRING_TYPE,
            "Values" : [ "explicit", "priority", "orphaned" ],
            "Mandatory" : true
        },
        {
            "Names" : "Priority",
            "Description" : "Controls for priority membership",
            "Children" : [
                {
                    "Names" : "GroupFilter",
                    "Description" : "A regex filter to apply on group ids to include in the mode",
                    "Types" : STRING_TYPE,
                    "Default" : ".*"
                },
                {
                    "Names" : "Order",
                    "Description" : "How to evalute the priority ordering",
                    "Types" : STRING_TYPE,
                    "Values" : [ "HighestFirst", "LowestFirst" ],
                    "Default" : "LowestFirst"
                }
            ]
        },
        {
            "Names" : "Explicit",
            "Description" : "Controls for explicit membership",
            "Children" : [
                {
                    "Names" : "Groups",
                    "Description" : "A list of group ids in their deployment order",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        }
    ]
/]

[#function getDeploymentMode ]
    [#local deploymentModeDetails = getDeploymentModeDetails(getCLODeploymentMode())]
    [#return (deploymentModeDetails.Name)!""]
[/#function]

[#function getDeploymentModeDetails deploymentMode  ]
    [#local deploymentModes = getReferenceData(DEPLOYMENTMODE_REFERENCE_TYPE)]
    [#local deploymentModeDetails = {}]

    [#if (deploymentModes[deploymentMode]!{})?has_content && deploymentModes[deploymentMode].Enabled ]
        [#local deploymentModeDetails = deploymentModes[deploymentMode]]
    [/#if]

    [#if deploymentModeDetails?has_content ]
        [#return
            mergeObjects(
                {
                    "Id" : deploymentMode,
                    "Name" : (deploymentModeDetails.Name)!deploymentMode,
                    "Enabled" : (deploymentModeDetails.Enabled)!false
                },
                deploymentModeDetails
            )
        ]
    [#else]
        [#return {}]
    [/#if]
[/#function]
