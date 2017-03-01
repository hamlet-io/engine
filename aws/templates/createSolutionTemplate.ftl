[#ftl]
[#include "setContext.ftl"]

[#macro createBlockDevices storageProfile]
    [#if (storageProfile.Volumes)?? ]
        "BlockDeviceMappings" : [
            [#list storageProfile.Volumes?values as volume]
                [#if volume?is_hash]
                    {
                        "DeviceName" : "${volume.Device}",
                        "Ebs" : {
                            "DeleteOnTermination" : true,
                            "Encrypted" : false,
                            "VolumeSize" : "${volume.Size}",
                            "VolumeType" : "gp2"
                        }
                    },
                [/#if]
            [/#list]
            {
                "DeviceName" : "/dev/sdc",
                "VirtualName" : "ephemeral0"
            },
            {
                "DeviceName" : "/dev/sdt",
                "VirtualName" : "ephemeral1"
            }
        ],
    [/#if]
[/#macro]

[#macro createTargetGroup tier component source destination name]
    "${formatId("tg", tier.Id, component.Id, source.Port?c, name)}" : {
        "Type" : "AWS::ElasticLoadBalancingV2::TargetGroup",
        "Properties" : {
            "HealthCheckPort" : "${(destination.HealthCheck.Port)!"traffic-port"}",
            "HealthCheckProtocol" : "${(destination.HealthCheck.Protocol)!destination.Protocol}",
            "HealthCheckPath" : "${destination.HealthCheck.Path}",
            "HealthCheckIntervalSeconds" : ${destination.HealthCheck.Interval},
            "HealthCheckTimeoutSeconds" : ${destination.HealthCheck.Timeout},
            "HealthyThresholdCount" : ${destination.HealthCheck.HealthyThreshold},
            "UnhealthyThresholdCount" : ${destination.HealthCheck.UnhealthyThreshold},
            [#if (destination.HealthCheck.SuccessCodes)?? ]
                "Matcher" : { "HttpCode" : "${destination.HealthCheck.SuccessCodes}" },
            [/#if]
            "Port" : ${destination.Port?c},
            "Protocol" : "${destination.Protocol}",
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
                { "Key" : "Name", "Value" : "${formatName(productName, segmentName, tier.Name, component.Name, source.Port?c, name)}" }
            ],
            "VpcId": "${vpc}"
        }
    }
[/#macro]

[#macro securityGroup tier component]
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            "${formatId("securityGroup", tier.Id, component.Id)}" : {
                "Type" : "AWS::EC2::SecurityGroup",
                "Properties" : {
                    "GroupDescription": "Security Group for ${formatName(tier.Name, component.Name)}",
                    "VpcId": "${vpc}",
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
            "${formatId("securityGroup", tier.Id, component.Id)}" : {
                "Value" : { "Ref" : "${formatId("securityGroup", tier.Id, component.Id)}" }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#macro]

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    [#assign compositeList=solutionList]
    "Resources" : {
        [#assign solutionListMode="definition"]
        [#include "componentList.ftl"]
    },
    
    "Outputs" : {
        [#assign solutionListMode="outputs"]
        [#include "componentList.ftl"]
    }
}
