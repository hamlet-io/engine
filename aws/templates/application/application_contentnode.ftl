[#if componentType = "contentnode"]

    [#list requiredOccurrences(
            getOccurrences(component, tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]

        [#assign contentNodeId = formatContentHubNodeId(tier, component, occurrence) ]
        [#assign pathObject = getPathObject(configuration.Path, segmentId, segmentName) ]

        [#if ! (occurrence.Links?has_content)]
            [@cfPreconditionFailed listMode "contentnode" occurrence "No content hub link configured" /]
            [#break]
        [/#if]

        [#list occurrence.Links?values as link]
            [#if link?is_hash]
                [#assign linkTarget = getLinkTarget(occurrence, link) ]
                [#assign linkInformation = getLinkTargetInformation(linkTarget) ]
                [#switch linkTarget.Type!""]
                    [#case "contenthub"]
                        [#if linkInformation.Engine == "git" ]
                            [#assign branch = linkInformation.branch!""]
                            [#assign url = linkInformation.url!""]
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
                    [#break]
                [/#switch]     
            [/#if]
        [/#list]
    [/#list]
[/#if]
