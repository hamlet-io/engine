[#ftl]

[#assign SEED_RESOURCE_TYPE = "seed" ]

[#function formatSegmentSeedId ]
    [#return formatSegmentResourceId(SEED_RESOURCE_TYPE)]
[/#function]

[#function getBaselineComponentIds links cmk="cmk" ssh="ec2KeyPair" oai="originAccessId" storage="bucket"]
    [#local ids = {}]
    [#list links as linkName, linkTarget ]
        [#if !linkTarget?has_content]
            [@precondition
                function="getBaselineComponentIds"
                context=links
                detail="Link " + linkName + " has no target"
            /]
            [#continue]
        [/#if]
        [#local linkTargetCore = linkTarget.Core ]
        [#local linkTargetSolution = linkTarget.Configuration.Solution ]
        [#local linkTargetResources = linkTarget.State.Resources ]

        [#switch linkTargetCore.Type]
            [#case BASELINE_DATA_COMPONENT_TYPE ]
                [#local ids += { linkName, linkTargetResources[storage].Id }]
                [#break]

            [#case BASELINE_KEY_COMPONENT_TYPE ]
                [#switch linkTargetSolution.Engine ]
                    [#case "cmk" ]
                        [#if linkTargetResources[cmk].Id?has_content]
                            [#local ids += { linkName, linkTargetResources[cmk].Id }]
                        [#else]
                            [@fatal
                                message="CMK resource has not been found. A CMK is a mandatory baseline resource."
                                context=linkTarget
                            /]
                        [/#if]
                        [#break]
                    [#case "ssh" ]
                        [#if linkTargetResources[ssh].Id?has_content]
                            [#local ids += { linkName, linkTargetResources[ssh].Id }]
                        [#else]
                            [@fatal
                                message="SSH resource has not been found. A SSH resource is a mandatory baseline resource."
                                context=linkTarget
                            /]
                        [/#if]
                        [#break]
                    [#case "oai"]
                        [#if linkTargetResources[oai].Id?has_content]
                            [#local ids += { linkName, linkTargetResources[oai].Id }]
                        [/#if]
                        [#break]
                [/#switch]
                [#break]

            [#default]
                [@fatal
                    message="Unknown baseline subcomponent when looking up component id"
                    context=linkTarget
                /]
        [/#switch]
    [/#list]
    [#return ids ]
[/#function]

[#function getBaselineLinks occurrence baselineComponentNames activeOnly=true activeRequired=true  ]
    [#local baselineProfile = baselineProfiles[occurrence.Configuration.Solution.Profiles.Baseline] ]

    [#local baselineLinkTargets = {} ]

    [#list baselineProfile as key,value ]
        [#if baselineComponentNames?seq_contains(key)]
            [#switch key?lower_case ]
                [#case "opsdata" ]
                [#case "appdata" ]
                    [#local subComponentType = "DataBucket" ]
                    [#break]

                [#case "encryption" ]
                [#case "sshkey" ]
                [#case "cdnoriginkey" ]
                    [#local subComponentType = "Key" ]
                    [#break]

                [#default]
                    [@fatal
                        message="Unknown baseline subcomponent"
                        context=key
                    /]
            [/#switch]

            [#local baselineLink =
                {
                    "Id" : "baseline",
                    "Name" : "baseline",
                    "Tier" : "mgmt",
                    "Component" : "baseline",
                    "Instance" : "",
                    "Version" : "",
                    subComponentType : value
                }
            ]
            [#local baselineLinkTarget = getLinkTarget(occurrence, baselineLink, activeOnly, activeRequired )]

            [#-- Skip missing targets --]
            [#if baselineLinkTarget?has_content]
                [#local baselineLinkTargets += {
                        key : baselineLinkTarget
                    } ]
            [/#if]
        [/#if]
    [/#list]

    [#return baselineLinkTargets ]
[/#function]

[@addComponentDeployment
    type=BASELINE_COMPONENT_TYPE
    lockAttributes=true
    defaultUnit="baseline"
    defaultPriority=1
    defaultGroup="segment"
/]

[@addComponent
    type=BASELINE_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A set of resources required for every segment deployment"
            }
        ]
    attributes=
        [
            {
                "Names" : "Active",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Seed",
                "Children" : [
                    {
                        "Names" : "Length",
                        "Types" : NUMBER_TYPE,
                        "Default" : 10
                    }
                ]
            }
        ]
/]

[@addChildComponent
    type=BASELINE_DATA_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A segment shared data store"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "segment"
            }
        ]
    attributes=
        [
            {
                "Names" : "Role",
                "Types" : STRING_TYPE,
                "Values" : [ "appdata", "operations", "staticWebsite" ],
                "Mandatory" : true
            },
            {
                "Names" : "Lifecycles",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Prefix",
                        "Types" : STRING_TYPE,
                        "Description" : "The prefix to apply the lifecycle to"
                    }
                    {
                        "Names" : "Expiration",
                        "Types" : [STRING_TYPE, NUMBER_TYPE],
                        "Description" : "Provide either a date or a number of days",
                        "Default" : "_operations"
                    },
                    {
                        "Names" : "Offline",
                        "Types" : [STRING_TYPE, NUMBER_TYPE],
                        "Description" : "Provide either a date or a number of days",
                        "Default" : "_operations"
                    }
                ]
            },
            {
                "Names" : "Versioning",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Notifications",
                "Subobjects" : true,
                "Children" : s3NotificationChildConfiguration
            },
            {
                "Names" : "Encryption",
                "Children" : s3EncryptionChildConfiguration
            },
            {
                "Names" : "Replication",
                "Children" : [
                    {
                        "Names" : "Prefixes",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ "" ]
                    },
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            }
        ]
    parent=BASELINE_COMPONENT_TYPE
    childAttribute="DataBuckets"
    linkAttributes="DataBucket"
/]

[@addChildComponent
    type=BASELINE_KEY_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Shared security keys for a segment"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "segment"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Types" : STRING_TYPE,
                "Values" : [ "cmk", "ssh", "oai", "cmk-account" ],
                "Mandatory" : true
            },
            {
                "Names" : "IPAddressGroups",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : ["_global"]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
    parent=BASELINE_COMPONENT_TYPE
    childAttribute="Keys"
    linkAttributes="Key"
/]
