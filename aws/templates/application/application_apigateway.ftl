[#-- API Gateway --]
[#if component.APIGateway??]
    [#assign apigateway = component.APIGateway]
    [#if apigateway.Versions??]
        [#list apigateway.Versions?values as version]
            [#if deploymentRequired(version, deploymentUnit)]
                [#assign apigatewayIdStem = formatId(componentIdStem, version.Id)]
                [#if resourceCount > 0],[/#if]
                [#switch applicationListMode]
                    [#case "definition"]
                        "${formatId("api", apigatewayIdStem)}" : {
                            "Type" : "AWS::ApiGateway::RestApi",
                            "Properties" : {
                                "BodyS3Location" : {
                                    "Bucket" : "${getRegistryEndPoint("swagger")}",
                                    "Key" : "${getRegistryPrefix("swagger")}${productId}/${deploymentUnit}/${buildCommit}/swagger.yaml"
                                },
                                "Name" : "${formatName(componentNameStem, version.Name)}"
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
                        [#assign stageName = version.Name]
                        "${formatId("apiStage", apigatewayIdStem)}" : {
                            "Type" : "AWS::ApiGateway::Stage",
                            "Properties" : {
                                "DeploymentId" : { "Ref" : "${formatId("apiDeploy", apigatewayIdStem)}" },
                                "RestApiId" : { "Ref" : "${formatId("api", apigatewayIdStem)}" },
                                "StageName" : "${stageName}"
                                [#if version.Links??]
                                    ,"Variables" : {
                                        [#assign linkCount = 0]
                                        [#list version.Links?values as link]
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
                                                    [#if (target.Lambda.Versions[version.Id].Functions)??]
                                                        [#list target.Lambda.Versions[version.Id].Functions?values as fn]
                                                            [#if fn?is_hash]
                                                                [#if linkCount > 0],[/#if]
                                                                [#assign stageVariable = link.Name?upper_case + "_" + fn.Name?upper_case + "_LAMBDA"]
                                                                [@environmentVariable stageVariable
                                                                    getKey("lambda", link.Tier, link.Component, version.Id, fn.Id)
                                                                    "apigateway" /]
                                                                [#assign linkCount += 1]
                                                            [/#if]
                                                        [/#list]
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
                        [#if version.Links??]
                            [#list version.Links?values as link]
                                [#if link?is_hash]
                                    [#if getComponent(link.Tier, link.Component)??]
                                        [#assign target = getComponent(link.Tier, link.Component)]
                                        [#if (target.Lambda.Versions[version.Id].Functions)??]
                                            [#list target.Lambda.Versions[version.Id].Functions?values as fn]
                                                [#if fn?is_hash]
                                                    ,"${formatId("apiLambdaPermission", apigatewayIdStem, link.Id, fn.Id)}" : {
                                                        "Type" : "AWS::Lambda::Permission",
                                                        "Properties" : {
                                                            "Action" : "lambda:InvokeFunction",
                                                            "FunctionName" : "${getKey("lambda", link.Tier, link.Component, version.Id, fn.Id)}",
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
            [/#if]
        [/#list]
    [/#if]
[/#if]
