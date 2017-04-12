[#ftl]
[#include "setContext.ftl"]

[#assign swaggerObject = swagger?eval]
[#assign integrationsObject = integrations?eval]
[#assign defaultValidation = "all"]
{
    "x-amazon-apigateway-request-validators" : {
        "all" : {
            "validateRequestBody" : true,
            "validateRequestParameters" : true
        },
        "params" : {
            "validateRequestBody" : false,
            "validateRequestParameters" : true
        },
        "body" : {
            "validateRequestBody" : true,
            "validateRequestParameters" : false
        },
        "none" : {
            "validateRequestBody" : false,
            "validateRequestParameters" : false
        }
    },
    "x-amazon-apigateway-request-validator" : "${integrationsObject.Validation ! defaultValidation}"
    [#if swaggerObject.paths??]
        ,"paths"  : {
            [#assign pathCount = 0]
            [#list swaggerObject.paths?keys as path]
                [#if pathCount > 0],[/#if]
                "${path}" : {
                    [#assign pathObject = swaggerObject.paths[path]]
                    [#assign verbCount = 0]
                    [#list pathObject?keys as verb]
                        [#if verbCount > 0],[/#if]
                        "${verb}" : {
                            [#assign verbObject = pathObject[verb]]
                            [#list integrationsObject.Patterns as pattern]
                                [#if path?matches(pattern.Path) && verb?matches(pattern.Verb)]
                                    [#switch pattern.Type]
                                        [#case "docker"]
                                        [#case "http_proxy"]
                                            "x-amazon-apigateway-integration" : {
                                                "type": "http_proxy"
                                                ,"uri" : "${r"https://${stageVariables." + pattern.Variable + r"}"}",
                                                "passthroughBehavior" : "when_no_match",
                                                "httpMethod" : "${verb}"
                                            }
                                            [#break]
                
                                        [#case "lambda"]
                                        [#case "aws_proxy"]
                                            "x-amazon-apigateway-integration" : {
                                                "type": "aws_proxy",
                                                [#-- "uri" : "${r"${stageVariables." + pattern.Variable + r"}"}", --]
                "uri" : "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${region}:${accountObject.AWSId}:function:${r"${stageVariables." + pattern.Variable + r"}"}/invocations",
                                                "passthroughBehavior" : "never",
                                                "httpMethod" : "POST"
                                            },
                                            "responses" : {}
                                            [#break]
                
                                        [#case "mock"]
                                            "x-amazon-apigateway-integration" : {
                                                "type": "mock"
                                            }
                                            [#break]
                                    [/#switch]
                                    [#if pattern.Validation??]
                                        ,"x-amazon-apigateway-request-validator" : "${pattern.Validation}"
                                    [/#if]
                                    [#break]
                                [/#if]
                            [/#list]
                        }
                        [#assign verbCount += 1]
                    [/#list]
                }
                [#assign pathCount += 1]
            [/#list]
        }
    [/#if]
}

