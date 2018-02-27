[#if (componentType == "contenthub") && deploymentSubsetRequired("contenthub", true)]
    [#assign contenthub = component.CONTENTHUB]

    [#list getOccurrences(component, deploymentUnit) as occurrence]

        [#assign contentHubId = formatContentHubHubId(tier, component, occurrence)]
        [#assign contentHubEngine = occurrence.Engine ]
        [#assign contentHubPrefix = occurrence.Prefix ]

        [#if occurrence.Engine == "git ]
            [#assign contentHubBranch = occurrence.Branch ]
        [#else]
            [#assign contentHubBranch = "" ]
        [/#if]

        [#if deploymentSubsetRequired("prologue", false)]
                [@cfScript
                    mode=listMode
                    content=
                    [
                        "function create_contenthub_snapshot() {",
                        "# Create contenthub stack",
                        "create_pseudo_stack" + " " + 
                        "\"RDS Pre-Deploy Snapshot\"" + " " +
                        "\"$\{pseudo_stack_file}\"" + " " +
                        "\"contenthubX" + contentHubId + "Xengine\" " + contentHubEngine +  
                        "\"contenthubX" + contentHubId + "Xurl\" " + contentHubURL +
                        "\"contenthubX" + contentHubId + "Xprefix\" " + contentHubPrefix +  
                        "\"contenthubX" + contentHubId + "Xbranch\" " + contentHubBranch  
                         "|| return $?", 
                        "}",
                        "pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-pseudo-stack.json\" ",
                        "create_contenthub_snapshot || return $?"
                    ]
                /]
        [/#if]
    [/#list]
[/#if]