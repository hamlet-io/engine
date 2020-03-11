[#ftl]
[#macro aws_cache_cf_generationcontract_solution occurrence ]
    [@addDefaultGenerationContract subsets="template" /]
[/#macro]

[#macro aws_cache_cf_setup_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]

    [#local networkLink = getOccurrenceNetwork(occurrence).Link!{} ]

    [#local networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]
    [#if ! networkLinkTarget?has_content ]
        [@fatal message="Network could not be found" context=networkLink /]
        [#return]
    [/#if]

    [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
    [#local networkResources = networkLinkTarget.State.Resources ]

    [#local vpcId = networkResources["vpc"].Id ]

    [#local engine = solution.Engine]
    [#switch engine]
        [#case "memcached"]
            [#local engineVersion =
                valueIfContent(
                    solution.EngineVersion!"",
                    solution.EngineVersion!"",
                    "1.4.24"
                )
            ]
            [#local familyVersionIndex = engineVersion?last_index_of(".") - 1]
            [#local family = "memcached" + engineVersion[0..familyVersionIndex]]
            [#local port = solution.Port!"memcached" ]
            [#if (ports[port].Port)?has_content]
                [#local port = ports[port].Port ]
            [#else]
                [@fatal message="Unknown Port" context=port /]
            [/#if]
            [#break]

        [#case "redis"]
            [#local engineVersion =
                valueIfContent(
                    solution.EngineVersion!"",
                    solution.EngineVersion!"",
                    "2.8.24"
                )
            ]
            [#local familyVersionIndex = engineVersion?last_index_of(".") - 1]
            [#local family = "redis" + engineVersion[0..familyVersionIndex]]
            [#local port = solution.Port!"redis" ]
            [#if (ports[port].Port)?has_content]
                [#local port = ports[port].Port ]
            [#else]
                [@fatal message="Unknown Port" context=port /]
            [/#if]
            [#break]

        [#default]
            [@precondition
                function="solution_cache"
                context=occurrence
                detail="Unsupported engine provided"
            /]
            [#local engineVersion = "unknown" ]
            [#local family = "unknown" ]
            [#local port = "unknown" ]
    [/#switch]

    [#local cacheId = resources["cache"].Id ]
    [#local cacheFullName = resources["cache"].Name ]
    [#local cacheSubnetGroupId = resources["subnetGroup"].Id ]
    [#local cacheParameterGroupId = resources["parameterGroup"].Id ]
    [#local cacheSecurityGroupId = resources["sg"].Id ]

    [#local cacheSecurityGroupIngressId = formatDependentSecurityGroupIngressId(
                                            cacheSecurityGroupId,
                                            port)]

    [#local processorProfile = getProcessor(occurrence, "cache")]
    [#local countPerZone = processorProfile.CountPerZone]
    [#local awsZones = [] ]
    [#list zones as zone]
        [#list 1..countPerZone as i]
            [#local awsZones += [zone.AWSZone] ]
        [/#list]
    [/#list]

    [#local hibernate = solution.Hibernate.Enabled && isOccurrenceDeployed(occurrence)]

    [#if deploymentSubsetRequired("cache", true)]

        [@createDependentSecurityGroup
            resourceId=cacheId
            resourceName=cacheFullName
            occurrence=occurrence
            vpcId=vpcId
        /]

        [@createSecurityGroupIngress
            id=cacheSecurityGroupIngressId
            port=port
            cidr="0.0.0.0/0"
            groupId=cacheSecurityGroupId
        /]

        [@cfResource
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

                [#local monitoredResources = getMonitoredResources(core.Id, resources, alert.Resource)]
                [#list monitoredResources as name,monitoredResource ]

                    [@debug message="Monitored resource" context=monitoredResource enabled=false /]

                    [#switch alert.Comparison ]
                        [#case "Threshold" ]
                            [@createAlarm
                                id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                                severity=alert.Severity
                                resourceName=core.FullName
                                alertName=alert.Name
                                actions=getCWAlertActions(occurrence, solution.Profiles.Alert, alert.Severity )
                                metric=getMetricName(alert.Metric, monitoredResource.Type, core.ShortFullName)
                                namespace=getResourceMetricNamespace(monitoredResource.Type, alert.Namespace)
                                description=alert.Description!alert.Name
                                threshold=alert.Threshold
                                statistic=alert.Statistic
                                evaluationPeriods=alert.Periods
                                period=alert.Time
                                operator=alert.Operator
                                reportOK=alert.ReportOk
                                unit=alert.Unit
                                missingData=alert.MissingData
                                dimensions=getResourceMetricDimensions(monitoredResource, resources)
                            /]
                        [#break]
                    [/#switch]
                [/#list]
            [/#list]

            [@cfResource
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
                tags=getOccurrenceCoreTags(occurrence, cacheFullName)
                outputs=engine?switch(
                    "memcached", MEMCACHED_OUTPUT_MAPPINGS,
                    "redis", REDIS_OUTPUT_MAPPINGS,
                    {})
            /]
        [/#if]
    [/#if]
[/#macro]
