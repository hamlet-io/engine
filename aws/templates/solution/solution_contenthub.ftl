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
                content=
                [
                    "function create_contenthub_snapshot() {",
                        "# Create contenthub stack",
                        "create_pseudo_stack" + " " + 
                        "\"Content Hub Deployment\"" + " " +
                        "\"$\{pseudo_stack_file}\"" + " " +
                        "\"" + contentHubId + "Xengine\" \"" + solution.Engine + "\" " +  
                        "\"" + contentHubId + "Xrepository\" \"" + solution.Repository + "\" " +
                        "\"" + contentHubId + "Xprefix\" \"" + contentHubPrefix + "\" " +
                        "\"" + contentHubId + "Xbranch\" \"" + solution.Branch + "\" " +
                        "|| return $?", 
                    "}",
                    "pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-pseudo-stack.json\" ",
                    "info \"Creating Contenthub Pseudo Stack\"",
                    "create_contenthub_snapshot || return $?"
                ]
            /]
        [/#if]
    [/#list]
[/#if]