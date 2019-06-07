[#-- Content Hub --]

[#if (componentType == CONTENTHUB_HUB_COMPONENT_TYPE) ]

    [#list requiredOccurrences(
        getOccurrences(tier, component),
        deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources]

        [#assign contentHubId = resources["contenthub"].Id]
        [#assign contentHubPrefix = solution.Prefix ]

        [#if deploymentSubsetRequired("prologue", false)]
            [@cfScript
                mode=listMode
                content=[
                        "info \"Creating Contenthub Pseudo Stack\""
                    ] + 
                    pseudoStackOutputScript(
                        "Content Hub Deployment",
                        { 
                            formatId(contentHubId, "engine") : solution.Engine,
                            formatId(contentHubId, "repository") : solution.Repository,
                            formatId(contentHubId, "prefix") : contentHubPrefix,
                            formatId(contentHubId, "branch") : solution.Branch
                        }
                    )
            /]
        [/#if]
    [/#list]
[/#if]