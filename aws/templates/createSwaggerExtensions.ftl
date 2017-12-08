[#ftl]

[#assign swaggerObject = swagger?eval]
[#assign integrationsObject = integrations?eval]
[#assign defaultPathPattern = integrationsObject.Path ! ".*"]
[#assign defaultVerbPattern = integrationsObject.Verb ! ".*"]
[#assign defaultType = integrationsObject.Type ! ""]
[#assign defaultVariable = integrationsObject.Variable ! ""]
[#assign defaultValidation = integrationsObject.Validation ! "all"]
[#assign defaultSig4 = integrationsObject.Sig4 ! false]
[#assign gatewayErrorReporting = integrationsObject.GatewayErrorReporting ! "full"]
[#assign gatewayErrorMap =
          {
              "ACCESS_DENIED": {
                  "Status" : 403,
                  "Code" : "gen01",
                  "Title" : "Authorisation Failure",
                  "Action" : "Please contact the API provider"
              },
              "API_CONFIGURATION_ERROR": {
                  "Status" : 500,
                  "Code" : "gen02",
                  "Title" : "Internal API failure",
                  "Action" : "Please contact the API provider"
              },
              "AUTHORIZER_CONFIGURATION_ERROR": {
                  "Status" : 500,
                  "Code" : "gen03",
                  "Title" : "Internal API failure",
                  "Action" : "Please contact the API provider"
              },
              "AUTHORIZER_FAILURE": {
                  "Status" : 500,
                  "Code" : "gen04",
                  "Title" : "Internal API failure",
                  "Action" : "Please contact the API provider"
              },
              "BAD_REQUEST_PARAMETERS": {
                  "Status" : 400,
                  "Code" : "gen05",
                  "Title" : "Parameters not valid",
                  "Action" : "Please check the API documentation"
              },
              "BAD_REQUEST_BODY": {
                  "Status" : 400,
                  "Code" : "gen06",
                  "Title" : "Request body not valid",
                  "Action" : "Please check the API documentation"
              },
              "EXPIRED_TOKEN": {
                  "Status" : 401,
                  "Code" : "gen07",
                  "Title" : "Expired Token",
                  "Action" : "Please re-authenticate"
              },
              "INTEGRATION_FAILURE": {
                  "Status" : 500,
                  "Code" : "gen08",
                  "Title" : "Internal API failure",
                  "Action" : "Please contact the API provider"
              },
              "INTEGRATION_TIMEOUT": {
                  "Status" : 500,
                  "Code" : "gen09",
                  "Title" : "Internal API failure",
                  "Action" : "Please contact the API provider"
              },
              "INVALID_API_KEY": {
                  "Status" : 401,
                  "Code" : "gen10",
                  "Title" : "Invalid API Key",
                  "Action" : "Please contact the API provider"
              },
              "INVALID_SIGNATURE": {
                  "Status" : 401,
                  "Code" : "gen11",
                  "Title" : "Invalid signature",
                  "Action" : "Please check signature implementation"
              },
              "MISSING_AUTHENTICATION_TOKEN": {
                  "Status" : 401,
                  "Code" : "gen12",
                  "Title" : "Authentication Failure",
                  "Action" : "Please check the API specification to ensure verb/path are valid"
              },
              "QUOTA_EXCEEDED": {
                  "Status" : 429,
                  "Code" : "gen13",
                  "Title" : "Quota exceeded",
                  "Action" : "Please contact the API provider"
              },
              "REQUEST_TOO_LARGE": {
                  "Status" : 413,
                  "Code" : "gen14",
                  "Title" : "Request too large",
                  "Action" : "Please check the API documentation"
              },
              "RESOURCE_NOT_FOUND": {
                  "Status" : 404,
                  "Code" : "gen15",
                  "Title" : "Resource not found",
                  "Action" : "Please check the API documentation"
              },
              "THROTTLED": {
                  "Status" : 429,
                  "Code" : "gen16",
                  "Title" : "Throttling employed",
                  "Action" : "Please contact the API provider"
              },
              "UNAUTHORIZED": {
                  "Status" : 403,
                  "Code" : "gen17",
                  "Title" : "Authorisation Failure",
                  "Action" : "Please contact the API provider"
              },
              "UNSUPPORTED_MEDIA_TYPE": {
                  "Status" : 415,
                  "Code" : "gen18",
                  "Title" : "Unsupported media type",
                  "Action" : "Please check the API documentation"
              }
          } +
          integrationsObject.gatewayErrorMap ! {}]
[#assign defaultApiKey = integrationsObject.ApiKey ! false]
[#assign binaryTypes = integrationsObject.BinaryTypes ! []]

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

[#macro gatewayResponses errorMap]
    [#list errorMap as key,value]
        [#assign detail = [] ]
        [#if value.Description?has_content]
            [#assign detail += ["Description:" + value.Description] ]
        [/#if]
        [#if value.Action?has_content]
            [#assign detail += ["Action:" + value.Action] ]
        [/#if]
        "${key}" : {
            "statusCode": ${value.Status?c},
            "responseTemplates": {
                "application/json": "[{\"Code\" : \"${value.Code}\",\n\"Title\" : \"${value.Title}\",\n\"Detail\" : \"${detail?join(", ")}\",\n\"Diagnostics\" : $context.error.messageString}]"
            }
        }[#sep],[/#sep]
    [/#list]
[/#macro]

[#macro binaryMediaTypes types]
    "x-amazon-apigateway-binary-media-types" : [
        [#list types as type]
            "${type}"
            [#sep],[/#sep]
        [/#list]
    ]
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
                "uri" : "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${region}:${account}:function:${r"${stageVariables." + apiVariable + r"}"}/invocations",
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
    [#if gatewayErrorReporting?has_content]
        "x-amazon-apigateway-gateway-responses": {
            [@gatewayResponses gatewayErrorMap /]
        },
    [/#if]
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
    [@security defaultSig4 defaultApiKey /]
    ,[@validator defaultValidation /]
    [#if binaryTypes?has_content ]
        ,[@binaryMediaTypes binaryTypes /]
    [/#if]
    [#if swaggerObject.paths??]
        ,"paths"  : {
            [#list swaggerObject.paths as path, pathObject]
                "${path}" : {
                    [#list pathObject as verb, verbObject]
                        "${verb}" : {
                            [#assign matchSeen = false]
                            [#if integrationsObject.Patterns??]
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
                                        [#assign matchSeen = true]
                                        [#break]
                                    [/#if]
                                [/#list]
                            [/#if]
                            [#if ! matchSeen]
                                [@methodEntry
                                    verb
                                    defaultType
                                    defaultVariable
                                    defaultValidation
                                    defaultSig4
                                    defaultApiKey
                                /]
                            [/#if]
                        }
                        [#sep],[/#sep]
                    [/#list]
                }
                [#sep],[/#sep]
            [/#list]
        }
    [/#if]
}

