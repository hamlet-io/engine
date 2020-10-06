[#ftl]

[#----------------------------------------
-- Public functions for link processing --
------------------------------------------]

[#function getLinkTargets occurrence links={} activeOnly=true activeRequired=false ]
    [#local result={} ]
    [#list (valueIfContent(links, links, getOccurrenceSolution(occurrence).Links!{}))?values as link]
        [#if link?is_hash]
            [#local linkTarget = getLinkTarget(occurrence, link, activeOnly, activeRequired) ]
            [#local result +=
                valueIfContent(
                    {
                        link.Name : linkTarget
                    },
                    linkTarget
                )]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#function isLinkTargetActive target]
    [#return
        isOccurrenceEnabled(target) &&
        (isOccurrenceDeployed(target) || isOccurrenceExternal(target)) ]
[/#function]

[#function getLinkTargetsOutboundRoles LinkTargets ]
    [#local roles = [] ]
    [#list LinkTargets?values as linkTarget]
        [#if !isLinkTargetActive(linkTarget) ]
            [#continue]
        [/#if]
        [#if linkTarget.Role != "networkacl" ]
            [#local role = getOccurrenceRole(linkTarget, "Outbound", linkTarget.Role) ]
            [#if (linkTarget.Direction?lower_case == "outbound") && role?has_content  ]
                [#local roles += asArray(role![]) ]
            [/#if]
        [/#if]
    [/#list]
    [#return roles]
[/#function]

[#--------------------------------------------------
-- Internal support functions for link processing --
----------------------------------------------------]
