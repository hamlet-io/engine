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
                                            "IdExtensions" : [
                                                version.Id,
                                                (apigatewayInstance.Id == "default")?
                                                    string(
                                                        "",
                                                        apigatewayInstance.Id)],
                                            "NameExtensions" : [
                                                version.Name,
                                                (apigatewayInstance.Id == "default")?
                                                    string(
                                                        "",
                                                        apigatewayInstance.Name)],
                                            "VersionId" : version.Id,
                                            "StageName" : version.Name,
                                            "InstanceIdRef" : apigatewayInstance.Id
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
                                    "IdExtensions" : [version.Id],
                                    "NameExtensions" : [version.Name],
                                    "VersionId" : version.Id,
                                    "StageName" : version.Name
                                }
                            }
                        ] 
                    ]
                [/#if]
            [/#if]
        [/#list]
    [/#if]
    
    [#-- Non-repeating text to ensure deploy happens every time --]
    [#assign noise = (.now?long / 1000)?round?string.computer]

    [#list apigatewayInstances as apigatewayInstance]
        [#assign apiId    = formatAPIGatewayId(
                                tier,
                                component,
                                apigatewayInstance)]
        [#assign deployId = formatAPIGatewayDeployId(
                                tier,
                                component,
                                apigatewayInstance,
                                noise)]
        [#assign stageId  = formatAPIGatewayStageId(
                                tier,
                                component,
                                apigatewayInstance)]

        [#if resourceCount > 0],[/#if]
        [#switch applicationListMode]
            [#case "definition"]
                "${apiId}" : {
                    "Type" : "AWS::ApiGateway::RestApi",
                    "Properties" : {
                        "BodyS3Location" : {
                            "Bucket" : "${getRegistryEndPoint("swagger")}",
                            "Key" : "${getRegistryPrefix("swagger")}${productName}/${buildDeploymentUnit}/${buildCommit}/swagger.json"
                        },
                        "Name" : "${formatComponentFullName(
                                        tier,
                                        component,
                                        apigatewayInstance)}"
                    }
                },
                "${deployId}" : {
                    "Type": "AWS::ApiGateway::Deployment",
                    "Properties": {
                        "RestApiId": { "Ref" : "${apiId}" },
                        "StageName": "default"
                    },
                    "DependsOn" : "${apiId}"
                },
                [#assign stageName = apigatewayInstance.Internal.StageName]
                "${stageId}" : {
                    "Type" : "AWS::ApiGateway::Stage",
                    "Properties" : {
                        "DeploymentId" : { "Ref" : "${deployId}" },
                        "RestApiId" : { "Ref" : "${apiId}" },
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
                                                    getKey(formatALBDNSId(
                                                            targetTier,
                                                            targetComponent))
                                                    "apigateway" /]
                                                [#assign linkCount += 1]
                                            [/#if]
                                            [#if targetComponentType == "lambda"]
                                                [#assign lambdaInstance = targetComponent.Lambda ]
                                                [#assign lambdaFunctions = (lambdaInstance.Functions)!"unknown" ]
                                                [#if targetComponent.Lambda.Versions?? ]
                                                    [#assign lambdaInstance = targetComponent.Lambda.Versions[apigatewayInstance.Internal.VersionId] ]
                                                    [#assign lambdaFunctions = (lambdaInstance.Functions)!lambdaFunctions ]
                                                    [#if targetComponent.Lambda.Versions[apigatewayInstance.Internal.VersionId].Instances??]
                                                        [#assign lambdaInstance = targetComponent.Lambda.Versions[apigatewayInstance.Internal.VersionId].Instances[apigatewayInstance.Internal.InstanceIdRef] ]
                                                        [#assign lambdaFunctions = (lambdaInstance.Functions)!lambdaFunctions ]
                                                    [/#if]
                                                [/#if]

                                                [#if lambdaFunctions?is_hash]
                                                    [#list lambdaFunctions?values as fn]
                                                        [#if fn?is_hash]
                                                            [#if linkCount > 0],[/#if]
                                                            [#assign stageVariable = link.Name?upper_case + "_" + fn.Name?upper_case + "_LAMBDA"]
                                                            [#assign fnName = formatLambdaFunctionName(
                                                                                        targetTier,
                                                                                        targetComponent,
                                                                                        apigatewayInstance,
                                                                                        fn)]
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
                    "DependsOn" : "${deployId}"
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
                                    [#assign lambdaInstance = targetComponent.Lambda ]
                                    [#assign lambdaFunctions = (lambdaInstance.Functions)!"unknown" ]
                                    [#if targetComponent.Lambda.Versions?? ]
                                        [#assign lambdaInstance = targetComponent.Lambda.Versions[apigatewayInstance.Internal.VersionId] ]
                                        [#assign lambdaFunctions = (lambdaInstance.Functions)!lambdaFunctions ]
                                        [#if targetComponent.Lambda.Versions[apigatewayInstance.Internal.VersionId].Instances??]
                                            [#assign lambdaInstance = targetComponent.Lambda.Versions[apigatewayInstance.Internal.VersionId].Instances[apigatewayInstance.Internal.InstanceIdRef] ]
                                            [#assign lambdaFunctions = (lambdaInstance.Functions)!lambdaFunctions ]
                                        [/#if]
                                    [/#if]

                                    [#if lambdaFunctions?is_hash]
                                        [#list lambdaFunctions?values as fn]
                                            [#if fn?is_hash]
                                                [#assign fnName = formatLambdaFunctionName(
                                                                            targetTier,
                                                                            targetComponent,
                                                                            apigatewayInstance,
                                                                            fn)]
                                                ,"${formatAPIGatewayLambdaPermissionId(
                                                        tier,
                                                        component,
                                                        link,
                                                        fn,
                                                        apigatewayInstance)}" : {
                                                    "Type" : "AWS::Lambda::Permission",
                                                    "Properties" : {
                                                        "Action" : "lambda:InvokeFunction",
                                                        "FunctionName" : "${fnName}",
                                                        "Principal" : "apigateway.amazonaws.com",
                                                        "SourceArn" : {
                                                            "Fn::Join" : [
                                                                "",
                                                                [
                                                                    "arn:aws:execute-api:",
                                                                    "${regionId}", ":",
                                                                    {"Ref" : "AWS::AccountId"}, ":",                    
                                                                    { "Ref" : "${apiId}" },
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
                [@output apiId /],
                [@outputRoot apiId /]
                [#break]

        [/#switch]
        [#assign resourceCount += 1]
    [/#list]
[/#if]
