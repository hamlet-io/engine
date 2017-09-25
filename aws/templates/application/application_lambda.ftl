[#if componentType = "lambda"]

    [#list getOccurrences(component, deploymentUnit) as occurrence]
        [#if occurrence.Functions?is_hash]
        
            [#assign lambdaId = formatLambdaId(
                                    tier,
                                    component,
                                    occurrence)]
            [#assign lambdaName = formatLambdaName(
                                    tier,
                                    component,
                                    occurrence)]
        
            [#-- Set up context for processing the list of containers --]
            [#assign container =
                getLambdaContainer(
                    occurrence,
                    {
                        "Id" : occurrence.Container,
                        "Name" : occurrence.Container
                    }
                )
            ]

            [#assign roleId = formatDependentRoleId(lambdaId)]
            [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(containerListRole)]
                [#-- Create a role under which the function will run and attach required policies --]
                [#-- The role is mandatory though there may be no policies attached to it --]
                [@createRole 
                    mode=applicationListMode
                    id=roleId
                    trustedServices=["lambda.amazonaws.com"]
                    managedArns=
                        (vpc?has_content && occurrence.VPCAccess)?then(
                            ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"],
                            ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
                        )
                /]
                
                [#if container.Policy?has_content]
                        [#assign policyId = formatDependentPolicyId(taskId, container.Id)]
                        [@createPolicy
                            mode=applicationListMode
                            id=policyId
                            name=container.Name
                            statements=container.Policy
                            role=roleId
                        /]
                        [#assign dependencies += [policyId]
                    [/#if]
                [/#list]

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
                                                            occurrence,
                                                            {"Name" : lambda.Container })]
                        [#include containerList?ensure_starts_with("/")]
                        [#break]

                [#case "outputs"]
                    [@output containerListRole /]
                    [@outputArn containerListRole /]
                    [#break]

                [/#switch]
            [/#if]
        
            [#if deploymentSubsetRequired("lambda", true)]
                [#-- VPC config uses an ENI so needs an SG - create one without restriction --]
                [#if vpc?has_content && occurrence.VPCAccess]
                    [@createDependentSecurityGroup 
                        applicationListMode
                        tier
                        component
                        lambdaId
                        lambdaName  /]
                [/#if]

                [#list occurrence.Functions?values as fn]
                    [#if fn?is_hash]
                        [#assign lambdaFunctionId = formatLambdaFunctionId(
                                            tier,
                                            component,
                                            fn,
                                            occurrence)]
    
                        [#assign lambdaFunctionName = formatLambdaFunctionName(
                                                    tier,
                                                    component,
                                                    occurrence,
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
                                        "Runtime" : "${fn.RunTime!occurrence.RunTime}"
                                        [#assign memorySize = fn.Memory!occurrence.MemorySize]
                                        [#if memorySize > 0]
                                            ,"MemorySize" : ${(memorySize)?c}
                                        [/#if]
                                        [#assign timeout = fn.Timeout!occurrence.Timeout]
                                        [#if timeout > 0]
                                            ,"Timeout" : ${(timeout)?c}
                                        [/#if]
                                        [#if lambda.UseSegmentKey?? && (lambda.UseSegmentKey == true) ]
                                            ,"KmsKeyArn" : "${getKey(formatSegmentCMKArnId())}"
                                        [/#if]
                                        [#if vpc?has_content && occurrence.VPCAccess]
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
                                    [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(containerListRole)]
                                        ,"DependsOn" : [
                                            "${containerListRole}"
                                        ]
                                    [/#if]
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
