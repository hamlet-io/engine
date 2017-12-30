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
            [#assign context = 
                {
                    "Id" : containerId,
                    "Name" : containerId,
                    "Instance" : occurrence.InstanceId,
                    "Version" : occurrence.VersionId,
                    "Environment" :
                        standardEnvironment(tier, component, occurrence, "WEB"),
                    "S3Bucket" : getRegistryEndPoint("lambda"),
                    "S3Key" : 
                        formatRelativePath(
                            getRegistryPrefix("lambda") + productName,
                            buildDeploymentUnit,
                            buildCommit,
                            "lambda.zip"
                        ),
                    "Links" : {}
                }
            ]
        
            [#list occurrence.Links?values as link]
                [#if link?is_hash]
                    [#assign targetComponent = getComponent(link.Tier, link.Component)]
                    [#if targetComponent?has_content]
                        [#list getOccurrences(targetComponent) as targetOccurrence]
                            [#if (targetOccurrence.InstanceId == occurrence.InstanceId) &&
                                    (targetOccurrence.VersionId == occurrence.VersionId)]
                                [#switch getComponentType(targetComponent)]
                                    [#case "alb"]
                                        [#assign context +=
                                            {
                                              "Links" :
                                                  context.Links +
                                                  {
                                                    link.Name : {
                                                        "Url" :
                                                            getExistingReference(
                                                                formatALBId(
                                                                    link.Tier,
                                                                    link.Component,
                                                                    targetOccurrence),
                                                                DNS_ATTRIBUTE_TYPE)
                                                    }
                                                }
                                            }
                                        ]
                                        [#break]

                                    [#case "apigateway"]
                                        [#assign apiId =
                                            formatAPIGatewayId(
                                                link.Tier,
                                                link.Component,
                                                targetOccurrence)]
                                        [#assign context +=
                                            {
                                              "Links" :
                                                  context.Links +
                                                  {
                                                    link.Name : {
                                                        "Url" :
                                                            "https://" +
                                                            formatDomainName(
                                                                getExistingReference(apiId),
                                                                "execute-api",
                                                                regionId,
                                                                "amazonaws.com"),
                                                        "Policy" : apigatewayInvokePermission(apiId, occurrence.VersionId)
                                                    }
                                                }
                                            }
                                        ]
                                        [#break]
                                [/#switch]
                                [#break]
                            [/#if]
                        [/#list]
                    [/#if]
                [/#if]
            [/#list]

            [#-- Add in container specifics including override of defaults --]
            [#assign containerListMode = "model"]
            [#assign containerId = formatContainerFragmentId(occurrence, context)]
            [#include containerList?ensure_starts_with("/")]

            [#assign roleId = formatDependentRoleId(lambdaId)]
            [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(roleId)]
                [#-- Create a role under which the function will run and attach required policies --]
                [#-- The role is mandatory though there may be no policies attached to it --]
                [@createRole 
                    mode=listMode
                    id=roleId
                    trustedServices=["lambda.amazonaws.com"]
                    managedArns=
                        (vpc?has_content && occurrence.VPCAccess)?then(
                            ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"],
                            ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
                        )
                /]
                
                [#if context.Policy?has_content]
                    [#assign policyId = formatDependentPolicyId(lambdaId, context)]
                    [@createPolicy
                        mode=listMode
                        id=policyId
                        name=context.Name
                        statements=context.Policy
                        roles=roleId
                    /]
                [/#if]

                [#assign linkPolicies = [] ]
                [#list context.Links as name,value]
                    [#assign linkPolicies += (value.Policy)![] ]
                [/#list]

                [#if linkPolicies?has_content]
                    [#assign policyId = formatDependentPolicyId(lambdaId, "links")]
                    [@createPolicy
                        mode=listMode
                        id=policyId
                        name="links"
                        statements=linkPolicies
                        roles=roleId
                    /]
                [/#if]
            [/#if]

            [#if deploymentSubsetRequired("lambda", true)]
                [#-- VPC config uses an ENI so needs an SG - create one without restriction --]
                [#if vpc?has_content && occurrence.VPCAccess]
                    [@createDependentSecurityGroup 
                        mode=listMode
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
                            mode=listMode
                            id=lambdaFunctionId
                            container=context +
                                {
                                    "Handler" : fn.Handler!occurrence.Handler,
                                    "RunTime" : fn.RunTime!occurrence.RunTime,
                                    "MemorySize" : fn.Memory!fn.MemorySize!occurrence.Memory,
                                    "Timeout" : fn.Timeout!occurrence.Timeout,
                                    "UseSegmentKey" : fn.UseSegmentKey!occurrence.UseSegmentKey,
                                    "Name" : lambdaFunctionName,
                                    "Description" : lambdaFunctionName
                                }
                            roleId=roleId
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
                [#assign containerListMode = listMode]
                [#include containerList?ensure_starts_with("/")]
            [/#if]
        [/#if]
    [/#list]
[/#if]
