[#if componentType = "lambda"]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence ]

        [@cfDebug listMode occurrence false /]

        [#list occurrence.Occurrences as fn]
            [#assign core = fn.Core ]
            [#assign configuration = fn.Configuration ]
            [#assign resources = fn.State.Resources ]
    
            [#assign fnId = resources["function"].Id ]
            [#assign fnName = resources["function"].Name ]

            [#assign containerId =
                configuration.Container?has_content?then(
                    configuration.Container,
                    getComponentId(core.Component)
                ) ]
            [#assign context = 
                {
                    "Id" : containerId,
                    "Name" : containerId,
                    "Instance" : core.Instance.Id,
                    "Version" : core.Version.Id,
                    "Environment" :
                        standardEnvironment(core.Tier, core.Component, fn, "WEB"),
                    "S3Bucket" : getRegistryEndPoint("lambda"),
                    "S3Key" : 
                        formatRelativePath(
                            getRegistryPrefix("lambda") + productName,
                            buildDeploymentUnit,
                            buildCommit,
                            "lambda.zip"
                        ),
                    "Links" : getLinkTargets(fn),
                    "DefaultLinkVariables" : true
                }
            ]

            [#if deploymentSubsetRequired("lambda", true)]
                [#list context.Links as linkName,linkTarget]
                    
                    [#assign linkTargetCore = linkTarget.Core ]
                    [#assign linkTargetConfiguration = linkTarget.Configuration ]
                    [#assign linkTargetResources = linkTarget.State.Resources ]
                    [#assign linkTargetRoles = linkTarget.State.Roles ]
                    [#assign linkDirection = linkTarget.Direction ]

                    [#switch linkTargetCore.Type!""]
                        [#case USERPOOL_COMPONENT_TYPE] 
                            [#if linkTargetResources[USERPOOL_COMPONENT_TYPE].Deployed &&
                                    (linkDirection == "inbound")]
                                [@createLambdaPermission
                                    mode=listMode
                                    id=formatLambdaPermissionId(fn, "link", linkName)
                                    targetId=fnId
                                    source=linkTargetRoles.Inbound["invoke"]
                                /]
                            [/#if]
                        [#break]

                        [#case "apigateway" ]
                            [#if linkTargetResources["gateway"].Deployed &&
                                    (linkDirection == "inbound")]
                                [@createLambdaPermission
                                    mode=listMode
                                    id=formatLambdaPermissionId(fn, "link", linkName)
                                    targetId=fnId
                                    source=linkTargetRoles.Inbound["invoke"]
                                /]
                            [/#if]
                        [#break]
                    [/#switch]    
                [/#list]
            [/#if]

            [#-- Add in container specifics including override of defaults --]
            [#assign containerListMode = "model"]
            [#assign containerId = formatContainerFragmentId(occurrence, context)]
            [#include containerList?ensure_starts_with("/")]

            [#if context.DefaultLinkVariables]
                [#assign context = addDefaultLinkVariablesToContext(context) ]
            [/#if]

            [#assign roleId = formatDependentRoleId(fnId)]
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
                    [#assign policyId = formatDependentPolicyId(fnId)]
                    [@createPolicy
                        mode=listMode
                        id=policyId
                        name=context.Name
                        statements=context.Policy
                        roles=roleId
                    /]
                [/#if]

                [#assign linkPolicies = getLinkTargetsOutboundRoles(context.Links) ]

                [#if linkPolicies?has_content]
                    [#assign policyId = formatDependentPolicyId(fnId, "links")]
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
                        resourceId=fnId
                        resourceName=formatName("lambda", fnName) /]
                [/#if]

                [@createLambdaFunction
                    mode=listMode
                    id=fnId
                    container=context +
                        {
                            "Handler" : configuration.Handler,
                            "RunTime" : configuration.RunTime,
                            "MemorySize" : configuration.Memory,
                            "Timeout" : configuration.Timeout,
                            "UseSegmentKey" : configuration.UseSegmentKey,
                            "Name" : fnName,
                            "Description" : fnName
                        }
                    roleId=roleId
                    securityGroupIds=
                        (vpc?has_content && configuration.VPCAccess)?then(
                            formatDependentSecurityGroupId(fnId),
                            []
                        )
                    subnetIds=
                        (vpc?has_content && configuration.VPCAccess)?then(
                            getSubnets(core.Tier, false),
                            []
                        )
                    dependencies=roleId
                /]
                
                [#list configuration.Schedules?values as schedule ]
                    [#assign scheduleRuleId = formatEventRuleId(fn, "schedule", schedule.Id) ]

                    [@createScheduleEventRule
                        mode=listMode
                        id=scheduleRuleId
                        targetId=fnId
                        enabled=schedule.Enabled
                        scheduleExpression=schedule.Expression
                        path=schedule.InputPath
                        dependencies=fnId
                    /]

                    [@createLambdaPermission
                        mode=listMode
                        id=formatLambdaPermissionId(fn, "schedule", schedule.Id)
                        targetId=fnId
                        sourcePrincipal="events.amazonaws.com"
                        sourceId=scheduleRuleId
                        dependencies=scheduleRuleId
                    /]
                [/#list]
                
                [#-- Pick any extra macros in the container fragment --]
                [#assign containerListMode = listMode]
                [#include containerList?ensure_starts_with("/")]
            [/#if]
        [/#list]
    [/#list]
[/#if]
