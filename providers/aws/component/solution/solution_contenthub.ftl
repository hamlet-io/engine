[#ftl]
[#macro aws_contenthub_cf_solution occurrence ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["prologue"])
        /]
        [#return]
    [/#if]

    [@cfDebug listMode occurrence false /]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources]

    [#local contentHubId = resources["contenthub"].Id]
    [#local contentHubPrefix = solution.Prefix ]

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
[/#macro]