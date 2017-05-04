[#-- API Gateway --]
[#if componentType == "apigateway"]
    [#assign apigateway = component.APIGateway]
    [#assign apigatewayInstances=[] ]
    [#if apigateway.Versions??]
        [#list apigateway.Versions?values as version]
            [#if deploymentRequired(version, deploymentUnit)]  
                [#if version.Instances??]
                    [#list version.Instances?values as apigatewayInstance]
                        [#if deploymentRequired(apigatewayInstance, deploymentUnit)]
                            [#assign apigatewayInstances += [apigatewayInstance +
                                    {
                                        "Internal" : {
                                            "VersionId" : version.Id,
                                            "VersionName" : version.Name,
                                            "InstanceIdRef" : apigatewayInstance.Id,
                                            "InstanceId" : (apigatewayInstance.Id == "default")?string("",apigatewayInstance.Id),
                                            "InstanceName" : (apigatewayInstance.Id == "default")?string("",apigatewayInstance.Name)
                                        }
                                    }
                                ] 
                            ]
                        [/#if]
                    [/#list]
                [#else]
                    [#assign apigatewayInstances += [version +
                            {
                                "Internal" : {
                                    "VersionId" : version.Id,
                                    "VersionName" : version.Name,
                                    "InstanceId" : "",
                                    "InstanceName" : ""
                                }
                            }
                        ] 
                    ]
                [/#if]
            [/#if]
        [/#list]
    [/#if]

    [#list apigatewayInstances as apigatewayInstance]
        [#assign apiResourceId    = formatAPIGatewayAPIResourceId(
                                        tier,
                                        component,
                                        apigatewayInstance)]
        [#assign deployResourceId = formatAPIGatewayDeployResourceId(
                                        tier,
                                        component,
                                        apigatewayInstance)]
        [#assign stageResourceId  = formatAPIGatewayDeployResourceId(
                                        tier,
                                        component,
                                        apigatewayInstance)]
        [#if resourceCount > 0],[/#if]
        [#switch applicationListMode]
            [#case "definition"]
                "${apiResourceId}" : {
                    "Type" : "AWS::ApiGateway::RestApi",
                    "Properties" : {
                        "BodyS3Location" : {
                            "Bucket" : "${getRegistryEndPoint("swagger")}",
                            "Key" : "${getRegistryPrefix("swagger")}${productName}/${buildDeploymentUnit}/${buildCommit}/swagger.json"
                        },
                        "Name" : "${formatComponentFullNameStem(
                                        tier,
                                        component,
                                        apigatewayInstance.Internal.VersionName,
                                        apigatewayInstance.Internal.InstanceName)}"
                    }
                },
                "${deployResourceId}" : {
                    "Type": "AWS::ApiGateway::Deployment",
                    "Properties": {
                        "RestApiId": { "Ref" : "${apiResourceId}" },
                        "StageName": "default"
                    },
                    "DependsOn" : "${apiResourceId}"
                },
                [#assign stageName = apigatewayInstance.Internal.VersionName]
                "${stageResourceId}" : {
                    "Type" : "AWS::ApiGateway::Stage",
                    "Properties" : {
                        "DeploymentId" : { "Ref" : "${deployResourceId}" },
                        "RestApiId" : { "Ref" : "${apiResourceId}" },
                        "StageName" : "${stageName}"
                        [#if apigatewayInstance.Links??]
                            ,"Variables" : {
                                [#assign linkCount = 0]
                                [#list apigatewayInstance.Links?values as link]
                                    [#if link?is_hash]
                                        [#if getComponent(link.Tier, link.Component)??]
                                            [#assign targetTier = getTier(link.Tier)]
                                            [#assign targetComponent = getComponent(link.Tier, link.Component)]
                                            [#assign targetComponentType = getComponentType(targetComponent)]
                                            [#if (targetComponentType == "alb") || (targetComponentType == "elb")]
                                                [#if linkCount > 0],[/#if]
                                                [#assign stageVariable = link.Name?upper_case + "_DOCKER" ]
                                                [@environmentVariable stageVariable
                                                    getKey(formatALBResourceDNSId(
                                                            targetTier,
                                                            targetComponent))
                                                    "apigateway" /]
                                                [#assign linkCount += 1]
                                            [/#if]
                                            [#if targetComponentType == "lambda"]
                                                [#assign lambdaInstance = target.Lambda ]
                                                [#assign lambdaFunctions = (lambdaInstance.Functions)!"unknown" ]
                                                [#if target.Lambda.Versions?? ]
                                                    [#assign lambdaInstance = target.Lambda.Versions[apigatewayInstance.Internal.VersionId] ]
                                                    [#assign lambdaFunctions = (lambdaInstance.Functions)!lambdaFunctions ]
                                                    [#if target.Lambda.Versions[apigatewayInstance.Internal.VersionId].Instances??]
                                                        [#assign lambdaInstance = target.Lambda.Versions[apigatewayInstance.Internal.VersionId].Instances[apigatewayInstance.Internal.InstanceIdRef] ]
                                                        [#assign lambdaFunctions = (lambdaInstance.Functions)!lambdaFunctions ]
                                                    [/#if]
                                                [/#if]

                                                [#if lambdaFunctions?is_hash]
                                                    [#list lambdaFunctions?values as fn]
                                                        [#if fn?is_hash]
                                                            [#if linkCount > 0],[/#if]
                                                            [#assign stageVariable = link.Name?upper_case + "_" + fn.Name?upper_case + "_LAMBDA"]
                                                            [#assign fnName = getKey(formatLambdaFunctionResourceId(
                                                                                        targetTier,
                                                                                        targetComponent,
                                                                                        fn,
                                                                                        apigatewayInstance.Internal.VersionId,
                                                                                        apigatewayInstance.Internal.InstanceId))]
                                                            [@environmentVariable stageVariable fnName "apigateway" /]
                                                            [#assign linkCount += 1]
                                                        [/#if]
                                                    [/#list]
                                                [/#if]
                                            [/#if]
                                        [/#if]
                                    [/#if]
                                [/#list]
                            }
                        [/#if]
                    },
                    "DependsOn" : "${deployResourceId}"
                }
                [#-- Include access to lambda functions if required --]
                [#if apigatewayInstance.Links?? ]
                    [#list apigatewayInstance.Links?values as link]
                        [#if link?is_hash]
                            [#if getComponent(link.Tier, link.Component)??]
                                [#assign targetTier = getTier(link.Tier)]
                                [#assign targetComponent = getComponent(link.Tier, link.Component)]
                                [#assign targetComponentType = getComponentType(targetComponent)]
                                [#if targetComponentType == "lambda"]
                                    [#assign lambdaInstance = target.Lambda ]
                                    [#assign lambdaFunctions = (lambdaInstance.Functions)!"unknown" ]
                                    [#if target.Lambda.Versions?? ]
                                        [#assign lambdaInstance = target.Lambda.Versions[apigatewayInstance.Internal.VersionId] ]
                                        [#assign lambdaFunctions = (lambdaInstance.Functions)!lambdaFunctions ]
                                        [#if target.Lambda.Versions[apigatewayInstance.Internal.VersionId].Instances??]
                                            [#assign lambdaInstance = target.Lambda.Versions[apigatewayInstance.Internal.VersionId].Instances[apigatewayInstance.Internal.InstanceIdRef] ]
                                            [#assign lambdaFunctions = (lambdaInstance.Functions)!lambdaFunctions ]
                                        [/#if]
                                    [/#if]

                                    [#if lambdaFunctions?is_hash]
                                        [#list lambdaFunctions?values as fn]
                                            [#if fn?is_hash]
                                                [#-- See comment above re formatting function name --]
                                                [#assign fnName = getKey(formatLambdaFunctionResourceId(
                                                                            targetTier,
                                                                            targetComponent,
                                                                            apigatewayInstance,
                                                                            fn))]
                                                ,"${formatAPIGatewayLambdaPermissionResourceId(
                                                        tier,
                                                        component,
                                                        apiGateway,
                                                        link,
                                                        fn)}" : {
                                                    "Type" : "AWS::Lambda::Permission",
                                                    "Properties" : {
                                                        "Action" : "lambda:InvokeFunction",
                                                        "FunctionName" : [@createReference fnName /],
                                                        "Principal" : "apigateway.amazonaws.com",
                                                        "SourceArn" : {
                                                            "Fn::Join" : [
                                                                "",
                                                                [
                                                                    "arn:aws:execute-api:",
                                                                    "${regionId}", ":",
                                                                    {"Ref" : "AWS::AccountId"}, ":",                    
                                                                    { "Ref" : "${apiResourceId}" },
                                                                    "/${stageName}/*"
                                                                ]
                                                            ]
                                                        }
                                                    }
                                                }
                                            [/#if]
                                        [/#list]
                                    [/#if]
                                [/#if]
                            [/#if]
                        [/#if]
                    [/#list]
                [/#if]
                [#break]

            [#case "outputs"]
                "${apiResourceId}" : {
                    "Value" : { "Ref" : "${apiResourceId}" }
                },
                "${formatResourceAttributeId(apiResourceId, "root")}" : {
                    "Value" : { "Fn::GetAtt" : ["${apiResourceId}", "RootResourceId"] }
                }
                [#break]

        [/#switch]
        [#assign resourceCount += 1]
    [/#list]
[/#if]
