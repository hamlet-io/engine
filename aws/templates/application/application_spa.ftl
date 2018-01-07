[#if componentType = "spa"]

    [#list getOccurrences(component, deploymentUnit) as occurrence]
        [#assign containerId =
            occurrence.Container?has_content?then(
                occurrence.Container,
                getComponentId(component)                            
            ) ]
        [#assign context = 
            {
                "Id" : containerId,
                "Name" : containerId,
                "Instance" : occurrence.InstanceId,
                "Version" : occurrence.VersionId,
                "Environment" : 
                    {
                        "TEMPLATE_TIMESTAMP" : .now?iso_utc
                    } +
                    attributeIfContent("BUILD_REFERENCE", buildCommit!"") +
                    attributeIfContent("APP_REFERENCE", appReference!""),
                "Links" : {}
            }
        ]
    
        [#list occurrence.Links?values as link]
            [#if link?is_hash]
                [#assign targetComponent = getComponent(link.Tier, link.Component)]
                [#if targetComponent?has_content]
                    [#list getOccurrences(targetComponent) as targetOccurrence]
                        [#if (targetOccurrence.InstanceId == occurrence.InstanceId) &&
                                (targetOccurrence.VersionId == occurrence.VersionId)]
                            [#assign certificateObject = getCertificateObject(occurrence.Certificate, segmentId, segmentName) ]
                            [#assign hostName = getHostName(certificateObject, tier, component, occurrence) ]
                            [#assign dns = formatDomainName(hostName, certificateObject.Domain.Name) ]
                            [#switch getComponentType(targetComponent)]
                                [#case "alb"]
                                    [#assign context +=
                                        {
                                          "Links" :
                                              context.Links +
                                              {
                                                link.Name : {
                                                    "Url" : "https://" + dns
                                                }
                                            }
                                        }
                                    ]
                                    [#break]

                                [#case "apigateway"]
                                    [#assign apiId =
                                        formatAPIGatewayId(
                                            link.Tier,
                                            link.Component,
                                            targetOccurrence)]
                                    [#-- assign context +=
                                        {
                                          "Links" :
                                              context.Links +
                                              {
                                                link.Name : {
                                                    "Url" :
                                                        "https://" +
                                                        (targetOccurrence.CertificateIsConfigured && targetOccurrence.Certificate.Enabled)?then(
                                                            dns,
                                                            formatDomainName(
                                                                getExistingReference(apiId),
                                                                "execute-api",
                                                                regionId,
                                                                "amazonaws.com")
                                                        )
                                                }
                                            }
                                        }
                                    --]
                                    [#break]
                            [/#switch]
                            [#break]
                        [/#if]
                    [/#list]
                [/#if]
            [/#if]
        [/#list]

        [#-- Add in container specifics including override of defaults --]
        [#assign containerListMode = "model"]
        [#assign containerId = formatContainerFragmentId(occurrence, context)]
        [#include containerList?ensure_starts_with("/")]

        [#if deploymentSubsetRequired("config", false)]
            [@cfConfig
                mode=listMode
                content=context.Environment
            /]
        [/#if]
        [#if deploymentSubsetRequired("prologue", false)]
            [@cfScript
                mode=listMode
                content=
                  [
                      "function get_spa_file() {",
                      "  #",
                      "  # Temporary dir for the spa file",
                      "  mkdir -p ./temp_spa",
                      "  #",
                      "  # Fetch the spa zip file",
                      "  copyFilesFromBucket" + " " +
                          regionId + " " + 
                          getRegistryEndPoint("spa") + " " +
                          formatRelativePath(
                              getRegistryPrefix("spa") + productName,
                              buildDeploymentUnit,
                              buildCommit) + " " +
                      "   ./temp_spa || return $?",
                      "  #",
                      "  # Sync with the operations bucket",
                      "  copy_spa_file ./temp_spa/spa.zip",
                      "}",
                      "#",
                      "get_spa_file"
                  ]
            /]
        [/#if]
    [/#list]
[/#if]
