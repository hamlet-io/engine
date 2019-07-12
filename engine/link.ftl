[#ftl]

[#----------------------------------------
-- Public functions for link processing --
------------------------------------------]

[#function getLinkTarget occurrence link activeOnly=true activeRequired=false]

    [#local instanceToMatch = link.Instance!(getOccurrenceInstance(occurrence).Id) ]
    [#local versionToMatch = link.Version!(getOccurrenceVersion(occurrence).Id) ]

    [@debug
        message="Getting link Target"
        context=
            {
                "Occurrence" : occurrence,
                "Link" : link,
                "EffectiveInstance" : instanceToMatch,
                "EffectiveVersion" : versionToMatch
            }
        enabled=false
    /]
    [#if ! (link.Enabled)!true ]
        [#return {} ]
    [/#if]

    [#if link.Tier?lower_case == "external"]
        [#-- If a type is provided, ensure it has been included --]
        [#if link.Type??]
            [@includeComponentConfiguration link.Type /]
        [/#if]
        [#return
            createOccurrenceFromExternalLink(occurrence, link) +
            {
                "Direction" : link.Direction!"outbound",
                "Role" : link.Role!"external"
            }
        ]
    [/#if]

    [#list getOccurrences(
                getTier(link.Tier),
                getComponent(link.Tier, link.Component)) as targetOccurrence]

        [@debug
            message="Possible link target"
            context=targetOccurrence
            enabled=false
        /]

        [#local targetType = getOccurrenceType(targetOccurrence) ]

        [#local targetSubOccurrences = [targetOccurrence] ]
        [#local subComponentId = "" ]

        [#-- Check if suboccurrence linking is required --]
        [#-- Support multiple alternatives --]
        [#local subComponents = getComponentChildren(targetType) ]
        [#list subComponents as subComponent]
            [#list getComponentChildLinkAttributes(subComponent) as linkAttribute]
                [#local subComponentId = link[linkAttribute]!"" ]
                [#if subComponentId?has_content ]
                    [#break]
                [/#if]
            [/#list]
            [#if subComponentId?has_content ]
                [#break]
            [/#if]
        [/#list]

        [#-- Legacy support for links to lambda without explicit function --]
        [#-- TODO(mfl): Review legacy support with view to removal --]
        [#if hasOccurrenceChildren(targetOccurrence) &&
                subComponentId == "" &&
                (targetType == LAMBDA_COMPONENT_TYPE) ]
            [#local subComponentId = (getOccurrenceChildren(targetOccurrence)[0].Core.SubComponent.Id)!"" ]
        [/#if]

        [#if subComponentId?has_content]
            [#local targetSubOccurrences = getOccurrenceChildren(targetOccurrence) ]
        [/#if]

        [#list targetSubOccurrences as targetSubOccurrence]

            [#-- Subcomponent checking --]
            [#if subComponentId?has_content &&
                    (subComponentId != (getOccurrenceSubComponent(targetSubOccurrence).Id)!"") ]
                [#continue]
            [/#if]

            [#-- Match needs to be exact                            --]
            [#-- If occurrences do not match, overrides can be added --]
            [#-- to the link.                                       --]
            [#if (getOccurrenceInstance(targetSubOccurrence).Id != instanceToMatch) ||
                (getOccurrenceVersion(targetSubOccurrence).Id != versionToMatch) ]
                [#continue]
            [/#if]

            [@debug message="Link matched target" enabled=false /]

            [#-- Determine if deployed --]
            [#if ( activeOnly || activeRequired ) && !isOccurrenceDeployed(targetSubOccurrence) ]
                [#if activeRequired ]
                    [@postcondition
                        function="getLinkTarget"
                        context=
                            {
                                "Occurrence" : occurrence,
                                "Link" : link,
                                "EffectiveInstance" : instanceToMatch,
                                "EffectiveVersion" : versionToMatch
                            }
                        detail="COTFatal:Link target not active/deployed"
                        enabled=true
                    /]
                [/#if]
                [#return {} ]
            [/#if]

            [#-- Determine the role --]
            [#local direction = link.Direction!"outbound"]

            [#local role =
                link.Role!getOccurrenceDefaultRole(targetSubOccurrence, direction)]

            [#return
                targetSubOccurrence +
                {
                    "Direction" : direction,
                    "Role" : role
                } ]
        [/#list]
    [/#list]

    [@postcondition
        function="getLinkTarget"
        context=
            {
                "Occurrence" : occurrence,
                "Link" : link,
                "EffectiveInstance" : instanceToMatch,
                "EffectiveVersion" : versionToMatch
            }
        detail="COTFatal:Link not found"
    /]
    [#return {} ]
[/#function]

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
        [#local role = getOccurrenceRole(linkTarget, "Outbound", linkTarget.Role) ]
        [#if (linkTarget.Direction == "outbound") && role?has_content ]
            [#local roles += asArray(role![]) ]
        [/#if]
    [/#list]
    [#return roles]
[/#function]

[#--------------------------------------------------
-- Internal support functions for link processing --
----------------------------------------------------]
