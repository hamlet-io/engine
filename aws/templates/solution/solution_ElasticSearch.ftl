[#-- ElasticSearch --]
[#if componentType == "elasticsearch" ||
        (componentType == "es")]
    [#assign es = component.ES!component.ElasticSearch]
    [#assign esId = formatElasticSearchId(
                        tier,
                        component)]

    [#assign processorProfile = getProcessor(tier, component, "ElasticSearch")]
    [#assign master = processorProfile.Master!{}]

    [#assign storageProfile = getStorage(tier, component, "ElasticSearch")]
    [#assign volume = (storageProfile.Volumes["codeontap"])!{}]

    [#assign esCIDRs =
                getUsageCIDRs(
                    "es",
                    es.IPAddressGroups![])]
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
    [#list es.AdvancedOptions as option]
        [#assign esAdvancedOptions +=
            {
                option.Id : option.Value
            }
        ]
    [/#list]

    [#-- In order to permit updates to the security policy, don't name the domain. --]
    [#-- Use tags in the console to find the right one --]
    [#-- "DomainName" : "${productName}-${segmentId}-${tierId}-${componentId}", --]


    [@cfTemplate
        mode=solutionListMode
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
                            esCIDRs?has_content?then(
                                {
                                    "IpAddress": {
                                        "aws:SourceIp": esCIDRs
                                    }
                                },
                                {}
                            )
                        )
                    ),
                "ElasticsearchVersion" :
                    es.Version?has_content?then(
                        es.Version,
                        "2.3"
                    ),
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
            esAdvancedOptions?has_content?then(
                {
                    "AdvancedOptions" : esAdvancedOptions
                },
                {}
            ) +
            (es.Snapshot.Hour)?has_content?then(
                {
                    "SnapshotOptions" : {
                        "AutomatedSnapshotStartHour" : es.Snapshot.Hour
                    }
                },
                {}
            ) +
            volume?has_content?then(
                {
                    "EBSOptions" :
                        {
                            "EBSEnabled" : true,
                            "VolumeSize" : volume.Size,
                            "VolumeType" :
                                volume.Type?has_content?then(
                                    volume.Type,
                                    "gp2"
                                )
                        } +
                        volume.Iops?has_content?then(
                            {
                                "Iops" : volume.Iops
                            },
                            {}
                        )
                },
                {}
            )
        tags=
            getCfTemplateCoreTags(
                "",
                tier,
                component)
        outputs=ES_OUTPUT_MAPPINGS
    /]
[/#if]