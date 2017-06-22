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
                                        "VPCAccess" : lambdaInstance.VPCAccess!version.VPCAccess!lambda.VPCAccess!true,
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
                                "VPCAccess" : version.VPCAccess!lambda.VPCAccess!true,
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
                    "VPCAccess" : lambda.VPCAccess!true,
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
            [#if vpc?has_content && lambdaInstance.Internal.VPCAccess]
                [@createDependentSecurityGroup 
                    applicationListMode
                    tier
                    component
                    lambdaId
                    lambdaName  /]
            [/#if]

            [#if isPartOfCurrentDeploymentUnit(containerListRole)]
                [#switch applicationListMode]
                    [#case "definition"]            
                        [#-- Create a role under which the function will run and attach required policies --]
                        [#-- The role is mandatory though there may be no policies attached to it --]
                        [#assign managedArns = []]
                        [#if vpc?has_content && lambdaInstance.Internal.VPCAccess]
                            [#assign
                                managedArns = [
                                    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
                                ]
                            ]
                        [#else]
                            [#assign
                                managedArns = [
                                    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
                                ]
                            ]
                        [/#if]
                        [@role
                            containerListRole,
                            ["lambda.amazonaws.com" ],
                            managedArns /]
                        [@resourcesCreated /]
                        [#assign containerListMode = "policy"]
                        [#assign containerListPolicyId = formatDependentPolicyId(
                                                            lambdaId,
                                                            {"Id" : lambda.Container })]
                        [#assign containerListPolicyName = formatContainerPolicyName(
                                                            tier,
                                                            component,
                                                            lambdaInstance,
                                                            {"Name" : lambda.Container })]
                        [#include containerList?ensure_starts_with("/")]
                        [#break]

                [#case "outputs"]
                    [@output containerListRole /]
                    [@outputArn containerListRole /]
                    [#break]

                [/#switch]
            [/#if]
        
            [#if !deploymentSubsetRequired("iam")]
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
                        [#switch applicationListMode]
                            [#case "definition"]
                                [@checkIfResourcesCreated /]
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
                                                    [#assign environmentCount = 0]
                                                    [#include containerList?ensure_starts_with("/")]
                                                }
                                            },
                                        [/#if]
                                        "FunctionName" : "${lambdaFunctionName}",
                                        "Description" : "${lambdaFunctionName}",
                                        "Handler" : "${fn.Handler}",
                                        "Role" : [@createArnReference containerListRole /],
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
                                        [#if vpc?has_content && lambdaInstance.Internal.VPCAccess]
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
                                [@resourcesCreated /]
                                [#break]
        
                            [#case "outputs"]
                                [@output lambdaFunctionId /]
                                [@outputArn lambdaFunctionId /]
                                [#break]
        
                        [/#switch]
                    [/#if]
                [/#list]
            [/#if]
        [/#if]
    [/#list]
[/#if]
