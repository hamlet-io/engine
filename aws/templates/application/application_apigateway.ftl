[#-- API Gateway --]
[#if component.APIGateway??]
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
        [#assign apigatewayIdStem = formatId(componentIdStem,
                                                apigatewayInstance.Internal.VersionId,
                                                apigatewayInstance.Internal.InstanceId)]
        [#if resourceCount > 0],[/#if]
        [#switch applicationListMode]
            [#case "definition"]
                "${formatId("api", apigatewayIdStem)}" : {
                    "Type" : "AWS::ApiGateway::RestApi",
                    "Properties" : {
                        "BodyS3Location" : {
                            "Bucket" : "${getRegistryEndPoint("swagger")}",
                            "Key" : "${getRegistryPrefix("swagger")}${productName}/${deploymentUnit}/${buildCommit}/swagger.json"
                        },
                        "Name" : "${formatName(componentNameStem,
                                                apigatewayInstance.Internal.VersionName,
                                                apigatewayInstance.Internal.InstanceName)}"
                    }
                },
                "${formatId("apiDeploy", apigatewayIdStem)}" : {
                    "Type": "AWS::ApiGateway::Deployment",
                    "Properties": {
                        "RestApiId": { "Ref" : "${formatId("api", apigatewayIdStem)}" },
                        "StageName": "default"
                    },
                    "DependsOn" : "${formatId("api", apigatewayIdStem)}"
                },
                [#assign stageName = apigatewayInstance.Internal.VersionName]
                "${formatId("apiStage", apigatewayIdStem)}" : {
                    "Type" : "AWS::ApiGateway::Stage",
                    "Properties" : {
                        "DeploymentId" : { "Ref" : "${formatId("apiDeploy", apigatewayIdStem)}" },
                        "RestApiId" : { "Ref" : "${formatId("api", apigatewayIdStem)}" },
                        "StageName" : "${stageName}"
                        [#if apigatewayInstance.Links??]
                            ,"Variables" : {
                                [#assign linkCount = 0]
                                [#list apigatewayInstance.Links?values as link]
                                    [#if link?is_hash]
                                        [#if getComponent(link.Tier, link.Component)??]
                                            [#assign target = getComponent(link.Tier, link.Component)]
                                            [#if target.ALB?? || target.ELB??]
                                                [#if linkCount > 0],[/#if]
                                                [#assign stageVariable = link.Name?upper_case + "_DOCKER" ]
                                                [@environmentVariable stageVariable
                                                    getKey("alb", link.Tier, link.Component, "dns")
                                                    "apigateway" /]
                                                [#assign linkCount += 1]
                                            [/#if]
                                            [#if target.Lambda??]
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
                                                            [#-- In order that lambda code doesn't have to be deployed before the api gateway is
                                                                 instantiated, construct the function name from constituent parts rather than looking up
                                                                 via
                                                                            getReference("lambda", link.Tier, link.Component,
                                                                            apigatewayInstance.Internal.VersionId,
                                                                            apigatewayInstance.Internal.InstanceId,
                                                                            fn.Id)
"arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${region}:${accountObject.AWSId}:function:${fnName}/invocations"

                                                                --]
                                                            [#assign fnName = formatName(
                                                                        productName,
                                                                        segmentName,
                                                                        getTier(link.Tier).Name,
                                                                        target.Name,
                                                                        apigatewayInstance.Internal.VersionName,
                                                                        apigatewayInstance.Internal.InstanceName,
                                                                        fn.Name)]
                                                            [@environmentVariable
                                                                stageVariable
                                                                "${fnName}"
                                                                "apigateway" /]
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
                    "DependsOn" : "${formatId("apiDeploy", apigatewayIdStem)}"
                }
                [#-- Include access to lambda functions if required --]
                [#if apigatewayInstance.Links??]
                    [#list apigatewayInstance.Links?values as link]
                        [#if link?is_hash]
                            [#if getComponent(link.Tier, link.Component)??]
                                [#assign target = getComponent(link.Tier, link.Component)]

                                [#if target.Lambda??]
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
                                                [#assign fnName = formatName(
                                                            productName,
                                                            segmentName,
                                                            getTier(link.Tier).Name,
                                                            target.Name,
                                                            apigatewayInstance.Internal.VersionName,
                                                            apigatewayInstance.Internal.InstanceName,
                                                            fn.Name)]
                                                ,"${formatId("apiLambdaPermission", apigatewayIdStem, link.Id, fn.Id)}" : {
                                                    "Type" : "AWS::Lambda::Permission",
                                                    "Properties" : {
                                                        "Action" : "lambda:InvokeFunction",
                                                        "FunctionName" : [@reference fnName /],
                                                        "Principal" : "apigateway.amazonaws.com",
                                                        "SourceArn" : {
                                                            "Fn::Join" : [
                                                                "",
                                                                [
                                                                    "arn:aws:execute-api:",
                                                                    "${regionId}", ":",
                                                                    {"Ref" : "AWS::AccountId"}, ":",                    
                                                                    { "Ref" : "${formatId("api", apigatewayIdStem)}" },
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
                "${formatId("api", apigatewayIdStem)}" : {
                    "Value" : { "Ref" : "${formatId("api", apigatewayIdStem)}" }
                },
                "${formatId("api", apigatewayIdStem, "root")}" : {
                    "Value" : { "Fn::GetAtt" : ["${formatId("api", apigatewayIdStem)}", "RootResourceId"] }
                }
                [#break]

        [/#switch]
        [#assign resourceCount += 1]
    [/#list]
[/#if]
