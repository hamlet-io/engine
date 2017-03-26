[#ftl]
[#include "setContext.ftl"]

[#function getRegistryEndPoint type]
    [#return (appSettingsObject.Registries[type?lower_case].EndPoint)!(appSettingsObject[type?capitalize].Registry)!"unknown"]
[/#function]

[#function getRegistryPrefix type]
    [#return (appSettingsObject.Registries[type?lower_case].Prefix)!(appSettingsObject[type?capitalize].Prefix)!""]
[/#function]

[#if buildReference??]
    [#if buildReference?starts_with("{")]
        [#-- JSON format --]
        [#assign buildReferenceObject = buildReference?eval]
        [#if buildReferenceObject.commit?? ]
            [#assign buildCommit = buildReferenceObject.commit]
        [/#if]
        [#if buildReferenceObject.Commit?? ]
            [#assign buildCommit = buildReferenceObject.Commit]
        [/#if]
        [#if buildReferenceObject.tag??]
            [#assign appReference = buildReferenceObject.tag]
        [/#if]
        [#if buildReferenceObject.Tag??]
            [#assign appReference = buildReferenceObject.Tag]
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

[#macro environmentVariable name value format="docker"]
    [#switch format]
        [#case "docker"]
            {
                "Name" : "${name}",
                "Value" : "${value}"
            }
            [#break]

        [#case "lambda"]
        [#default]
            "${name}" : "${value}"
            [#break]

    [/#switch]
[/#macro]

[#macro standardEnvironmentVariables format="docker"]
    [@environmentVariable "TEMPLATE_TIMESTAMP" "${.now?iso_utc}" format /],
    [@environmentVariable "ENVIRONMENT" "${environmentName}" format /],
    [@environmentVariable "REQUEST_REFERENCE" "${requestReference}" format /],
    [@environmentVariable "CONFIGURATION_REFERENCE" "${configurationReference}" format /]
    [#if buildCommit??]
        ,[@environmentVariable "BUILD_REFERENCE" "${buildCommit}" format /]
    [/#if]
    [#if appReference?? && (appReference != "")]
        ,[@environmentVariable "APP_REFERENCE" "${appReference}" format /]
    [/#if]
[/#macro]

[#macro createTask tier component task taskIdStem version]
    [#-- Set up context for processing the list of containers --]
    [#assign containerListTarget = "docker"]
    [#assign containerListRole = formatId("role", taskIdStem)]

    [#-- Check if a role is required --]
    [#assign containerListMode = "policyCount"]
    [#assign policyCount = 0]
    [#list task.Containers?values as container]
        [#if container?is_hash]
            [#assign containerId = formatName(container.Id, version)]
            [#include containerList]
        [/#if]
    [/#list]

    [#-- Create a role under which the task will run and attach required policies --]
    [#if policyCount > 0]
        "${containerListRole}" : {
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
                [#assign containerId = formatName(container.Id, version)]
                [#assign policyIdStem = formatId(taskIdStem, container.Id)]
                [#assign policyNameStem = formatId(container.Name)]
                [#include containerList]
            [/#if]
        [/#list]
    [/#if]

    "${formatId("ecsTask", taskIdStem)}" : {
        "Type" : "AWS::ECS::TaskDefinition",
        "Properties" : {
            "ContainerDefinitions" : [
                [#assign containerCount = 0]
                [#list task.Containers?values as container]
                    [#if container?is_hash]
                        [#assign dockerTag = ""]
                        [#if container.Version??]
                            [#assign dockerTag = ":" + container.Version]
                        [/#if]
                        [#if containerCount > 0],[/#if]
                        {
                            [#assign containerId = formatName(container.Id, version)]
                            [#assign containerName = formatName(tier.Name, component.Name, container.Name)]
                            [#assign containerListMode = "definition"]
                            [#include containerList]
                            [#assign containerListMode = "environmentCount"]
                            [#assign environmentCount = 0]
                            [#include containerList]
                            [#if environmentCount > 0]
                                "Environment" : [
                                    [#assign containerListMode = "environment"]
                                    [#include containerList]
                                ],
                            [/#if]
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
                    [#assign containerId = formatName(container.Id, version)]
                    [#include containerList]
                [/#if]
            [/#list]
            [#if volumeCount > 0]
                ,"Volumes" : [
                    [#assign containerListMode = "volumes"]
                    [#assign volumeCount = 0]
                    [#list task.Containers?values as container]
                        [#if container?is_hash]
                            [#assign containerId = formatName(container.Id, version)]
                            [#include containerList]
                        [/#if]
                    [/#list]
                ]
            [/#if]
            [#if policyCount > 0]
                ,"TaskRoleArn" : { "Fn::GetAtt" : ["${containerListRole}","Arn"]}
            [/#if]
        }
    }
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

