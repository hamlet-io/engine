[#if component.Lambda??]
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
                                        "VersionId" : version.Id,
                                        "VersionName" : version.Name,
                                        "InstanceId" : (lambdaInstance.Id == "default")?string("",lambdaInstance.Id),
                                        "InstanceName" : (lambdaInstance.Id == "default")?string("",lambdaInstance.Name),
                                        "RunTime" : lambdaInstance.RunTime!version.RunTime!lambda.RunTime,
                                        "MemorySize" : lambdaInstance.MemorySize!version.MemorySize!lambda.MemorySize,
                                        "Timeout" : lambdaInstance.Timeout!version.Timeout!lambda.Timeout,
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
                                "VersionId" : version.Id,
                                "VersionName" : version.Name,
                                "InstanceId" : "",
                                "InstanceName" : "",
                                "RunTime" : version.RunTime!lambda.RunTime,
                                "MemorySize" : version.MemorySize!lambda.MemorySize,
                                "Timeout" : version.Timeout!lambda.Timeout,
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
                    "VersionId" : "",
                    "VersionName" : "",
                    "InstanceId" : "",
                    "InstanceName" : "",
                    "RunTime" : lambda.RunTime,
                    "MemorySize" : lambda.MemorySize,
                    "Timeout" : lambda.Timeout,
                    "Functions" : lambda.Functions!"unknown"
                }
            }
        ]]
    [/#if]

    [#list lambdaInstances as lambdaInstance]
        [#assign lambdaIdStem = formatId(componentIdStem,
                                            lambdaInstance.Internal.VersionId,
                                            lambdaInstance.Internal.InstanceId)]
        [#assign lambdaNameStem = formatName(componentNameStem,
                                            lambdaInstance.Internal.VersionName,
                                            lambdaInstance.Internal.InstanceName)]

        [#if lambdaInstance.Internal.Functions?is_hash]

            [#-- Set up context for processing the list of containers --]
            [#assign containerListTarget = "lambda"]
            [#assign containerListRole = formatId("role", lambdaIdStem)]
            [#assign containerId = formatName(lambda.Container,
                                                lambdaInstance.Internal.VersionId,
                                                lambdaInstance.Internal.InstanceId)]

            [#-- VPC config uses an ENI so needs an SG - create one without restriction --]
            [#if vpc != "unknown"]
                [#assign lambdaSGIdStem = formatId(lambdaInstance.Internal.VersionId, lambdaInstance.Internal.InstanceId)]
                [#assign lambdaSGNameStem = formatName(lambdaInstance.Internal.VersionName, lambdaInstance.Internal.InstanceName)]
                [@securityGroup applicationListMode tier component lambdaSGIdStem lambdaSGNameStem /]
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
                    [#assign policyIdStem = lambdaIdStem]
                    [#assign policyNameStem = lambda.Container]
                    [#include containerList?ensure_starts_with("/")]
                    [#break]
                
            [/#switch]
        
            [#assign functionCount = 0]
            [#list lambdaInstance.Internal.Functions?values as fn]
                [#if fn?is_hash]
                    [#if functionCount > 0],[/#if]
                    [#assign lambdaFunctionIdStem = formatId(lambdaIdStem, fn.Id)]
                    [#assign lambdaFunctionNameStem = formatName(lambdaNameStem, fn.Name)]
                    [#switch applicationListMode]
                        [#case "definition"]
                            "${formatId("lambda", lambdaFunctionIdStem)}" : {
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
                                    "FunctionName" : "${formatName(lambdaFunctionNameStem)}",
                                    "Description" : "${formatName(lambdaFunctionNameStem)}",
                                    "Handler" : "${fn.Handler}",
                                    "Role" : { "Fn::GetAtt" : ["${containerListRole}","Arn"]},
                                    "Runtime" : "${fn.RunTime!lambdaInstance.Internal.RunTime}"
                                    [#if (fn.Memory!lambdaObject.Memory!lambda.Memory)??]
                                        ,"MemorySize" : ${(fn.Memory!lambdaInstance.Internal.Memory)?c}
                                    [/#if]
                                    [#if (fn.Timeout!lambdaObject.Timeout!lambda.Timeout)??]
                                        ,"Timeout" : ${(fn.Timeout!lambdaInstance.Internal.Timeout)?c}
                                    [/#if]
                                    [#if lambda.UseSegmentKey?? && (lambda.UseSegmentKey == true) ]
                                        ,"KmsKeyArn" : "${getKey("cmk", "segment", "cmk", "arn")}"
                                    [/#if]
                                    [#if vpc != "unknown"]
                                        ,"VpcConfig" : {
                                            "SecurityGroupIds" : [ 
                                                { "Ref" : "${formatId("securityGroup", lambdaIdStem)}" }
                                            ],
                                            "SubnetIds" : [
                                                [#list zones as zone]
                                                    "${getKey("subnet", tier.Id, zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                                                [/#list]
                                            ]
                                        }
                                    [/#if]
                                }
                            }
                            [#break]
    
                        [#case "outputs"]
                            "${formatId("lambda", lambdaFunctionIdStem)}" : {
                                "Value" : { "Ref" : "${formatId("lambda", lambdaFunctionIdStem)}" }
                            },
                            "${formatId("lambda", lambdaFunctionIdStem, "arn")}" : {
                                "Value" : { "Fn::GetAtt" : ["${formatId("lambda", lambdaFunctionIdStem)}", "Arn"]}
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
