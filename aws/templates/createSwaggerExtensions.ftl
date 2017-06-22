[#ftl]
[#include "setContext.ftl"]

[#assign swaggerObject = swagger?eval]
[#assign integrationsObject = integrations?eval]
[#assign defaultPathPattern = integrationsObject.Path ! ".*"]
[#assign defaultVerbPattern = integrationsObject.Verb ! ".*"]
[#assign defaultValidation = integrationsObject.Validation ! "all"]
[#assign defaultSig4 = integrationsObject.Sig4 ! false]
[#assign defaultApiKey = integrationsObject.ApiKey ! false]

[#macro security sig4 apiKey]
    "security": [
        [#local count = 0]
        [#if sig4]
            {
                "sigv4": []
            }
            [#local count += 1]
        [/#if]
        [#if apiKey]
            [#if count > 0],[/#if]
            {
                "api_key": []
            }
        [/#if]
    ]
[/#macro]

[#macro validator type]
    "x-amazon-apigateway-request-validator" : "${type}"
[/#macro]

[#macro methodEntry verb type apiVariable validation sig4 apiKey ]
    [@security sig4 apiKey /],
    [@validator validation /],
    [#switch type]
        [#case "docker"]
        [#case "http_proxy"]
            "x-amazon-apigateway-integration" : {
                "type": "http_proxy",
                "uri" : "${r"https://${stageVariables." + apiVariable + r"}"}",
                "passthroughBehavior" : "when_no_match",
                "httpMethod" : "${verb}"
            }
            [#break]

        [#case "lambda"]
        [#case "aws_proxy"]
            "x-amazon-apigateway-integration" : {
                "type": "aws_proxy",
                [#-- "uri" : "${r"${stageVariables." + apiVariable + r"}"}", --]
                "uri" : "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${region}:${accountObject.AWSId}:function:${r"${stageVariables." + apiVariable + r"}"}/invocations",
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
[/#macro]

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
    "securityDefinitions": {
        "api_key": {
          "type": "apiKey",
          "name": "x-api-key",
          "in": "header"
        },
        "sigv4": {
          "type": "apiKey",
          "name": "Authorization",
          "in": "header",
          "x-amazon-apigateway-authtype": "awsSigv4"
        }
    },
    [@security defaultSig4 defaultApiKey /],
    [@validator defaultValidation /]
    [#if swaggerObject.paths??]
        ,"paths"  : {
            [#list swaggerObject.paths?keys as path]
                "${path}" : {
                    [#assign pathObject = swaggerObject.paths[path]]
                    [#list pathObject?keys as verb]
                        "${verb}" : {
                            [#assign verbObject = pathObject[verb]]
                            [#list integrationsObject.Patterns as pattern]
                                [#assign pathPattern = pattern.Path ! defaultPathPattern ]
                                [#assign verbPattern = pattern.Verb ! defaultVerbPattern ]
                                [#if path?matches(pathPattern) && verb?matches(verbPattern)]
                                    [@methodEntry 
                                        verb
                                        pattern.Type ! defaultType
                                        pattern.Variable ! defaultVariable
                                        pattern.Validation ! defaultValidation
                                        pattern.Sig4 ! defaultSig4
                                        pattern.ApiKey ! defaultApiKey
                                    /]
                                    [#break]
                                [/#if]
                            [/#list]
                        }
                        [#sep],[/#sep]
                    [/#list]
                }
                [#sep],[/#sep]
            [/#list]
        }
    [/#if]
}

