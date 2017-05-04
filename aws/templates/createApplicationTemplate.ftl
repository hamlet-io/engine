[#ftl]
[#include "setContext.ftl"]

[#function getRegistryEndPoint type]
    [#return (appSettingsObject.Registries[type?lower_case].EndPoint)!(appSettingsObject[type?capitalize].Registry)!"unknown"]
[/#function]

[#function getRegistryPrefix type]
    [#return (appSettingsObject.Registries[type?lower_case].Prefix)!(appSettingsObject[type?capitalize].Prefix)!""]
[/#function]

[#function getCredentialFilePrefix]
    [#return "credentials/" + productName + "/" + segmentName]
[/#function]

[#function getAppSettingsFilePrefix]
    [#return "appsettings/" + productName + "/" + segmentName + "/" + deployment_unit]
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

[#macro createTask tier component task]
    [#-- Set up context for processing the list of containers --]
    [#assign containerListTarget = "docker"]
    [#assign containerListRole = formatContainerHostRoleResourceId(
                                    tier,
                                    component,
                                    task)]

    [#-- Check if a role is required --]
    [#assign containerListMode = "policyCount"]
    [#assign policyCount = 0]
    [#list task.Containers?values as container]
        [#if container?is_hash]
            [#assign containerId = formatContainerId(
                                    tier,
                                    component,
                                    task,
                                    container)]
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
                [#assign containerId = formatContainerId(
                                        tier,
                                        component,
                                        task,
                                        container)]
                [#-- DEPRECATED: These stem variables are deprecated --]
                [#--             in favour of the containerListPolicy* variables --]
                [#assign policyIdStem = formatComponentIdStem(
                                            tier,
                                            component,
                                            task.Internal.TaskId,
                                            task.Internal.VersionId,
                                            task.Internal.InstanceId,
                                            container.Id)]
                [#assign policyNameStem = formatName(container.Name)]
                [#assign containerListPolicyId = formatContainerPolicyResourceId(
                                                tier,
                                                component,
                                                task,
                                                container)]
                [#assign containerListPolicyName = formatContainerPolicyName(
                                                tier,
                                                component,
                                                task,
                                                container)]
                [#include containerList]
            [/#if]
        [/#list]
    [/#if]

    "${formatECSTaskResourceId(tier, component, task)}" : {
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
                            [#assign containerId = formatContainerId(
                                                    tier,
                                                    component,
                                                    task,
                                                    container)]
                            [#assign containerName = formatContainerName(
                                                        tier,
                                                        component,
                                                        task,
                                                        container)]
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
                                [#if ((appSettingsObject.Docker.LocalLogging)?? && appSettingsObject.Docker.LocalLogging) || (container.LocalLogging?? && (container.LocalLogging == true))]
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
                    [#assign containerId = formatContainerId(
                                            tier,
                                            component,
                                            task,
                                            container)]
                    [#include containerList]
                [/#if]
            [/#list]
            [#if volumeCount > 0]
                ,"Volumes" : [
                    [#assign containerListMode = "volumes"]
                    [#assign volumeCount = 0]
                    [#list task.Containers?values as container]
                        [#if container?is_hash]
                            [#assign containerId = formatContainerId(
                                                    tier,
                                                    component,
                                                    task,
                                                    container)]
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

