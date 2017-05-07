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
                                        "IdExtensions" : [
                                            version.Id,
                                            (lambdaInstance.Id == "default")?
                                                string(
                                                    "",
                                                    lambdaInstance.Id)],
                                        "NameExtensions" : [
                                            version.Name,
                                            (lambdaInstance.Id == "default")?
                                                string(
                                                    "",
                                                    lambdaInstance.Name)],
                                        "HostIdExtensions" : [
                                            version.Id,
                                            (lambdaInstance.Id == "default")?
                                                string(
                                                    "",
                                                    lambdaInstance.Id)],
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
                                "IdExtensions" : [
                                    version.Id],
                                "NameExtensions" : [
                                    version.Name],
                                "HostIdExtensions" : [
                                    version.Id],
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
                    "IdExtensions" : [],
                    "NameExtensions" : [],
                    "HostIdExtensions" : [],
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
        
            [#assign lambdaId = formatLambdaId(
                                    tier,
                                    component,
                                    lambdaInstance)]
            [#assign lambdaName = formatLambdaName(
                                    tier,
                                    component,
                                    lambdaInstance)]
        
            [#-- Set up context for processing the list of containers --]
            [#assign containerListTarget = "lambda"]
            [#assign containerListRole = formatDependentRoleId(lambdaId)]
            [#assign containerId = formatContainerId(
                                    lambdaInstance,
                                    {"Id" : lambda.Container })]

            [#-- VPC config uses an ENI so needs an SG - create one without restriction --]
            [#if vpc != "unknown"]
                [@createDependentSecurityGroup 
                    applicationListMode
                    tier
                    component
                    lambdaId
                    lambdaName  /]
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
                    [#assign containerListPolicyId = formatDependentPolicyId(
                                                        lambdaId,
                                                        {"Id" : lambda.Container })]
                    [#assign containerListPolicyName = formatContainerPolicyName(
                                                        lambdaInstance,
                                                        {"Name" : lambda.Container })]
                    [#include containerList?ensure_starts_with("/")]
                    [#break]
                
            [/#switch]
        
            [#assign functionCount = 0]
            [#list lambdaInstance.Internal.Functions?values as fn]
                [#if fn?is_hash]
                    [#assign lambdaFunctionId = formatLambdaFunctionId(
                                        tier,
                                        component,
                                        fn,
                                        lambdaInstance)]

                    [#assign lambdaFunctionName = formatLambdaFunctionName(
                                                tier,
                                                component,
                                                lambdaInstance,
                                                fn)]
                    [#if functionCount > 0],[/#if]
                    [#switch applicationListMode]
                        [#case "definition"]
                            "${lambdaFunctionId}" : {
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
                                        ,"KmsKeyArn" : "${getKey(formatSegmentCMKArnId())}"
                                    [/#if]
                                    [#if vpc != "unknown"]
                                        ,"VpcConfig" : {
                                            "SecurityGroupIds" : [ 
                                                { "Ref" : "${formatDependentSecurityGroupId(lambdaId)}" }
                                            ],
                                            "SubnetIds" : [
                                                [#list zones as zone]
                                                    "${getKey(formatSubnetId(
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
                            [@output lambdaFunctionId /],
                            [@outputArn lambdaFunctionId /]
                            [#break]
    
                    [/#switch]
                    [#assign functionCount += 1]
                [/#if]
            [/#list]
            [#assign resourceCount += 1]
        [/#if]
    [/#list]
[/#if]
