[#ftl]
[#macro aws_contenthub_cf_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets="prologue" /]
        [#return]
    [/#if]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources]

    [#local contentHubId = resources["contenthub"].Id]
    [#local contentHubPrefix = solution.Prefix ]

    [#if deploymentSubsetRequired("prologue", false)]
        [@addToDefaultBashScriptOutput
            content=[
                    "info \"Creating Contenthub Pseudo Stack\""
                ] +
                pseudoStackOutputScript(
                    "Content Hub Deployment",
                    {
                        formatId(contentHubId)                  : contentHubId,
                        formatId(contentHubId, "engine")        : solution.Engine,
                        formatId(contentHubId, "repository")    : solution.Repository,
                        formatId(contentHubId, "prefix")        : contentHubPrefix,
                        formatId(contentHubId, "branch")        : solution.Branch
                    }
                )
        /]
    [/#if]
[/#macro]