[#ftl]
[#macro aws_spa_cf_application occurrence]
    [@cfDebug listMode occurrence false /]

    [#assign core = occurrence.Core ]
    [#assign solution = occurrence.Configuration.Solution ]
    [#assign settings = occurrence.Configuration.Settings ]
    [#assign resources = occurrence.State.Resources]

    [#assign fragment = getOccurrenceFragmentBase(occurrence) ]

    [#assign contextLinks = getLinkTargets(occurrence) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks),
            "Environment" : {},
            "Links" : contextLinks,
            "DefaultCoreVariables" : false,
            "DefaultEnvironmentVariables" : false,
            "DefaultLinkVariables" : false
        }
    ]

    [#-- Add in container specifics including override of defaults --]
    [#assign fragmentListMode = "model"]
    [#assign fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#assign _context += getFinalEnvironment(occurrence, _context) ]

    [#if deploymentSubsetRequired("config", false)]
        [@cfConfig
            mode=listMode
            content={ "RUN_ID" : runId } + _context.Environment
        /]
    [/#if]
    [#if deploymentSubsetRequired("prologue", false)]

        [@cfScript
            mode=listMode
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

        [#assign cfId = resources["cf"].Id]

        [@cfScript
            mode=listMode
            content=(getExistingReference(cfId)?has_content)?then(
                [
                    "case $\{STACK_OPERATION} in",
                    "  create|update)"
                ] +
                [
                    "# Invalidate distribution",
                    "info \"Invalidating cloudfront distribution ... \"",
                    "invalidate_distribution" +
                    " \"" + region + "\" " +
                    " \"" + getExistingReference(cfId) + "\" || return $?"

                ] +
                [
                    "       ;;",
                    "       esac"
                ],
                []
            )
        /]
    [/#if]
[/#macro]
