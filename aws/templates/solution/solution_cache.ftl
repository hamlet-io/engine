[#-- ElastiCache --]
[#if ((componentType == "elasticache") ||
        (componentType == "cache")) && 
        deploymentSubsetRequired("cache", true)]

    [#assign cache = component.Cache!component.ElastiCache]
    [#assign engine = cache.Engine]
        [#switch engine]
            [#case "memcached"]
                [#assign engineVersion =
                    cache.EngineVersion?has_content?then(
                        cache.EngineVersion,
                        "1.4.24"
                    )
                ]
                [#assign familyVersionIndex = engineVersion?last_index_of(".") - 1]
                [#assign family = "memcached" + engineVersion[0..familyVersionIndex]]
                [#break]

            [#case "redis"]
                [#assign engineVersion =
                    cache.EngineVersion?has_content?then(
                        cache.EngineVersion,
                        "2.8.24"
                    )
                ]
                [#assign familyVersionIndex = engineVersion?last_index_of(".") - 1]
                [#assign family = "redis" + engineVersion[0..familyVersionIndex]]
                [#break]
        [/#switch]

    [#assign cacheId = formatCacheId(
                        tier,
                        component)]
    [#assign cacheFullName = formatComponentFullName(tier, component) ]
    [#assign cacheSubnetGroupId = formatCacheSubnetGroupId(tier, component)]
    [#assign cacheParameterGroupId = formatCacheParameterGroupId(tier, component)]

    [#assign cacheSecurityGroupId = formatDependentSecurityGroupId(
                                        cacheId)]
    [#assign cacheSecurityGroupIngressId = formatDependentSecurityGroupIngressId(
                                            cacheSecurityGroupId, 
                                            ports[cache.Port].Port?c)]

    [#assign processorProfile = getProcessor(tier, component, "ElastiCache")]
    [#assign countPerZone = processorProfile.CountPerZone]
    [#assign awsZones = [] ]
    [#list zones as zone]
        [#list 1..countPerZone as i]
            [#assign awsZones += [zone.AWSZone] ]
        [/#list]
    [/#list]

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
        port=cache.Port
        cidr="0.0.0.0"
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
                "Port" : ports[cache.Port].Port,
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
            attributeIfContent("SnapshotRetentionLimit", cache.SnapshotRetentionLimit!"")
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