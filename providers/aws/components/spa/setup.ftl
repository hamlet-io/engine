[#ftl]
[#macro aws_spa_cf_application occurrence  ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets=["prologue", "config", "epilogue" ] /]
        [#return]
    [/#if]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local settings = occurrence.Configuration.Settings ]
    [#local resources = occurrence.State.Resources]

    [#if (resources["legacyCF"]!{})?has_content ]
        [@fatal
            message="SPA Cloudfront distributions have been deprecated"
            detail="Please delete the solution SPA stack and add a CDN inbound link on the SPA"
            context=resources["legacyCF"]
        /] 
    [/#if]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]

    [#local baselineLinks = getBaselineLinks(occurrence, [ "OpsData"] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]

    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]) ]

    [#local distributions = [] ]

    [#local contextLinks = getLinkTargets(occurrence) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks, baselineLinks),
            "Environment" : {},
            "Links" : contextLinks,
            "BaselineLinks" : baselineLinks,
            "DefaultCoreVariables" : false,
            "DefaultEnvironmentVariables" : false,
            "DefaultLinkVariables" : false,
            "DefaultBaselineVariables" : false
        }
    ]

    [#-- Add in container specifics including override of defaults --]
    [#local fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#assign _context += getFinalEnvironment(occurrence, _context) ]

    [#list _context.Links as id,linkTarget ]

        [#local linkTargetCore = linkTarget.Core ]
        [#local linkTargetConfiguration = linkTarget.Configuration ]
        [#local linkTargetResources = linkTarget.State.Resources ]
        [#local linkTargetAttributes = linkTarget.State.Attributes ]
        [#local linkDirection = linkTarget.Direction ]

        [#switch linkTargetCore.Type]
            [#case CDN_COMPONENT_TYPE ]
                [#list linkTarget.Occurrences as subLinkTarget ]
                    [#local subLinkAttributes = subLinkTarget.State.Attributes ]
                    [#local subLinkResources = subLinkTarget.State.Resources]
                    [#if subLinkTarget.Core.Type == CDN_ROUTE_COMPONENT_TYPE]
                        [#if linkDirection == "inbound" ]  
                            [#local distributions += [ { 
                                "DistributionId" : subLinkAttributes["DISTRIBUTION_ID"],
                                "PathPattern" :     subLinkResources["origin"].PathPattern
                            }]]   
                        [/#if]
                    [/#if]      
                [/#list]
                [#break]
        [/#switch]
    [/#list]

    [#if ! distributions?has_content ]
        [@fatal 
            message="An SPA must have at least 1 CDN component link"
            detail="Please add an inbound CDN link to your SPA"
            context=solution
            enabled=true
        /]
    [/#if]

    [#if deploymentSubsetRequired("config", false)]
        [@addToDefaultJsonOutput
            content={ "RUN_ID" : runId } + _context.Environment
        /]
    [/#if]
    [#if deploymentSubsetRequired("prologue", false)]

        [@addToDefaultBashScriptOutput
            content=
                getBuildScript(
                    "spaFiles",
                    regionId,
                    "spa",
                    productName,
                    occurrence,
                    "spa.zip"
                ) +
                syncFilesToBucketScript(
                    "spaFiles",
                    regionId,
                    operationsBucket,
                    formatRelativePath(
                        getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX"),
                        "spa"
                    )
                ) +
                getLocalFileScript(
                    "configFiles",
                    "$\{CONFIG}",
                    "config.json"
                ) +
                syncFilesToBucketScript(
                    "configFiles",
                    regionId,
                    operationsBucket,
                    formatRelativePath(
                        getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX"),
                        "config"
                    )
                ) /] 
    [/#if]

    [#if solution.InvalidateOnUpdate && distributions?has_content ]
        [#local invalidationScript = []]
        [#list distributions as distribution ]
            [#local distributionId = distribution.DistributionId ]
            [#local pathPattern = distribution.PathPattern]

            [#local invalidationScript += [
                "       # Invalidate distribution",
                "       info \"Invalidating cloudfront distribution " + distributionId + " " + pathPattern + "\"",
                "       invalidate_distribution" +
                "       \"" + region + "\" " +
                "       \"" + distributionId + "\" " +
                "       \"" + pathPattern + "\" || return $?"
            ]]
        [/#list]

        [#if deploymentSubsetRequired("epilogue", false)]
            [@addToDefaultBashScriptOutput
                [
                    "case $\{STACK_OPERATION} in",
                    "  create|update)"
                ] + 
                invalidationScript +
                [
                    " ;;",
                    " esac"
                ]
            /]
        [/#if]
    [/#if]
[/#macro]
