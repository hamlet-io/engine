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
            "Type" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Operations",
            "Description" : "The deployment operations to complete for each deployment",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Values" : [ "create", "update", "delete" ],
            "Default" : [ "update" ]
        },
        {
            "Names" : "ExecutionPolicy",
            "Description" : "Defines how groups can be used in this deployment mode",
            "Type" : STRING_TYPE,
            "Values" : [ "Required", "Optional" ],
            "Default" : "Optional"
        },
        {
            "Names" : "Membership",
            "Description" : "How deployment groups are included in the mode and their ordering",
            "Type" : STRING_TYPE,
            "Values" : [ "explicit", "priority" ],
            "Mandatory" : true
        },
        {
            "Names" : "Priority",
            "Description" : "Controls for priority membership",
            "Children" : [
                {
                    "Names" : "GroupFilter",
                    "Description" : "A regex filter to apply on group ids to include in the mode",
                    "Type" : STRING_TYPE,
                    "Default" : ".*"
                },
                {
                    "Names" : "Order",
                    "Description" : "How to evalute the priority ordering",
                    "Type" : STRING_TYPE,
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
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        }
    ]
/]

[#function getDeploymentMode ]
    [#local deploymentModeDetails = getDeploymentModeDetails(commandLineOptions.Deployment.Mode)]
    [#return (deploymentModeDetails.Name)!""]
[/#function]

[#function getDeploymentModeDetails deploymentMode  ]
    [#local deploymentModes = getReferenceData(DEPLOYMENTMODE_REFERENCE_TYPE)]
    [#local deploymentModeDetails = {}]

    [#if (deploymentModes[deploymentMode]!{})?has_content && deploymentModes[deploymentMode].Enabled ]
        [#local deploymentModeDetails = deploymentModes[deploymentMode]]
    [/#if]

    [#if !(deploymentModeDetails?has_content) &&
            (deploymentModes["_default"]!{})?has_content && deploymentModes["_default"].Enabled  ]
        [#local deploymentModeDetails = deploymentModes["_default"]]
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
