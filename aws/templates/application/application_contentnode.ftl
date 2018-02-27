[#if componentType = "contentnode"]

    [#list getOccurrences(component, deploymentUnit) as occurrence]

        [#assign contentNodeId = formatContentHubNodeId(tier, component, occurrence) ]
        [#assign pathObject = getPathObject(occurrence.Path, segmentId, segmentName) ]

        [#if ! (occurrence.Links?has_content)]
            [@cfPreconditionFailed listMode "contentnode" occurrence "No content hub link configured" /]
            [#break]
        [/#if]

        [#list occurrence.Links?values as link]
            [#if link?is_hash]
                [#assign linkTarget = getLinkTarget(occurrence, link) ]
                [#assign linkInformation = getLinkTargetInformation(linkTarget) ]
                [#switch linkTarget.Type!""][#list occurrence.Links?values as link]
                    [#case "contenthub"]
                        [#if linkInformation.Engine == "git" ]
                            [#assign branch = linkInformation.branch!""]
                        [/#if]
                        
                        [#if deploymentSubsetRequired("prologue", false)]
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
                                                    linkInformation.Attributes.Engine + " " +
                                                    linkInformation.Attributes.URL + " " + 
                                                    linkInformation.Attributes.Prefix + " " +
                                                    pathObject.Path + " " +
                                                    branch,
                                        "}",
                                        "#",
                                        "get_contentnode_file"
                                    ]
                                /]
                            [/#if]
                        [/#if]
                    [#break]
                [/#switch]     
            [/#if]
        [/#list]
    [/#list]
[/#if]
