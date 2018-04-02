[#if componentType = "spa"]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]

        [#assign containerId =
            solution.Container?has_content?then(
                solution.Container,
                getComponentId(component)                            
            ) ]
        [#assign context = 
            {
                "Id" : containerId,
                "Name" : containerId,
                "Instance" : core.Instance.Id,
                "Version" : core.Version.Id,
                "Environment" : 
                    {
                        "TEMPLATE_TIMESTAMP" : .now?iso_utc,
                        "BUILD_REFERENCE" : getOccurrenceBuildReference(occurrence)
                    } +
                    attributeIfContent(
                        "APP_REFERENCE", 
                        getOccurrenceSettingValue(occurrence, "APP_REFERENCE", true)),
                "Links" : getLinkTargets(occurrence),
                "DefaultLinkVariables" : false
            }
        ]

        [#-- Add in container specifics including override of defaults --]
        [#assign containerListMode = "model"]
        [#assign containerId = formatContainerFragmentId(occurrence, context)]
        [#include containerList?ensure_starts_with("/")]

        [#if context.DefaultLinkVariables]
            [#assign context = addDefaultLinkVariablesToContext(context) ]
        [/#if]

        [#if deploymentSubsetRequired("config", false)]
            [@cfConfig
                mode=listMode
                content=context.Environment
            /]
        [/#if]
        [#if deploymentSubsetRequired("prologue", false)]
            [@cfScript
                mode=listMode
                content=
                  [
                      "function get_spa_file() {",
                      "  #",
                      "  #",
                      "  # Fetch the spa zip file",
                      "  copyFilesFromBucket" + " " +
                          regionId + " " + 
                          getRegistryEndPoint("spa", occurrence) + " " +
                          formatRelativePath(
                              getRegistryPrefix("spa", occurrence) + productName,
                              buildDeploymentUnit,
                              getOccurrenceBuildReference(occurrence)) + " " +
                        "   \"$\{tmpdir}\" || return $?",
                      "  #",
                      "  # Sync with the operations bucket",
                      "  copy_spa_file \"$\{tmpdir}/spa.zip\"",
                      "}",
                      "#",
                      "get_spa_file"
                  ]
            /]
        [/#if]
    [/#list]
[/#if]
