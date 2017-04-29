[#-- ElastiCache --]
[#if componentType == "elasticache"]
    [@securityGroup solutionListMode tier component /]
    [#assign cache = component.ElastiCache]
    [#assign engine = cache.Engine]
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
            "${formatId("securityGroupIngress", tier.Id, component.Id)}" : {
                "Type" : "AWS::EC2::SecurityGroupIngress",
                "Properties" : {
                    "GroupId": {"Ref" : "${formatId("securityGroup", tier.Id, component.Id)}"},
                    "IpProtocol": "${ports[cache.Port].IPProtocol}",
                    "FromPort": "${ports[cache.Port].Port?c}",
                    "ToPort": "${ports[cache.Port].Port?c}",
                    "CidrIp": "0.0.0.0/0"
                }
            },
            "${formatId("cacheSubnetGroup", tier.Id, component.Id)}" : {
                "Type" : "AWS::ElastiCache::SubnetGroup",
                "Properties" : {
                    "Description" : "${formatName(productName, segmentName, tier.Name, component.Name)}",
                    "SubnetIds" : [
                        [#list zones as zone]
                            "${getKey("subnet", tier.Id, zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                        [/#list]
                    ]
                }
            },
            "${formatId("cacheParameterGroup", tier.Id, component.Id)}" : {
                "Type" : "AWS::ElastiCache::ParameterGroup",
                "Properties" : {
                    "CacheParameterGroupFamily" : "${family}",
                    "Description" : "Parameter group for ${formatName(tier.Id, component.Id)}",
                    "Properties" : {
                    }
                }
            },
            [#assign processorProfile = getProcessor(tier, component, "ElastiCache")]
            "${formatId("cache", tier.Id, component.Id)}":{
                "Type":"AWS::ElastiCache::CacheCluster",
                "Properties":{
                    "Engine": "${cache.Engine}",
                    "EngineVersion": "${engineVersion}",
                    "CacheNodeType" : "${processorProfile.Processor}",
                    "Port" : ${ports[cache.Port].Port?c},
                    "CacheParameterGroupName": { "Ref" : "${formatId("cacheParameterGroup", tier.Id, component.Id)}" },
                    "CacheSubnetGroupName": { "Ref" : "${formatId("cacheSubnetGroup", tier.Id, component.Id)}" },
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
                        { "Ref" : "${formatId("securityGroup", tier.Id, component.Id)}" }
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
                        { "Key" : "cot:tier", "Value" : "${tier.Id}" },
                        { "Key" : "cot:component", "Value" : "${component.Id}" },
                        { "Key" : "Name", "Value" : "${formatName(productName, segmentName, tier.Name, component.Name)}" }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            [#switch engine]
                [#case "memcached"]
                    "${formatId("cache", tier.Id, component.Id, "dns")}" : {
                       "Value" : { "Fn::GetAtt" : ["${formatId("cache", tier.Id, component.Id)}", "ConfigurationEndpoint.Address"] }
                    },
                    "${formatId("cache", tier.Id, component.Id, "port")}" : {
                        "Value" : { "Fn::GetAtt" : ["${formatId("cache", tier.Id, component.Id)}", "ConfigurationEndpoint.Port"] }
                    }
                [#break]
                [#case "redis"]
                    [#break]
            [/#switch]
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]