[#ftl]
[#include "setContext.ftl"]

[#-- Domains --]
[#assign segmentDomain = getKey("domainXsegmentXdomain")]
[#assign segmentDomainQualifier = getKey("domainXsegmentXqualifier")]
[#assign certificateId = getKey("domainXsegmentXcertificate")]

[#-- Solution --]
[#assign solnMultiAZ = solutionObject.MultiAZ!environmentObject.MultiAZ!false]
[#assign vpc = getKey("vpcXsegmentXvpc")]
[#assign securityGroupNAT = getKey("securityGroupXmgmtXnat")!"none"]

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
    "tgX${tier.Id}X${component.Id}X${source.Port?c}X${name}" : {
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
                { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}-${source.Port?c}-${name}" }
            ],
            "VpcId": "${vpc}"
        }
    }
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
