[#ftl]
[#macro application_apiusageplan tier component]
    [#-- API Gateway Usage Plan --]
    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]
        [#assign attributes = occurrence.State.Attributes ]
        [#assign roles = occurrence.State.Roles]

        [#assign planId   = resources["apiusageplan"].Id]
        [#assign planName = resources["apiusageplan"].Name]

        [#assign stages = [] ]

        [#list solution.Links?values as link]
            [#if link?is_hash]
                [#assign linkTarget = getLinkTarget(occurrence, link) ]

                [@cfDebug listMode linkTarget false /]

                [#if !linkTarget?has_content ]
                    [#continue]
                [/#if]

                [#assign linkTargetCore = linkTarget.Core ]
                [#assign linkTargetConfiguration = linkTarget.Configuration ]
                [#assign linkTargetResources = linkTarget.State.Resources ]
                [#assign linkTargetAttributes = linkTarget.State.Attributes ]

                [#switch linkTargetCore.Type]
                    [#case APIGATEWAY_COMPONENT_TYPE ]
                        [#assign stages +=
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
                mode=listMode
                id=planId
                name=planName
                stages=stages
            /]
        [/#if]

    [/#list]
[/#macro]
