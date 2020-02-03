[#ftl]

[#macro aws_apiusageplan_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local outboundPolicy = [] ]

    [#list solution.Links?values as link]
        [#if link?is_hash]
            [#local linkTarget = getLinkTarget(occurrence, link) ]

            [@debug message="Link Target" context=linkTarget enabled=false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]
            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetRoles = linkTarget.State.Roles ]

            [#if !(linkTarget.Configuration.Solution.Enabled!true) ]
                [#continue]
            [/#if]

            [#switch linkTargetCore.Type]
                [#case APIGATEWAY_COMPONENT_TYPE ]
                    [#local outboundPolicy += linkTargetRoles.Outbound["invoke"] ]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]

    [#assign componentState =
        {
            "Resources" : {
                "apiusageplan" : {
                    "Id" : formatResourceId(AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE, core.Id),
                    "Name" : core.FullName,
                    "Type" : AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE
                }
            },
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {
                    "default" : "invoke",
                    "invoke" : outboundPolicy
                }
            }
        }
    ]
[/#macro]
