[#-- API Gateway --]
[#if component.APIGateway??]
    [#assign apigateway = component.APIGateway]
    [#if apigateway.Versions??]
        [#list apigateway.Versions?values as version]
            [#if version?is_hash && (version.Slices!component.Slices)?seq_contains(slice)]
                [#if resourceCount > 0],[/#if]
                [#switch applicationListMode]
                    [#case "definition"]
                        "apiX${tier.Id}X${component.Id}X${version.Id}" : {
                            "Type" : "AWS::ApiGateway::RestApi",
                            "Properties" : {
                                "BodyS3Location" : {
                                    "Bucket" : "${registryBucket}",
                                    "Key" : "swagger+integrations.yaml"
                                },
                                "Name" : "${productName}-${segmentName}-${tier.Name}-${component.Name}-${version.Name}"
                            }
                        },
                        "apiDeployX${tier.Id}X${component.Id}X${version.Id}" : {
                            "Type": "AWS::ApiGateway::Deployment",
                            "Properties": {
                                "RestApiId": { "Ref" : "apiX${tier.Id}X${component.Id}X${version.Id}" },
                                "StageName": "default"
                            },
                            "DependsOn" : "apiX${tier.Id}X${component.Id}X${version.Id}"
                        },
                        "apiStageX${tier.Id}X${component.Id}X${version.Id}" : {
                            "Type" : "AWS::ApiGateway::Stage",
                            "Properties" : {
                                "DeploymentId" : { "Ref" : "apiDeployX${tier.Id}X${component.Id}X${version.Id}" },
                                "RestApiId" : { "Ref" : "apiX${tier.Id}X${component.Id}X${version.Id}" },
                                "StageName" : "${version.Name}"
[#--
                                [#if version.Links??]
                                    ,"Variables" : {
                                        [#assign linkCount = 0]
                                        [#list version.Links?values as link]
                                            [#if link?is_hash]
                                                [#if linkCount > 0],[/#if]
                                                [#if link.Function??]
                                                    [@environmentVariable "${link.Name?upper_case}"
                                                        getKey("lambdaX" + link.Tier + "X" + link.Component + "X" + version.Id + "X" + link.Function + "Xarn")
                                                        "flat" /]

                                                [#else]
                                                    [@environmentVariable "${link.Name?upper_case}"
                                                        getKey("albX" + link.Tier + "X" + link.Component + "Xdns")
                                                        "flat" /]

                                                [/#if]
                                                [#assign linkCount += 1]
                                            [/#if]
                                        [/#list]
                                    }
                                [/#if]
--]
                            },
                            "DependsOn" : "apiDeployX${tier.Id}X${component.Id}X${version.Id}"
                        }
                        [#break]

                    [#case "outputs"]
                        "apiX${tier.Id}X${component.Id}X${version.Id}" : {
                            "Value" : { "Ref" : "apiX${tier.Id}X${component.Id}X${version.Id}" }
                        },
                        "apiX${tier.Id}X${component.Id}X${version.Id}Xroot" : {
                            "Value" : { "Fn::GetAtt" : ["apiX${tier.Id}X${component.Id}X${version.Id}", "RootResourceId"] }
                        }
                        [#break]

                [/#switch]
                [#assign resourceCount += 1]
            [/#if]
        [/#list]
    [/#if]
[/#if]
