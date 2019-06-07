[#-- Content Node --]

[#if componentType = "contentnode"]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources]

        [#assign contentNodeId = resources["contentnode"].Id ]
        [#assign pathObject = getContentPath(occurrence) ]

        [#if ! (solution.Links?has_content)]
            [@cfPreconditionFailed listMode "contentnode" occurrence "No content hub link configured" /]
            [#break]
        [/#if]

        [#list solution.Links?values as link]
            [#if link?is_hash]
                [#assign linkTarget = getLinkTarget(occurrence, link) ]

                [@cfDebug listMode linkTarget false /]

                [#if !linkTarget?has_content]
                    [#continue]
                [/#if]

                [#assign linkTargetCore = linkTarget.Core ]
                [#assign linkTargetConfiguration = linkTarget.Configuration ]
                [#assign linkTargetAttributes = linkTarget.State.Attributes ]

                [#switch linkTargetCore.Type]
                    [#case "external"]
                    [#case "contenthub"]
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
                                        getRegistryEndPoint("contentnode", occurrence) + " " +
                                        formatRelativePath(
                                            getRegistryPrefix("contentnode", occurrence) + productName,
                                            getOccurrenceBuildUnit(occurrence),
                                            getOccurrenceBuildReference(occurrence)) + " " +
                                        "   \"$\{tmpdir}\" || return $?",
                                    "  #",
                                    "  # Sync with the contentnode",
                                    "  copy_contentnode_file \"$\{tmpdir}/contentnode.zip\" " + 
                                            "\"" + linkTargetAttributes.ENGINE + "\" " +
                                            "\"" +    linkTargetAttributes.REPOSITORY + "\" " + 
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
