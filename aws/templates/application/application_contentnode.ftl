[#if componentType = "contentnode"]

    [#list requiredOccurrences(
            getOccurrences(component, tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]

        [#assign contentNodeId = formatContentHubNodeId(tier, component, occurrence) ]
        [#assign pathObject = getContentPath(occurrence, component) ]

        [#if ! (configuration.Links?has_content)]
            [@cfPreconditionFailed listMode "contentnode" occurrence "No content hub link configured" /]
            [#break]
        [/#if]

        [#list configuration.Links?values as link]
            [#if link?is_hash]
                [#assign linkTarget = getLinkTarget(occurrence, link) ]
                [#assign linkTargetCore = linkTarget.Core ]
                [#assign linkTargetConfiguration = linkTarget.Configuration ]
                [#assign linkTargetAttributes = linkTarget.State.Attributes ]

                [#switch linkTargetCore.Type!""]
                    [#case "contenthub"]
                        [#if linkTargetAttributes.ENGINE == "git" ]
                            [#assign branch = linkTargetAttributes.BRANCH!""]
                            [#assign url = linkTargetAttributes.URL!""]
                        [/#if]
                        [#if deploymentSubsetRequired("prologue", false)]
                            [@cfScript
                                mode=listMode
                                content=
                                [
                                    "function get_contentnode_file() {",
                                    "  #",
                                    "  #",
                                    "  # Fetch the spa zip file",
                                    "  copyFilesFromBucket" + " " +
                                        regionId + " " + 
                                        getRegistryEndPoint("contentnode") + " " +
                                        formatRelativePath(
                                            getRegistryPrefix("contentnode") + productName,
                                            buildDeploymentUnit,
                                            buildCommit) + " " +
                                        "   \"$\{tmpdir}\" || return $?",
                                    "  #",
                                    "  # Sync with the operations bucket",
                                    "  copy_contentnode_file \"$\{tmpdir}/contentnode.zip\" " + 
                                            "\"" + linkTargetAttributes.ENGINE + "\" " +
                                            "\"" +    linkTargetAttributes.URL + "\" " + 
                                            "\"" +    linkTargetAttributes.PREFIX + "\" " +
                                            "\"" +    pathObject + "\" " +
                                            "\"" +    linkTargetAttributes.BRANCH + "\" ",
                                    "}",
                                    "#",
                                    "get_contentnode_file"
                                ]
                            /]
                        [/#if]
                    [#break]
                [/#switch]     
            [/#if]
        [/#list]
    [/#list]
[/#if]
