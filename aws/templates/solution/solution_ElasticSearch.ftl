[#-- ElasticSearch --]
[#if componentType == "elasticsearch" ||
        (componentType == "es")]
    [#assign es = component.ES!component.ElasticSearch]
    [#assign esId = formatElasticSearchId(
                        tier,
                        component)]
    [#switch solutionListMode]
        [#case "definition"]
            [#assign processorProfile = getProcessor(tier, component, "ElasticSearch")]
            [#assign storageProfile = getStorage(tier, component, "ElasticSearch")]
            [@checkIfResourcesCreated /]
            "${esId}":{
                "Type" : "AWS::Elasticsearch::Domain",
                "Properties" : {
                    "AccessPolicies" : {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Sid": "",
                                "Effect": "Allow",
                                "Principal": {
                                    "AWS": "*"
                                },
                                "Action": "es:*",
                                "Resource": "*"
                                [#assign esCIDRs =
                                            getUsageCIDRs(
                                                "es",
                                                es.IPAddressGroups![])]
                                [#list zones as zone]
                                    [#if getKey("eip", "mgmt", "nat", zone.Id, "ip")?has_content]
                                        [#assign esCIDRs +=
                                            [getKey("eip", "mgmt", "nat", zone.Id, "ip")]]
                                    [/#if]
                                [/#list]
                                [#list 1..20 as i]
                                    [#if getKey("eip", "mgmt", "nat", "external" + i)?has_content]
                                        [#assign esCIDRs +=
                                            [getKey("eip", "mgmt", "nat", "external", i)]]
                                    [/#if]
                                [/#list]
                                [#if esCIDRs?has_content]
                                    ,"Condition": {
                                        "IpAddress": {
                                            "aws:SourceIp": [
                                                [#list esCIDRs as cidrBlock]
                                                    "${cidrBlock}"
                                                    [#sep],[/#sep]
                                                [/#list]
                                            ]
                                        }
                                    }
                                [/#if]
                            }
                        ]
                    },
                    [#if es.AdvancedOptions??]
                        "AdvancedOptions" : {
                            [#list es.AdvancedOptions as option]
                                "${option.Id}" : "${option.Value}"
                                [#sep],[/#sep]
                            [/#list]
                        },
                    [/#if]
                    [#-- In order to permit updates to the security policy, don't name the domain. --]
                    [#-- Use tags in the console to find the right one --]
                    [#-- "DomainName" : "${productName}-${segmentId}-${tierId}-${componentId}", --]
                    [#if es.Version??]
                        "ElasticsearchVersion" : "${es.Version}",
                    [#else]
                        "ElasticsearchVersion" : "2.3",
                    [/#if]
                    [#if (storageProfile.Volumes["codeontap"])??]
                        [#assign volume = storageProfile.Volumes["codeontap"]]
                        "EBSOptions" : {
                            "EBSEnabled" : true,
                            [#if volume.Iops??]"Iops" : ${volume.Iops},[/#if]
                            "VolumeSize" : ${volume.Size},
                            [#if volume.Type??]
                                "VolumeType" : "${volume.Type}"
                            [#else]
                                "VolumeType" : "gp2"
                            [/#if]
                        },
                    [/#if]
                    "ElasticsearchClusterConfig" : {
                        [#if processorProfile.Master??]
                            [#assign master = processorProfile.Master]
                            "DedicatedMasterEnabled" : true,
                            "DedicatedMasterCount" : ${master.Count},
                            "DedicatedMasterType" : "${master.Processor}",
                        [#else]
                            "DedicatedMasterEnabled" : false,
                        [/#if]
                        "InstanceType" : "${processorProfile.Processor}",
                        "ZoneAwarenessEnabled" : ${multiAZ?string("true","false")},
                        [#if multiAZ]
                            "InstanceCount" : ${processorProfile.CountPerZone * zones?size}
                        [#else]
                            "InstanceCount" : ${processorProfile.CountPerZone}
                        [/#if]
                    },
                    [#if (es.Snapshot.Hour)??]
                        "SnapshotOptions" : {
                            "AutomatedSnapshotStartHour" : ${es.Snapshot.Hour}
                        },
                    [/#if]
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
                        { "Key" : "cot:component", "Value" : "${componentId}" }
                    ]
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output esId /]
            [@outputElasticSearchUrl esId /]
            [@outputElasticSearchArn esId /]
            [#break]

    [/#switch]
[/#if]