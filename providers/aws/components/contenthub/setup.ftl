[#ftl]
[#macro aws_contenthub_cf_generationcontract_solution occurrence ]
    [@addDefaultGenerationContract subsets="prologue" /]
[/#macro]

[#macro aws_contenthub_cf_setup_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

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
