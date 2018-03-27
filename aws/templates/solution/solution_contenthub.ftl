[#if (componentType == "contenthub") ]

    [#list requiredOccurrences(
        getOccurrences(tier, component),
        deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign configuration = occurrence.Configuration]
        [#assign resources = occurrence.State.Resources]

        [#assign contentHubId = resources["contenthub"].Id]
        [#assign contentHubPrefix = configuration.Prefix ]

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
                        "\"" + contentHubId + "Xengine\" \"" + configuration.Engine + "\" " +  
                        "\"" + contentHubId + "Xrepository\" \"" + configuration.Repository + "\" " +
                        "\"" + contentHubId + "Xprefix\" \"" + contentHubPrefix + "\" " +
                        "\"" + contentHubId + "Xbranch\" \"" + configuration.Branch + "\" " +
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