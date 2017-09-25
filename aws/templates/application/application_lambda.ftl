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

            [#containerId =
                occurrence.Container?has_content?then(
                    occurrence.Container,
                    getComponentId(component)                            
                ) 
            [#local currentContainer = 
                {
                    "Id" : containerId,
                    "Name" : containerId,
                    "Environment" :
                        {
                            "TEMPLATE_TIMESTAMP" .now?iso_utc,
                            "ENVIRONMENT" : environmentName,
                            "REQUEST_REFERENCE" : requestReference,
                            "CONFIGURATION_REFERENCE" : configurationReference,
                            "APPDATA_BUCKET" : dataBucket,
                            "APPDATA_PREFIX" : getAppDataFilePrefix(),
                            "OPSDATA_BUCKET" : operationsBucket,
                            "APPSETTINGS_PREFIX" : getAppSettingsFilePrefix(),
                            "CREDENTIALS_PREFIX" : getCredentialsFilePrefix(),
                            "APP_RUN_MODE" : getContainerMode(container),
                        } +
                        buildCommit?has_content?then(
                            {
                                "BUILD_REFERENCE" : buildCommit
                            },
                            {}
                        ) +
                        appReference?has_content?then(
                            {
                                "APP_REFERENCE" : appReference
                            }
                }
            ]
        
            [#-- Add in container specifics including override of defaults --]
            [#assign containerListMode = "model"]
            [#assign containerId = formatContainerFragmentId(occurrence, currentContainer)]
            [#include containerList]
    
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
                
                [#if currentContainer.Policy?has_content]
                    [#assign policyId = formatDependentPolicyId(lambda, currentContainer)]
                    [@createPolicy
                        mode=applicationListMode
                        id=policyId
                        name=currentContainer.Name
                        statements=currentContainer.Policy
                        role=roleId
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
                                
                        [#assign memorySize = fn.MemorySize!occurrence.MemorySize]
                        [#assign timeout = fn.Timeout!occurrence.Timeout]
                        [#assign useSegmentKey = fn.UseSegmentKey!occurrence.UseSegmentKey]
                        [@cfTemplate
                            mode=applicationListMode
                            id=lambdaFunctionId
                            type="AWS::Lambda::Function"
                            properties=
                                {
                                    "Code" : {
                                        "S3Bucket" : getRegistryEndPoint("lambda"),
                                        "S3Key" : 
                                            formatRelativePath(
                                                getRegistryPrefix("lambda") + productName,
                                                buildDeploymentUnit,
                                                buildCommit,
                                                "lambda.zip"
                                            )
                                    },                                            
                                    "FunctionName" : lambdaFunctionName,
                                    "Description" : lambdaFunctionName,
                                    "Handler" : fn.Handler!occurrence.Handler,
                                    "Role" : getReference(roleId, ARN_ATTRIBUTE_TYPE),
                                    "Runtime" : fn.RunTime!occurrence.RunTime
                                    }
                                } + 
                                currentContainer.Environment?then(
                                    {
                                        "Environment" : currentContainer.Environment
                                    } +
                                    {}
                                ) +
                                (memorySize > 0)?then(
                                    {
                                        "MemorySize" : memorySize
                                    },
                                    {}
                                ) +
                                (time > 0)?then(
                                    {
                                        "Timeout" : timeout
                                    },
                                    {}
                                ) +
                                useSegmentKey?then(
                                    {
                                        "KmsKeyArn" : getReference(formatSegmentCMKArnId())
                                    },
                                    {}
                                ) + 
                                (vpc?has_content && occurrence.VPCAccess)?then(
                                    {
                                        "VpcConfig" : {
                                            "SecurityGroupIds" : [ 
                                                getReference(formatDependentSecurityGroupId(lambdaId))
                                            ],
                                            "SubnetIds" : getSubnets(tier)
                                        }
                                    },
                                    {}
                                )
                            dependencies=roleId
                        /]
                    [/#if]
                [/#list]
            [/#if]
        [/#if]
    [/#list]
[/#if]
