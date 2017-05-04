[#if componentType = "lambda"]
    [#assign lambda = component.Lambda]

    [#assign lambdaInstances=[] ]
    [#if lambda.Versions??]
        [#list lambda.Versions?values as version]
            [#if deploymentRequired(version, deploymentUnit)]            
                [#if version.Instances??]
                    [#list version.Instances?values as lambdaInstance]
                        [#if deploymentRequired(lambdaInstance, deploymentUnit)]
                            [#assign lambdaInstances += [lambdaInstance +
                                {
                                    "Internal" : {
                                        "HostId" : "lambda",
                                        "VersionId" : version.Id,
                                        "VersionName" : version.Name,
                                        "InstanceId" : (lambdaInstance.Id == "default")?string("",lambdaInstance.Id),
                                        "InstanceName" : (lambdaInstance.Id == "default")?string("",lambdaInstance.Name),
                                        "RunTime" : lambdaInstance.RunTime!version.RunTime!lambda.RunTime,
                                        "MemorySize" : lambdaInstance.MemorySize!version.MemorySize!lambda.MemorySize!0,
                                        "Timeout" : lambdaInstance.Timeout!version.Timeout!lambda.Timeout!0,
                                        "Functions" : lambdaInstance.Functions!version.Functions!lambda.Functions!"unknown"
                                    }
                                }
                            ] ]
                        [/#if]
                    [/#list]
                [#else]
                    [#assign lambdaInstances += [version +
                        {
                            "Internal" : {
                                "HostId" : "lambda",
                                "VersionId" : version.Id,
                                "VersionName" : version.Name,
                                "InstanceId" : "",
                                "InstanceName" : "",
                                "RunTime" : version.RunTime!lambda.RunTime,
                                "MemorySize" : version.MemorySize!lambda.MemorySize!0,
                                "Timeout" : version.Timeout!lambda.Timeout!0,
                                "Functions" : version.Functions!lambda.Functions!"unknown"
                            }
                        }
                    ] ]
                [/#if]
            [/#if]
        [/#list]
    [#else]
        [#assign lambdaInstances += [lambda +
            {
                "Internal" : {
                    "HostId" : "lambda",
                    "VersionId" : "",
                    "VersionName" : "",
                    "InstanceId" : "",
                    "InstanceName" : "",
                    "RunTime" : lambda.RunTime,
                    "MemorySize" : lambda.MemorySize!0,
                    "Timeout" : lambda.Timeout!0,
                    "Functions" : lambda.Functions!"unknown"
                }
            }
        ]]
    [/#if]

    [#list lambdaInstances as lambdaInstance]
        [#if lambdaInstance.Internal.Functions?is_hash]
        
            [#-- Set up context for processing the list of containers --]
            [#assign containerListTarget = "lambda"]
            [#assign containerListRole = formatContainerHostRoleResourceId(
                                            tier,
                                            component,
                                            lambdaInstance)]
            [#assign containerId = formatContainerId(
                                    tier,
                                    component,
                                    lambdaInstance,
                                    {"Id" : lambda.Container })]

            [#-- VPC config uses an ENI so needs an SG - create one without restriction --]
            [#if vpc != "unknown"]
                [@createSecurityGroup 
                    applicationListMode
                    tier
                    component
                    formatIdExtension(
                        lambdaInstance.Internal.VersionId,
                        lambdaInstance.Internal.InstanceId)
                    formatNameExtension(
                        lambdaInstance.Internal.VersionName,
                        lambdaInstance.Internal.InstanceName) /]
            [/#if]

            [#if resourceCount > 0],[/#if]
            [#switch applicationListMode]
                [#case "definition"]            
                    [#-- Create a role under which the function will run and attach required policies --]
                    [#-- The role is mandatory though there may be no policies attached to it --]
                    "${containerListRole}" : {
                        "Type" : "AWS::IAM::Role",
                        "Properties" : {
                            "AssumeRolePolicyDocument" : {
                                "Version": "2012-10-17",
                                "Statement": [
                                    {
                                        "Effect": "Allow",
                                        "Principal": { "Service": [ "lambda.amazonaws.com" ] },
                                        "Action": [ "sts:AssumeRole" ]
                                    }
                                ]
                            },
                            "Path": "/"
                            [#if vpc != "unknown"]
                                ,"ManagedPolicyArns" : [
                                    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
                                ]
                            [/#if]
                        }
                    },
                    [#assign containerListMode = "policy"]
                    [#assign containerListPolicyId = formatContainerPolicyResourceId(
                                                        tier,
                                                        component,
                                                        lambdaInstance,
                                                        {"Id" : lambda.Container })]
                    [#assign containerListPolicyName = formatContainerPolicyName(
                                                        tier,
                                                        component,
                                                        lambdaInstance,
                                                        {"Name" : lambda.Container })]
                    [#include containerList?ensure_starts_with("/")]
                    [#break]
                
            [/#switch]
        
            [#assign functionCount = 0]
            [#list lambdaInstance.Internal.Functions?values as fn]
                [#if fn?is_hash]
                    [#assign lambdaFunctionResourceId = formatLambdaFunctionResourceId(
                                        tier,
                                        component,
                                        lambdaInstance,
                                        fn)]

                    [#assign lambdaFunctionName = formatLambdaFunctionName(
                                                tier,
                                                component,
                                                lambdaInstance,
                                                fn)]
                    [#if functionCount > 0],[/#if]
                    [#switch applicationListMode]
                        [#case "definition"]
                            "${lambdaFunctionResourceId}" : {
                                "Type" : "AWS::Lambda::Function",
                                "Properties" : {
                                    "Code" : {
                                        "S3Bucket" : "${getRegistryEndPoint("lambda")}",
                                        "S3Key" : "${getRegistryPrefix("lambda")}${productName}/${buildDeploymentUnit}/${buildCommit}/lambda.zip"
                                    },
                                    [#assign containerListMode = "definition"]
                                    [#include containerList?ensure_starts_with("/")]
                                    [#assign containerListMode = "environmentCount"]
                                    [#assign environmentCount = 0]
                                    [#include containerList?ensure_starts_with("/")]
                                    [#if environmentCount > 0]
                                        "Environment" : {
                                            "Variables" : {
                                                [#assign containerListMode = "environment"]
                                                [#include containerList?ensure_starts_with("/")]
                                            }
                                        },
                                    [/#if]
                                    "FunctionName" : "${lambdaFunctionName}",
                                    "Description" : "${lambdaFunctionName}",
                                    "Handler" : "${fn.Handler}",
                                    "Role" : { "Fn::GetAtt" : ["${containerListRole}","Arn"]},
                                    "Runtime" : "${fn.RunTime!lambdaInstance.Internal.RunTime}"
                                    [#assign memorySize = fn.Memory!lambdaInstance.Internal.MemorySize]
                                    [#if memorySize > 0]
                                        ,"MemorySize" : ${(memorySize)?c}
                                    [/#if]
                                    [#assign timeout = fn.Timeout!lambdaInstance.Internal.Timeout]
                                    [#if timeout > 0]
                                        ,"Timeout" : ${(timeout)?c}
                                    [/#if]
                                    [#if lambda.UseSegmentKey?? && (lambda.UseSegmentKey == true) ]
                                        ,"KmsKeyArn" : "${getKey(formatKMSCMKResourceArnId())}"
                                    [/#if]
                                    [#if vpc != "unknown"]
                                        ,"VpcConfig" : {
                                            "SecurityGroupIds" : [ 
                                                { "Ref" : "${formatLambdaSecurityGroupResourceId(
                                                                tier,
                                                                component,
                                                                lambdaInstance)}" }
                                            ],
                                            "SubnetIds" : [
                                                [#list zones as zone]
                                                    "${getKey(formatVPCSubnetResourceId(
                                                                tier,
                                                                zone))}"
                                                    [#if !(zones?last.Id == zone.Id)],[/#if]
                                                [/#list]
                                            ]
                                        }
                                    [/#if]
                                }
                            }
                            [#break]
    
                        [#case "outputs"]
                            "${lambdaFunctionResourceId}" : {
                                "Value" : { "Ref" : "${lambdaFunctionResourceId}" }
                            },
                            "${formatResourceAttributeId(lambdaFunctionResourceId, "arn")}" : {
                                "Value" : { "Fn::GetAtt" : ["${lambdaFunctionResourceId}", "Arn"]}
                            }
                            [#break]
    
                    [/#switch]
                    [#assign functionCount += 1]
                [/#if]
            [/#list]
            [#assign resourceCount += 1]
        [/#if]
    [/#list]
[/#if]
