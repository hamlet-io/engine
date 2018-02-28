[#if componentType = "lambda"]

    [#list requiredOccurrences(
            getOccurrences(component, tier, component),
            deploymentUnit) as occurrence ]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]

        [#if configuration.Functions?is_hash]
        
            [#assign lambdaId = formatLambdaId(
                                    tier,
                                    component,
                                    occurrence)]
            [#assign lambdaName = formatLambdaName(
                                    tier,
                                    component,
                                    occurrence)]

            [#assign containerId =
                configuration.Container?has_content?then(
                    configuration.Container,
                    getComponentId(component)                            
                ) ]
            [#assign context = 
                {
                    "Id" : containerId,
                    "Name" : containerId,
                    "Instance" : core.Instance.Id,
                    "Version" : core.Version.Id,
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
                    "Links" : getLinkTargets(occurrence),
                    "DefaultLinkVariables" : true
                }
            ]

            [#if deploymentSubsetRequired("lambda", true)]
                [#list configuration.Links?values as link]
                    [#if link?is_hash]
                        [#assign linkTarget = getLinkTarget(occurrence, link) ]
                        [@cfDebug listMode linkTarget false /]

                        [#assign linkTargetCore = linkTarget.Core ]
                        [#assign linkTargetConfiguration = linkTarget.Configuration ]
                        [#assign linkTargetResources = linkTarget.State.Resources ]

                        [#assign policyId = formatDependentPolicyId(
                                                lambdaId, 
                                                link.Name)]

                        [#assign lamdbaFunctionPolicies = [] ]

                        [#list configuration.Functions?values as fn]
                            [#if fn?is_hash]
                                [#assign fnId =
                                    formatLambdaFunctionId(
                                        tier,
                                        component,
                                        fn,
                                        occurrence)]
                                [#assign fnName =
                                    formatLambdaFunctionName(
                                        tier,
                                        component,
                                        occurrence,
                                        fn)]

                                [#switch linkTargetCore.Type!""]
                                    [#case "userpool"] 
      
                                        [#assign lambdaFunctionPolicy = getPolicyStatement(
                                                    "lambda:InvokeFunction",
                                                    formatLambdaArn(fnId)    
                                                )]
                                        [#assign lamdbaFunctionPolicies = lamdbaFunctionPolicies + [lambdaFunctionPolicy]]
                                        [#break]

                                    [#case "apigateway" ]
                                        [#assign apiId = linkTargetResources["primary"].Id ]
                                        [#if getExistingReference(apiId)?has_content]
                                            [@cfResource
                                                mode=listMode
                                                id=
                                                    formatAPIGatewayLambdaPermissionId(
                                                        linkTargetCore.Tier,
                                                        linkTargetCore.Component,
                                                        link,
                                                        fn,
                                                        linkTarget)
                                                type="AWS::Lambda::Permission"
                                                properties=
                                                    {
                                                        "Action" : "lambda:InvokeFunction",
                                                        "FunctionName" : fnName,
                                                        "Principal" : "apigateway.amazonaws.com",
                                                        "SourceArn" : formatInvokeApiGatewayArn(apiId)
                                                    }
                                                outputs={}
                                            /]
                                        [/#if]
                                        [#break]
                                [/#switch]
                            [/#if]
                        [/#list]
        
                        [#if lamdbaFunctionPolicies?has_content ]
                            [@createPolicy 
                                mode=listMode
                                id=policyId
                                name=lambdaName
                                statements=lamdbaFunctionPolicies
                                roles=formatDependentIdentityPoolAuthRoleId(
                                        formatIdentityPoolId(link.Tier, link.Component))
                            /]
                        [/#if]
                    [/#if]
                [/#list]
            [/#if]

            [#-- Add in container specifics including override of defaults --]
            [#assign containerListMode = "model"]
            [#assign containerId = formatContainerFragmentId(occurrence, context)]
            [#include containerList?ensure_starts_with("/")]

            [#if context.DefaultLinkVariables]
                [#assign context = addDefaultLinkVariablesToContext(context) ]
            [/#if]

            [#assign roleId = formatDependentRoleId(lambdaId)]
            [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(roleId)]
                [#-- Create a role under which the function will run and attach required policies --]
                [#-- The role is mandatory though there may be no policies attached to it --]
                [@createRole 
                    mode=listMode
                    id=roleId
                    trustedServices=["lambda.amazonaws.com"]
                    managedArns=
                        (vpc?has_content && configuration.VPCAccess)?then(
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
                [#if vpc?has_content && configuration.VPCAccess]
                    [@createDependentSecurityGroup 
                        mode=listMode
                        tier=tier
                        component=component
                        resourceId=lambdaId
                        resourceName=lambdaName  /]
                [/#if]

                [#list configuration.Functions?values as fn]
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
                                    "Handler" : fn.Handler!configuration.Handler,
                                    "RunTime" : fn.RunTime!configuration.RunTime,
                                    "MemorySize" : fn.Memory!fn.MemorySize!configuration.Memory,
                                    "Timeout" : fn.Timeout!configuration.Timeout,
                                    "UseSegmentKey" : fn.UseSegmentKey!configuration.UseSegmentKey,
                                    "Name" : lambdaFunctionName,
                                    "Description" : lambdaFunctionName
                                }
                            roleId=roleId
                            securityGroupIds=
                                (vpc?has_content && configuration.VPCAccess)?then(
                                    formatDependentSecurityGroupId(lambdaId),
                                    []
                                )
                            subnetIds=
                                (vpc?has_content && configuration.VPCAccess)?then(
                                    getSubnets(tier, false),
                                    []
                                )
                            dependencies=roleId
                        /]
                        
                        [#list (fn.Schedules!{})?values as schedule ]
                            [#if schedule?is_hash ]

                                [#assign eventRuleId =
                                    formatEventRuleId(
                                        tier,
                                        component,
                                        fn,
                                        occurrence,
                                        schedule.Id
                                        )]
            
                                [#assign lambdaPermissionId =
                                    formatLambdaPermissionId(
                                        tier,
                                        component,
                                        fn,
                                        occurrence,
                                        schedule.Id
                                        )]
                                
                                [@createScheduleEventRule
                                    mode=listMode
                                    id=eventRuleId
                                    targetId=lambdaFunctionId
                                    enabled=schedule.Enabled
                                    scheduleExpression=schedule.Expression
                                    path=schedule.InputPath
                                    dependencies=lambdaFunctionId
                                /]

                                [@createLambdaPermission
                                    mode=listMode
                                    id=lambdaPermissionId
                                    targetId=lambdaFunctionId
                                    sourcePrincipal="events.amazonaws.com"
                                    sourceId=eventRuleId
                                    dependencies=eventRuleId
                                /]
                            [/#if]
                        [/#list]
                    [/#if]
                [/#list]
                
                [#-- Pick any extra macros in the container fragment --]
                [#assign containerListMode = listMode]
                [#include containerList?ensure_starts_with("/")]
            [/#if]
        [/#if]
    [/#list]
[/#if]
