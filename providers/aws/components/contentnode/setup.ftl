[#ftl]
[#macro aws_contentnode_cf_generationcontract_application occurrence ]
    [@addDefaultGenerationContract subsets="prologue" /]
[/#macro]

[#macro aws_contentnode_cf_setup_application occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources]

    [#local contentNodeId = resources["contentnode"].Id ]
    [#local pathObject = getContentPath(occurrence) ]

    [#if ! (solution.Links?has_content)]
        [@precondition
            function="contentnode"
            context=occurrence
            detail="No content hub link configured"
        /]
    [/#if]

    [#list solution.Links?values as link]
        [#if link?is_hash]
            [#local linkTarget = getLinkTarget(occurrence, link) ]

            [@debug message="Link Target" context=linkTarget enabled=false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]

            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetConfiguration = linkTarget.Configuration ]
            [#local linkTargetAttributes = linkTarget.State.Attributes ]

            [#switch linkTargetCore.Type]
                [#case "external"]
                [#case "contenthub"]
                    [#if deploymentSubsetRequired("prologue", false)]
                        [@addToDefaultBashScriptOutput
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
                                        getRegistryPrefix("contentnode", occurrence),
                                        productName,
                                        getOccurrenceBuildScopeExtension(occurrence),
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
                                        "\"" +    linkTargetAttributes.BRANCH + "\" " +
                                        "\"replace\" || return $? ",
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
[/#macro]
