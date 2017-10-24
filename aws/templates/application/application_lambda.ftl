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

            [#assign containerId =
                occurrence.Container?has_content?then(
                    occurrence.Container,
                    getComponentId(component)                            
                ) ]
            [#assign currentContainer = 
                {
                    "Id" : containerId,
                    "Name" : containerId,
                    "Environment" :
                        standardEnvironment(tier, component, occurrence, "WEB"),
                    "S3Bucket" : getRegistryEndPoint("lambda"),
                    "S3Key" : 
                        formatRelativePath(
                            getRegistryPrefix("lambda") + productName,
                            buildDeploymentUnit,
                            buildCommit,
                            "lambda.zip"
                        )

                }
            ]
        
            [#-- Add in container specifics including override of defaults --]
            [#assign containerListMode = "model"]
            [#assign containerId = formatContainerFragmentId(occurrence, currentContainer)]
            [#include containerList?ensure_starts_with("/")]
    
            [#assign roleId = formatDependentRoleId(lambdaId)]
            [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(roleId)]
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
                
                [#if currentContainer.Policy?has_content]
                    [#assign policyId = formatDependentPolicyId(lambdaId, currentContainer)]
                    [@createPolicy
                        mode=applicationListMode
                        id=policyId
                        name=currentContainer.Name
                        statements=currentContainer.Policy
                        roles=roleId
                    /]
                [/#if]
            [/#if]

            [#if deploymentSubsetRequired("lambda", true)]
                [#-- VPC config uses an ENI so needs an SG - create one without restriction --]
                [#if vpc?has_content && occurrence.VPCAccess]
                    [@createDependentSecurityGroup 
                        mode=applicationListMode
                        tier=tier
                        component=component
                        resourceId=lambdaId
                        resourceName=lambdaName  /]
                [/#if]

                [#list occurrence.Functions?values as fn]
                    [#if fn?is_hash]
                        [#assign lambdaFunctionId =
                            formatLambdaFunctionId(
                                tier,
                                component,
                                fn,
                                occurrence)]
    
                        [#assign lambdaFunctionName =
                            formatLambdaFunctionName(
                                tier,
                                component,
                                occurrence,
                                fn)]
                                
                        [@createLambdaFunction
                            mode=applicationListMode
                            id=lambdaFunctionId
                            container=currentContainer +
                                {
                                    "Handler" : fn.Handler!occurrence.Handler,
                                    "RunTime" : fn.RunTime!occurrence.RunTime,
                                    "MemorySize" : fn.MemorySize!occurrence.MemorySize,
                                    "Timeout" : fn.Timeout!occurrence.Timeout,
                                    "UseSegmentKey" : fn.UseSegmentKey!occurrence.UseSegmentKey,
                                    "Name" : lambdaFunctionName,
                                    "Description" : lambdaFunctionName
                                }
                            roleId=roleId
                            securityGroupIds=
                                (vpc?has_content && occurrence.VPCAccess)?then(
                                    formatDependentSecurityGroupId(lambdaId),
                                    ""
                                )
                            securityGroupIds=
                                (vpc?has_content && occurrence.VPCAccess)?then(
                                    formatDependentSecurityGroupId(lambdaId),
                                    []
                                )
                            subnetIds=
                                (vpc?has_content && occurrence.VPCAccess)?then(
                                    getSubnets(tier, false),
                                    []
                                )
                            dependencies=roleId
                        /]
                    [/#if]
                [/#list]
                
                [#-- Pick any extra macros in the container fragment --]
                [#assign containerListMode = applicationListMode]
                [#include containerList?ensure_starts_with("/")]
            [/#if]
        [/#if]
    [/#list]
[/#if]
