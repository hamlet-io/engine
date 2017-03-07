[#if component.Lambda??]
    [#assign lambda = component.Lambda]

    [#assign lambdaFound = false]
    [#assign lambdaIdStem = componentIdStem]
    [#assign lambdaVersion = ""]
    [#assign lambdaVersionName = ""]
    [#if lambda.Versions??]
        [#list lambda.Versions?values as version]
            [#if version?is_hash]
                [#if version.DeploymentUnits?seq_contains(deploymentUnit)]
                    [#assign lambdaFound = true]
                    [#assign lambdaVersion = version.Id]
                    [#assign lambdaVersionName = version.Name]
                    [#assign lambdaIdStem = formatId(lambdaIdStem, version.Id)]
                    [#assign lambdaObject = version]
                    [#break]
                [/#if]
            [/#if]
        [/#list]
    [#else]
        [#if lambda.DeploymentUnits?seq_contains(deploymentUnit) ]
            [#assign lambdaFound = true]
            [#assign lambdaObject = lambda]
        [/#if]
    [/#if]

    [#if lambdaFound && lambdaObject.Functions??]
        [#-- Set up context for processing the list of containers --]
        [#assign containerListTarget = "lambda"]
        [#assign containerListRole = formatId("role", lambdaIdStem)]
        [#assign containerId = formatName(lambda.Container, lambdaVersion)]

        [#-- VPC config uses an ENI so needs an SG - create one without restriction --]
        [#if vpc != "unknown"]
            [@securityGroup applicationListMode tier component lambdaVersion /]
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
        [#list lambdaObject.Functions?values as fn]
            [#if fn?is_hash]
                [#if functionCount > 0],[/#if]
                [#switch applicationListMode]
                    [#case "definition"]
                        "${formatId("lambda", lambdaIdStem, fn.Id)}" : {
                            "Type" : "AWS::Lambda::Function",
                            "Properties" : {
                                "Code" : {
                                    "S3Bucket" : "${getRegistryEndPoint("lambda")}",
                                    "S3Key" : "${getRegistryPrefix("lambda")}${productId}/${deploymentUnit}/${buildCommit}/lambda.zip"
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
                                "FunctionName" : "${formatName(componentNameStem, lambdaVersionName, fn.Name)}",
                                "Description" : "${formatName(componentNameStem, lambdaVersionName, fn.Name)}",
                                "Handler" : "${fn.Handler}",
                                "Role" : { "Fn::GetAtt" : ["${containerListRole}","Arn"]},
                                "Runtime" : "${fn.RunTime!lambdaObject.RunTime!lambda.RunTime}"
                                [#if (fn.Memory!lambdaObject.Memory!lambda.Memory)??]
                                    ,"MemorySize" : ${(fn.Memory!lambdaObject.Memory!lambda.Memory)?c}
                                [/#if]
                                [#if (fn.Timeout!lambdaObject.Timeout!lambda.Timeout)??]
                                    ,"Timeout" : ${(fn.Timeout!lambdaObject.Timeout!lambda.Timeout)?c}
                                [/#if]
                                [#if lambda.UseSegmentKey?? && (lambda.UseSegmentKey == true) ]
                                    ,"KmsKeyArn" : "${getKey("cmk", "segment", "cmk", "arn")}"
                                [/#if]
                                [#if vpc != "unknown"]
                                    ,"VpcConfig" : {
                                        "SecurityGroupIds" : [ 
                                            { "Ref" : "${formatId("securityGroup", componentIdStem, lambdaVersion)}" }
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
                        "${formatId("lambda", lambdaIdStem, fn.Name)}" : {
                            "Value" : { "Ref" : "${formatId("lambda", lambdaIdStem, fn.Name)}" }
                        },
                        "${formatId("lambda", lambdaIdStem, fn.Name, "arn")}" : {
                            "Value" : { "Fn::GetAtt" : ["${formatId("lambda", lambdaIdStem, fn.Name)}", "Arn"]}
                        }
                        [#break]

                [/#switch]
                [#assign functionCount += 1]
            [/#if]
        [/#list]
        [#assign resourceCount += 1]
    [/#if]
[/#if]
