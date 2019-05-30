[#-- Cache --]

[#if componentType == CACHE_COMPONENT_TYPE ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#assign networkLink = getOccurrenceNetwork(occurrence).Link!{} ]

        [#assign networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]
        [#if ! networkLinkTarget?has_content ]
            [@cfException listMode "Network could not be found" networkLink /]
            [#break]
        [/#if]

        [#assign networkConfiguration = networkLinkTarget.Configuration.Solution]
        [#assign networkResources = networkLinkTarget.State.Resources ]

        [#assign vpcId = networkResources["vpc"].Id ]

        [#assign engine = solution.Engine]
        [#switch engine]
            [#case "memcached"]
                [#assign engineVersion =
                    valueIfContent(
                        solution.EngineVersion!"",
                        solution.EngineVersion!"",
                        "1.4.24"
                    )
                ]
                [#assign familyVersionIndex = engineVersion?last_index_of(".") - 1]
                [#assign family = "memcached" + engineVersion[0..familyVersionIndex]]
                [#assign port = solution.Port!"memcached" ]
                [#if (ports[port].Port)?has_content]
                    [#assign port = ports[port].Port ]
                [#else]
                    [@cfException listMode "Unknown Port" port /]
                [/#if]
                [#break]

            [#case "redis"]
                [#assign engineVersion =
                    valueIfContent(
                        solution.EngineVersion!"",
                        solution.EngineVersion!"",
                        "2.8.24"
                    )
                ]
                [#assign familyVersionIndex = engineVersion?last_index_of(".") - 1]
                [#assign family = "redis" + engineVersion[0..familyVersionIndex]]
                [#assign port = solution.Port!"redis" ]
                [#if (ports[port].Port)?has_content]
                    [#assign port = ports[port].Port ]
                [#else]
                    [@cfException listMode "Unknown Port" port /]
                [/#if]
                [#break]

            [#default]
                [@cfPreconditionFailed listMode "solution_cache" occurrence "Unsupported engine provided" /]
                [#assign engineVersion = "unknown" ]
                [#assign family = "unknown" ]
                [#assign port = "unknown" ]
        [/#switch]

        [#assign cacheId = resources["cache"].Id ]
        [#assign cacheFullName = resources["cache"].Name ]
        [#assign cacheSubnetGroupId = resources["subnetGroup"].Id ]
        [#assign cacheParameterGroupId = resources["parameterGroup"].Id ]
        [#assign cacheSecurityGroupId = resources["sg"].Id ]

        [#assign cacheSecurityGroupIngressId = formatDependentSecurityGroupIngressId(
                                                cacheSecurityGroupId,
                                                port)]

        [#assign processorProfile = getProcessor(occurrence, "ElastiCache")]
        [#assign countPerZone = processorProfile.CountPerZone]
        [#assign awsZones = [] ]
        [#list zones as zone]
            [#list 1..countPerZone as i]
                [#assign awsZones += [zone.AWSZone] ]
            [/#list]
        [/#list]

        [#assign hibernate = solution.Hibernate.Enabled  &&
            (getExistingReference(cacheId)?has_content) ]

        [#if deploymentSubsetRequired("cache", true)]

            [@createDependentSecurityGroup
                mode=listMode
                resourceId=cacheId
                resourceName=cacheFullName
                occurrence=occurrence
                vpcId=vpcId
            /]

            [@createSecurityGroupIngress
                mode=listMode
                id=cacheSecurityGroupIngressId
                port=port
                cidr="0.0.0.0/0"
                groupId=cacheSecurityGroupId
            /]

            [@cfResource
                mode=listMode
                id=cacheSubnetGroupId
                type="AWS::ElastiCache::SubnetGroup"
                properties=
                    {
                        "Description" : cacheFullName,
                        "SubnetIds" : getSubnets(core.Tier, networkResources)
                    }
                outputs={}
            /]

            [@cfResource
                mode=listMode
                id=cacheParameterGroupId
                type="AWS::ElastiCache::ParameterGroup"
                properties=
                    {
                        "CacheParameterGroupFamily" : family,
                        "Description" : cacheFullName,
                        "Properties" : {
                        }
                    }
                outputs={}
            /]

            [#if !hibernate]

                [#list solution.Alerts?values as alert ]

                    [#assign monitoredResources = getMonitoredResources(resources, alert.Resource)]
                    [#list monitoredResources as name,monitoredResource ]

                        [@cfDebug listMode monitoredResource false /]

                        [#switch alert.Comparison ]
                            [#case "Threshold" ]
                                [@createCountAlarm
                                    mode=listMode
                                    id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                                    severity=alert.Severity
                                    resourceName=core.FullName
                                    alertName=alert.Name
                                    actions=[
                                        getReference(formatSegmentSNSTopicId())
                                    ]
                                    metric=getMetricName(alert.Metric, monitoredResource.Type, core.ShortFullName)
                                    namespace=getResourceMetricNamespace(monitoredResource.Type)
                                    description=alert.Description!alert.Name
                                    threshold=alert.Threshold
                                    statistic=alert.Statistic
                                    evaluationPeriods=alert.Periods
                                    period=alert.Time
                                    operator=alert.Operator
                                    reportOK=alert.ReportOk
                                    missingData=alert.MissingData
                                    dimensions=getResourceMetricDimensions(monitoredResource, resources)
                                    dependencies=monitoredResource.Id
                                /]
                            [#break]
                        [/#switch]
                    [/#list]
                [/#list]

                [@cfResource
                    mode=listMode
                    id=cacheId
                    type="AWS::ElastiCache::CacheCluster"
                    properties=
                        {
                            "Engine": engine,
                            "EngineVersion": engineVersion,
                            "CacheNodeType" : processorProfile.Processor,
                            "Port" : port,
                            "CacheParameterGroupName": getReference(cacheParameterGroupId),
                            "CacheSubnetGroupName": getReference(cacheSubnetGroupId),
                            "VpcSecurityGroupIds":[getReference(cacheSecurityGroupId)]
                        } +
                        multiAZ?then(
                            {
                                "AZMode": "cross-az",
                                "PreferredAvailabilityZones" : awsZones,
                                "NumCacheNodes" : processorProfile.CountPerZone * zones?size
                            },
                            {
                                "AZMode": "single-az",
                                "PreferredAvailabilityZone" : awsZones[0],
                                "NumCacheNodes" : processorProfile.CountPerZone
                            }
                        ) +
                        attributeIfContent("SnapshotRetentionLimit", solution.Backup.RetentionPeriod)
                    tags=
                        getCfTemplateCoreTags(
                            cacheFullName,
                            core.Tier,
                            core.Component)
                    outputs=engine?switch(
                        "memcached", MEMCACHED_OUTPUT_MAPPINGS,
                        "redis", REDIS_OUTPUT_MAPPINGS,
                        {})
                /]
            [/#if]
        [/#if]
    [/#list]
[/#if]