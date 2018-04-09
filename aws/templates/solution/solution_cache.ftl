[#-- Cache --]

[#if componentType == CACHE_COMPONENT_TYPE ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]
        [#assign resources = occurrence.State.Resources ]

        [#assign engine = configuration.Engine]
        [#switch engine]
            [#case "memcached"]
                [#assign engineVersion =
                    valueIfContent(
                        configuration.EngineVersion!"",
                        configuration.EngineVersion!"",
                        "1.4.24"
                    )
                ]
                [#assign familyVersionIndex = engineVersion?last_index_of(".") - 1]
                [#assign family = "memcached" + engineVersion[0..familyVersionIndex]]
                [#assign port = configuration.Port!"memcached" ]
                [#if (ports[port].Port)?has_content]
                    [#assign port = ports[port].Port ]
                [#else]
                    [@cfException listMode "Unknown Port" port /]
                [/#if]                
                [#break]

            [#case "redis"]
                [#assign engineVersion =
                    valueIfContent(
                        configuration.EngineVersion!"",
                        configuration.EngineVersion!"",
                        "2.8.24"
                    )
                ]
                [#assign familyVersionIndex = engineVersion?last_index_of(".") - 1]
                [#assign family = "redis" + engineVersion[0..familyVersionIndex]]
                [#assign port = configuration.Port!"redis" ]
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

        [#assign processorProfile = getProcessor(tier, component, "ElastiCache")]
        [#assign countPerZone = processorProfile.CountPerZone]
        [#assign awsZones = [] ]
        [#list zones as zone]
            [#list 1..countPerZone as i]
                [#assign awsZones += [zone.AWSZone] ]
            [/#list]
        [/#list]

        [#if deploymentSubsetRequired("cache", true)]
            [@createDependentSecurityGroup
                mode=listMode
                tier=tier
                component=component
                resourceId=cacheId
                resourceName=cacheFullName
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
                        "SubnetIds" : getSubnets(tier)
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
                    attributeIfContent("SnapshotRetentionLimit", configuration.Backup.RetentionPeriod)
                tags=
                    getCfTemplateCoreTags(
                        cacheFullName,
                        tier,
                        component)
                outputs=engine?switch(
                    "memcached", MEMCACHED_OUTPUT_MAPPINGS,
                    "redis", REDIS_OUTPUT_MAPPINGS,
                    {})
            /]
        [/#if]
    [/#list]
[/#if]