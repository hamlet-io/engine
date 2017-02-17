[#ftl]
[#include "setContext.ftl"]

[#-- Domains --]
[#assign segmentDomain = getKey("domainXsegmentXdomain")]
[#assign segmentDomainQualifier = getKey("domainXsegmentXqualifier")]

[#-- Application --]
[#assign docker = appSettingsObject.Docker]
[#assign solnMultiAZ = solutionObject.MultiAZ!environmentObject.MultiAZ!false]
[#assign vpc = getKey("vpcXsegmentXvpc")]

[#if buildReference??]
    [#if buildReference?starts_with("{")]
        [#-- JSON format --]
        [#assign buildReferenceObject = buildReference?eval]
        [#if buildReferenceObject.commit?? ]
            [#assign buildCommit = buildReferenceObject.commit]
        [/#if]
        [#if buildReferenceObject.tag??]
            [#assign appReference = buildReferenceObject.tag]
        [/#if]
    [#else]
        [#-- Legacy format --]
        [#assign buildCommit = buildReference]
        [#assign buildSeparator = buildReference?index_of(" ")]
        [#if buildSeparator != -1]
            [#assign buildCommit = buildReference[0..(buildSeparator-1)]]
            [#assign appReference = buildReference[(buildSeparator+1)..]]
        [/#if]
    [/#if]
[/#if]

[#macro standardEnvironmentVariables]
    {
        "Name" : "TEMPLATE_TIMESTAMP",
        "Value" : "${.now?iso_utc}"
    },
    {
        "Name" : "ENVIRONMENT",
        "Value" : "${environmentName}"
    },
    {
        "Name" : "REQUEST_REFERENCE",
        "Value" : "${requestReference}"
    },
    {
        "Name" : "CONFIGURATION_REFERENCE",
        "Value" : "${configurationReference}"
    }
    [#if buildCommit??]
        ,{
            "Name" : "BUILD_REFERENCE",
            "Value" : "${buildCommit}"
        }
    [/#if]
    [#if appReference?? && (appReference != "")]
        ,{
            "Name" : "APP_REFERENCE",
            "Value" : "${appReference}"
        }
    [/#if]
[/#macro]

[#macro createTask tier component task]
    [#assign containerListMode = "policyCount"]
    [#assign policyCount = 0]
    [#list task.Containers?values as container]
        [#if container?is_hash]
            [#include containerList]
        [/#if]
    [/#list]
    [#if policyCount > 0]
        "roleX${tier.Id}X${component.Id}X${task.Id}" : {
            "Type" : "AWS::IAM::Role",
            "Properties" : {
                "AssumeRolePolicyDocument" : {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": { "Service": [ "ecs-tasks.amazonaws.com" ] },
                            "Action": [ "sts:AssumeRole" ]
                        }
                    ]
                },
                "Path": "/"
            }
        },
        [#assign containerListMode = "policy"]
        [#list task.Containers?values as container]
            [#if container?is_hash]
                [#include containerList]
            [/#if]
        [/#list]
    [/#if]
    "ecsTaskX${tier.Id}X${component.Id}X${task.Id}" : {
        "Type" : "AWS::ECS::TaskDefinition",
        "Properties" : {
            "ContainerDefinitions" : [
                [#assign containerListMode = "definition"]
                [#assign containerCount = 0]
                [#list task.Containers?values as container]
                    [#if container?is_hash]
                        [#assign dockerTag = ""]
                        [#if container.Version??]
                            [#assign dockerTag = ":" + container.Version]
                        [/#if]
                        [#if containerCount > 0],[/#if]
                        {
                            [#include containerList]
                            "Memory" : "${container.Memory?c}",
                            "Cpu" : "${container.Cpu?c}",
                            [#if container.Ports??]
                                "PortMappings" : [
                                    [#assign portCount = 0]
                                    [#list container.Ports?values as port]
                                        [#if port?is_hash]
                                            [#if portCount > 0],[/#if]
                                            {
                                                [#if port.Container??]
                                                    "ContainerPort" : ${ports[port.Container].Port?c},
                                                [#else]
                                                    "ContainerPort" : ${ports[port.Id].Port?c},
                                                [/#if]
                                                [#if port.DynamicHostPort?? && port.DynamicHostPort]
                                                    "HostPort" : 0
                                                [#else]
                                                    "HostPort" : ${ports[port.Id].Port?c}
                                                [/#if]
                                            }
                                            [#assign portCount += 1]
                                        [/#if]
                                    [/#list]
                                ],
                            [/#if]
                            "LogConfiguration" : {
                                [#if (docker.LocalLogging?? && (docker.LocalLogging == true)) || (container.LocalLogging?? && (container.LocalLogging == true))]
                                    "LogDriver" : "json-file"
                                [#else]
                                    "LogDriver" : "fluentd",
                                    "Options" : { "tag" : "docker.${productId}.${segmentId}.${tier.Id}.${component.Id}.${container.Id}"}
                                [/#if]
                            }
                        }
                        [#assign containerCount += 1]
                    [/#if]
                [/#list]
            ]
            [#assign containerListMode = "volumeCount"]
            [#assign volumeCount = 0]
            [#list task.Containers?values as container]
                [#if container?is_hash]
                    [#include containerList]
                [/#if]
            [/#list]
            [#if volumeCount > 0]
                ,"Volumes" : [
                    [#assign containerListMode = "volumes"]
                    [#assign volumeCount = 0]
                    [#list task.Containers?values as container]
                        [#if container?is_hash]
                            [#include containerList]
                        [/#if]
                    [/#list]
                ]
            [/#if]
            [#if policyCount > 0]
                ,"TaskRoleArn" : { "Fn::GetAtt" : ["roleX${tier.Id}X${component.Id}X${task.Id}","Arn"]}
            [/#if]
        }
    }
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
    [#assign compositeList=applicationList]
    "Resources" : {
        [#assign applicationListMode="definition"]
        [#include "componentList.ftl"]
    },

    "Outputs" : {
        [#assign applicationListMode="outputs"]
        [#include "componentList.ftl"]
    }
}

