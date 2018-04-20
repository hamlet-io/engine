[#-- ElasticSearch --]

[#if (componentType == ES_COMPONENT_TYPE || componentType == "elasticsearch" || componentType == "es") ]

    [#list requiredOccurrences(
        getOccurrences(tier, component),
        deploymentUnit) as occurrence]
        
        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign solution = occurrence.Configuration.Solution]
        [#assign resources = occurrence.State.Resources]

        [#assign esId = resources["es"].Id]

        [#assign processorProfile = getProcessor(tier, component, "ElasticSearch")]
        [#assign master = processorProfile.Master!{}]

        [#assign storageProfile = getStorage(tier, component, "ElasticSearch")]
        [#assign volume = (storageProfile.Volumes["codeontap"])!{}]
        [#assign esCIDRs =
                    getUsageCIDRs(
                        "es",
                        solution.IPAddressGroups)]
        [#list zones as zone]
            [#assign zoneIP =
                getExistingReference(
                    formatComponentEIPId("mgmt", "nat", zone),
                    IP_ADDRESS_ATTRIBUTE_TYPE
                )
            ]
            [#if zoneIP?has_content]
                [#assign esCIDRs += [zoneIP] ]
            [/#if]
        [/#list]
        [#list 1..20 as i]
            [#assign externalIP =
                getExistingReference(
                    formatComponentEIPId("mgmt", "nat", "external" + i)
                )
            ]
            [#if externalIP?has_content]
                [#assign esCIDRs += [externalIP] ]
            [/#if]
        [/#list]

        [#assign esAdvancedOptions = {} ]
        [#list solution.AdvancedOptions as option]
            [#assign esAdvancedOptions +=
                {
                    option.Id : option.Value
                }
            ]
        [/#list]

        [#-- In order to permit updates to the security policy, don't name the domain. --]
        [#-- Use tags in the console to find the right one --]
        [#-- "DomainName" : "${productName}-${segmentId}-${tierId}-${componentId}", --]

        [#if deploymentSubsetRequired("es", true)]
            [@cfResource
                mode=listMode
                id=esId
                type="AWS::Elasticsearch::Domain"
                properties=
                    {
                        "AccessPolicies" :
                            getPolicyDocumentContent(
                                getPolicyStatement(
                                    "es:*",
                                    "*",
                                    {
                                        "AWS": "*"
                                    },
                                    attributeIfContent(
                                        "IpAddress",
                                        esCIDRs,
                                        {
                                            "aws:SourceIp": esCIDRs
                                        })
                                )
                            ),
                        "ElasticsearchVersion" : solution.Version,
                        "ElasticsearchClusterConfig" :
                            {
                                "InstanceType" : processorProfile.Processor,
                                "ZoneAwarenessEnabled" : multiAZ,
                                "InstanceCount" :
                                    multiAZ?then(
                                        processorProfile.CountPerZone * zones?size,
                                        processorProfile.CountPerZone
                                    )
                            } +
                            master?has_content?then(
                                {
                                    "DedicatedMasterEnabled" : true,
                                    "DedicatedMasterCount" : master.Count,
                                    "DedicatedMasterType" : master.Processor
                                },
                                {
                                    "DedicatedMasterEnabled" : false
                                }
                            )
                    } + 
                    attributeIfContent("AdvancedOptions", esAdvancedOptions) +
                    attributeIfContent("SnapshotOptions", solution.Snapshot.Hour, solution.Snapshot.Hour) +
                    attributeIfContent(
                        "EBSOptions",
                        volume,
                        {
                            "EBSEnabled" : true,
                            "VolumeSize" : volume.Size,
                            "VolumeType" :
                                volume.Type?has_content?then(
                                    volume.Type,
                                    "gp2"
                                )
                        } +
                        attributeIfContent("Iops", volume.Iops!""))
                tags=
                    getCfTemplateCoreTags(
                        "",
                        tier,
                        component)
                outputs=ES_OUTPUT_MAPPINGS
            /]
        [/#if]
    [/#list]
[/#if]