[#-- ElastiCache --]
[#if (componentType == "elasticache") ||
        (componentType == "cache")]
    [#assign cache = component.Cache!component.ElastiCache]
    [#assign engine = cache.Engine]
    [#assign cacheId = formatComponentResourceId(
                        "cache",
                        tier,
                        component)]
    [#assign cacheFullName = componentFullName]

    [@createComponentSecurityGroup solutionListMode tier component /]

    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            [#switch engine]
                [#case "memcached"]
                    [#if cache.EngineVersion??]
                        [#assign engineVersion = cache.EngineVersion]
                    [#else]
                        [#assign engineVersion = "1.4.24"]
                    [/#if]
                    [#assign familyVersionIndex = engineVersion?last_index_of(".") - 1]
                    [#assign family = "memcached" + engineVersion[0..familyVersionIndex]]
                    [#break]

                [#case "redis"]
                    [#if cache.EngineVersion??]
                        [#assign engineVersion = cache.EngineVersion]
                    [#else]
                        [#assign engineVersion = "2.8.24"]
                    [/#if]
                    [#assign familyVersionIndex = engineVersion?last_index_of(".") - 1]
                    [#assign family = "redis" + engineVersion[0..familyVersionIndex]]
                    [#break]
            [/#switch]
            "${formatId("securityGroupIngress", componentIdStem)}" : {
                "Type" : "AWS::EC2::SecurityGroupIngress",
                "Properties" : {
                    "GroupId": {"Ref" : "${formatComponentSecurityGroupId(
                                            tier,
                                            component)}"},
                    "IpProtocol": "${ports[cache.Port].IPProtocol}",
                    "FromPort": "${ports[cache.Port].Port?c}",
                    "ToPort": "${ports[cache.Port].Port?c}",
                    "CidrIp": "0.0.0.0/0"
                }
            },
            "${formatId("cacheSubnetGroup", componentIdStem)}" : {
                "Type" : "AWS::ElastiCache::SubnetGroup",
                "Properties" : {
                    "Description" : "${cacheFullName}",
                    "SubnetIds" : [
                        [#list zones as zone]
                            "${getKey("subnet", tierId, zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                        [/#list]
                    ]
                }
            },
            "${formatId("cacheParameterGroup", componentIdStem)}" : {
                "Type" : "AWS::ElastiCache::ParameterGroup",
                "Properties" : {
                    "CacheParameterGroupFamily" : "${family}",
                    "Description" : "${cacheFullName}",
                    "Properties" : {
                    }
                }
            },
            [#assign processorProfile = getProcessor(tier, component, "ElastiCache")]
            "${cacheId}":{
                "Type":"AWS::ElastiCache::CacheCluster",
                "Properties":{
                    "Engine": "${cache.Engine}",
                    "EngineVersion": "${engineVersion}",
                    "CacheNodeType" : "${processorProfile.Processor}",
                    "Port" : ${ports[cache.Port].Port?c},
                    "CacheParameterGroupName": { "Ref" : "${formatId("cacheParameterGroup", componentIdStem)}" },
                    "CacheSubnetGroupName": { "Ref" : "${formatId("cacheSubnetGroup", componentIdStem)}" },
                    [#if multiAZ]
                        "AZMode": "cross-az",
                        "PreferredAvailabilityZones" : [
                            [#assign countPerZone = processorProfile.CountPerZone]
                            [#assign cacheZoneCount = 0]
                            [#list zones as zone]
                                [#list 1..countPerZone as i]
                                    [#if cacheZoneCount > 0],[/#if]
                                    "${zone.AWSZone}"
                                    [#assign cacheZoneCount += 1]
                                [/#list]
                        [/#list]
                        ],
                        "NumCacheNodes" : "${processorProfile.CountPerZone * zones?size}",
                    [#else]
                        "AZMode": "single-az",
                        "PreferredAvailabilityZone" : "${zones[0].AWSZone}",
                        "NumCacheNodes" : "${processorProfile.CountPerZone}",
                    [/#if]
                    [#if (cache.SnapshotRetentionLimit)??]
                        "SnapshotRetentionLimit" : ${cache.SnapshotRetentionLimit}
                    [/#if]
                    "VpcSecurityGroupIds":[
                        { "Ref" : "${formatComponentSecurityGroupId(
                                        tier,
                                        component)}" }
                    ],
                    "Tags" : [
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" },
                        { "Key" : "cot:tier", "Value" : "${tierId}" },
                        { "Key" : "cot:component", "Value" : "${componentId}" },
                        { "Key" : "Name", "Value" : "${cacheFullName}" }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            [#switch engine]
                [#case "memcached"]
                    "${formatId(cacheId, "dns")}" : {
                       "Value" : { "Fn::GetAtt" : ["${cacheId}", "ConfigurationEndpoint.Address"] }
                    },
                    "${formatId(cacheId, "port")}" : {
                        "Value" : { "Fn::GetAtt" : ["${cacheId}", "ConfigurationEndpoint.Port"] }
                    }
                [#break]
                [#case "redis"]
                    [#break]
            [/#switch]
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]