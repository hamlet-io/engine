[#ftl]
[#macro aws_apiusageplan_cf_generationcontract_application occurrence ]
    [@addDefaultGenerationContract subsets="template" /]
[/#macro]

[#macro aws_apiusageplan_cf_setup_application occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]
    [#local attributes = occurrence.State.Attributes ]
    [#local roles = occurrence.State.Roles]

    [#local planId   = resources["apiusageplan"].Id]
    [#local planName = resources["apiusageplan"].Name]

    [#local stages = [] ]

    [#list solution.Links?values as link]
        [#if link?is_hash]
            [#local linkTarget = getLinkTarget(occurrence, link) ]

            [@debug message="Link Target" context=linkTarget enabled=false /]

            [#if !linkTarget?has_content ]
                [#continue]
            [/#if]

            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetConfiguration = linkTarget.Configuration ]
            [#local linkTargetResources = linkTarget.State.Resources ]
            [#local linkTargetAttributes = linkTarget.State.Attributes ]

            [#switch linkTargetCore.Type]
                [#case APIGATEWAY_COMPONENT_TYPE ]
                    [#local stages +=
                        [
                            {
                                "ApiId" : getReference(linkTargetResources["apigateway"].Id),
                                "Stage" : linkTargetResources["apistage"].Name
                            }
                        ]
                    ]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]

    [#if deploymentSubsetRequired("apiusageplan", true)]
        [@createAPIUsagePlan
            id=planId
            name=planName
            stages=stages
        /]
    [/#if]
[/#macro]
