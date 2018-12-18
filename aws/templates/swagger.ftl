[#ftl]

[#assign defaultGatewayErrorMap =
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
    }
]

[#function getSwaggerValidationLevels]
    [#return
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
            }
        }
    ]
[/#function]

[#function getSwaggerValidation validationLevel ]
    [#return
        {
            "x-amazon-apigateway-request-validator" : validationLevel
        }
    ]
[/#function]

[#-- Determine the legacy cognito pool(s) info --]
[#function getLegacyCognitoPools context integrations]
    [#local result = {} ]
    [#local name   = integrations.cognitoPoolName  !"CognitoUserPool" ]
    [#local header = integrations.cognitoAuthHeader!"Authorization" ]

    [#list integrations.UserPoolArns!integrationsObject.userPoolArns!{} as key, value]
        [#if key == context["Account"] ]
            [#local result +=
                {
                    name : {
                        "Name" : name,
                        "Header" : header,
                        "UserPoolArn" : value,
                        "Default" : true
                    }
                } ]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#-- Determine the cognito pool(s) info --]
[#function getDefaultCognitoPoolName context]
    [#list context.CognitoPools!{} as name, value]
        [#if value.Default!false]
            [#return value.Name]
        [/#if]
    [/#list]
    [#return "" ]
[/#function]

[#function getSwaggerGlobalSecurity context ]
    [#local result =
        {
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
        }
    ]
    [#list context.CognitoPools!{} as name,value]
        [#local result +=
            {
                name : {
                    "type": "apiKey",
                    "name": value.Header,
                    "in": "header",
                    "x-amazon-apigateway-authtype": "cognito_user_pools",
                    "x-amazon-apigateway-authorizer": {
                        "type": "cognito_user_pools",
                        "providerARNs": [ value.UserPoolArn ]
                    }
                }
            }
        ]
    [/#list]

    [#return { "securityDefinitions": result } ]
[/#function]

[#function getSwaggerSecurity sig4Required apiKeyRequired userPoolRequired cognitoPoolName=""]
    [#return
        {
            "security" :
                arrayIfTrue(
                    {
                        "sigv4": []
                    },
                    sig4Required
                ) +
                arrayIfTrue(
                    {
                        "api_key": []
                    },
                    apiKeyRequired
                ) +
                arrayIfTrue(
                    {
                        cognitoPoolName : []
                    },
                    userPoolRequired
                )
        }
    ]
[/#function]

[#function getSwaggerProxyPaths required]
    [#-- 404 support --]
    [#-- "/{proxy+}" and "/" paths to passthrough requests for urls which are not in the specification   --]
    [#-- otherwise API Gateway will report 403. https://forums.aws.amazon.com/thread.jspa?threadID=216684 --]
    [#return
        valueIfTrue(
            {
                "paths" : {
                    "{proxy+}" : { "x-amazon-apigateway-any-method" : {} },
                    "/" : { "x-amazon-apigateway-any-method": {} }
                }
            },
            required
        )
     ]
[/#function]

[#function getSwaggerBinaryMediaTypes types]
    [#return
        valueIfContent(
            {
                "x-amazon-apigateway-binary-media-types" : types
            },
            types
        )
    ]
[/#function]

[#function getSwaggerErrorResponses required errorMap ]
    [#local result = {}]
    [#if required]
        [#local templates = {}]
        [#list errorMap as key,value]
            [#local detail =
                arrayIfContent(
                    "Description:" + value.Description!"",
                    value.Description!""
                ) +
                arrayIfContent(
                    "Action:" + value.Action!"",
                    value.Action!""
                ) +
                ["Diagnostics:$context.error.message"]
            ]
            [#local template =
                [
                    {
                        "Code" : value.Code,
                        "Title" : value.Title,
                        "Detail" : detail?join(", ")
                    }
                ]
            ]
            [#local templates +=
                {
                  key :
                      {
                          "statusCode": value.Status,
                          "responseTemplates":
                             {
                                 "application/json": getJSON(template)
                             }
                      }
                }
            ]
        [/#list]
        [#local result = {"x-amazon-apigateway-gateway-responses" : templates} ]
    [/#if]
    [#return result]
[/#function]

[#function getSwaggerCorsHeaders headers=[] methods=[] origin=[] ]
    [#return
        {
            "method.response.header.Access-Control-Allow-Headers": "\'" + headers?join(",")?j_string + "\'",
            "method.response.header.Access-Control-Allow-Methods": "\'" + methods?join(",")?j_string + "\'",
            "method.response.header.Access-Control-Allow-Origin" : "\'" + origin?join(",")?j_string + "\'"
        }
    ]
[/#function]

[#function getSwaggerMethodEntry context path verb type apiVariable
    validationLevel sig4Required apiKeyRequired
    userPoolRequired cognitoPoolName
    useClientCredsRequired
    requests={}
    responses={}
    corsConfiguration={} ]

    [#local result =
        getSwaggerSecurity(sig4Required, apiKeyRequired, userPoolRequired, cognitoPoolName) +
        getSwaggerValidation(validationLevel)
    ]

    [#switch type]
        [#case "docker"]
        [#case "http_proxy"]
            [#local result +=
                {
                    "x-amazon-apigateway-integration" : {
                        "type": "http_proxy",
                        "uri" : "https://$\{stageVariables." + apiVariable + "}",
                        "passthroughBehavior" : "when_no_match",
                        "httpMethod" : verb
                    }
                }
            ]
            [#break]

        [#case "lambda"]
        [#case "aws_proxy"]
            [#local result +=
                {
                    "x-amazon-apigateway-integration" : {
                        "type": "aws_proxy",
                        "uri" : "arn:aws:apigateway:" + context["Region"] + ":lambda:path/2015-03-31/functions/arn:aws:lambda:" + context["Region"] + ":" + context["Account"] + ":function:$\{stageVariables." + apiVariable + "}/invocations",
                        "passthroughBehavior" : "never",
                        "httpMethod" : "POST"
                    } +
                    valueIfTrue(
                        {
                            "credentials" : "arn:aws:iam::*:user/*"
                        },
                        useClientCredsRequired
                    ),
                    "responses" : {}
                }
            ]
            [#break]

        [#case "sms"]
            [#-- Force the content type so the api returns the response body as JSON --]
            [#local result +=
                {
                    "x-amazon-apigateway-integration" : {
                        "type": "aws",
                        "uri" : "arn:aws:apigateway:" + context["Region"] + ":sns:action/Publish",
                        "passthroughBehavior" : "never",
                        "httpMethod" : "POST",
                        "credentials" : context[formatAbsolutePath(path,"rolearn")],
                        "responses" :
                            {
                                "default" : {
                                    "statusCode" : "200"
                                }
                            } +
                            responses
                    } +
                    requests
                }
            ]
            [#break]

        [#case "lambda_plain"]
            [#-- Force the content type so the api returns the response body as JSON --]
            [#local result +=
                {
                    "x-amazon-apigateway-integration" : {
                        "type": "aws",
                        "uri" : "arn:aws:apigateway:" + context["Region"] + ":lambda:path/2015-03-31/functions/arn:aws:lambda:" + context["Region"] + ":" + context["Account"] + ":function:$\{stageVariables." + apiVariable + "}/invocations",
                        "passthroughBehavior" : "never",
                        "httpMethod" : "POST",
                        "responses" :
                            {
                                "default" : {
                                    "statusCode" : "200"
                                }
                            } +
                            responses
                    } +
                    valueIfTrue(
                        {
                            "credentials" : "arn:aws:iam::*:user/*"
                        },
                        useClientCredsRequired
                    ) +
                    requests
                }
            ]
            [#break]

        [#case "mock"]
            [#local result +=
                {
                    "x-amazon-apigateway-integration" : {
                        "type": "mock"
                    }
                }
            ]
            [#break]

        [#case "mock-cors"]
            [#local result +=
                {
                    "x-amazon-apigateway-integration" : {
                        "type" : "mock",
                        "contentHandling" : "CONVERT_TO_TEXT",
                        "passthroughBehavior" : "when_no_match",
                        "requestTemplates": {
                            "application/json": getJSON({ "statusCode" : 200})
                        },
                        "contentHandling" : "CONVERT_TO_TEXT",
                        "responses": {
                            "default": {
                                "statusCode": 200,
                                "responseParameters": corsConfiguration
                            }
                        }
                    }
                }
            ]
            [#break]
    [/#switch]
    [#return result]
[/#function]

[#function extendSwaggerDefinition definition integrations context={} merge=false]

    [#-- General defaults for integrations --]
    [#local defaultPathPattern            = integrations.Path           ! ".*"]
    [#local defaultVerbPattern            = integrations.Verb           ! ".*"]
    [#local defaultType                   = integrations.Type           ! ""]
    [#local defaultVariable               = integrations.Variable       ! ""]
    [#local defaultValidationLevel        = integrations.Validation     ! "all"]
    [#local defaultSig4Required           = integrations.Sig4           ! false]
    [#local defaultApiKeyRequired         = integrations.ApiKey         ! false]
    [#local defaultUserPoolRequired       = integrations.userPool       ! false ]
    [#local defaultUseClientCredsRequired = integrations.useClientCreds ! false ]

    [#-- CORS defaults --]
    [#local defaultCorsHeaders            = integrations.corsHeaders    ! ["Content-Type","X-Amz-Date","Authorization","X-Api-Key"] ]
    [#local defaultCorsMethods            = integrations.corsMethods    ! ["*"] ]
    [#local defaultCorsOrigin             = integrations.corsOrigin     ! ["*"] ]

    [#-- Overall settings --]
    [#local proxyRequired                 = integrations.Proxy                 ! false]
    [#local binaryTypes                   = integrations.BinaryTypes           ! []]
    [#local gatewayErrorReportingRequired = integrations.GatewayErrorReporting ! true ]
    [#local gatewayErrorMap               = defaultGatewayErrorMap + (integrations.gatewayErrorMap!{}) ]

    [#-- Correct typing error with proxyRequired --]
    [#if proxyRequired?is_string]
        [#local proxyRequired = (proxyRequired?lower_case == "true")]
    [/#if]

    [#-- Determine the default Cognito pool --]
    [#local defaultCognitoPoolName = getDefaultCognitoPoolName(context) ]

    [#-- Start with global configuration --]
    [#local globalConfiguration =
        valueIfTrue(definition, merge) +
        getSwaggerValidationLevels() +
        getSwaggerValidation(defaultValidationLevel) +
        getSwaggerGlobalSecurity(context) +
        getSwaggerSecurity(defaultSig4Required, defaultApiKeyRequired, defaultUserPoolRequired, defaultCognitoPoolName) +
        getSwaggerBinaryMediaTypes(binaryTypes) +
        getSwaggerErrorResponses(gatewayErrorReportingRequired, gatewayErrorMap)
    ]

    [#local paths = {} ]
    [#list (definition.paths!{}) + getSwaggerProxyPaths(proxyRequired) as path, pathObject]
        [#local verbs = {} ]
        [#-- If we add an OPTIONS verb, it reflects what any of the other verbs require --]
        [#local optionsSig4 = false]
        [#local optionsApiKey = false]

        [#list pathObject as verb, verbObject]
            [#local extendedVerb = {} ]
            [#list integrations.Patterns![] as pattern]
                [#if path?matches(pattern.Path ! defaultPathPattern) &&
                    verb?matches(pattern.Verb ! defaultVerbPattern)]
                    [#local extendedVerb =
                        getSwaggerMethodEntry(
                            context,
                            path,
                            verb,
                            pattern.Type ! defaultType,
                            pattern.Variable ! defaultVariable,
                            pattern.Validation ! defaultValidationLevel,
                            pattern.Sig4 ! defaultSig4Required,
                            pattern.ApiKey ! defaultApiKeyRequired,
                            pattern.UserPool ! pattern.userPool ! defaultUserPoolRequired,
                            pattern.CognitoPoolName ! defaultCognitoPoolName,
                            pattern.UseClientCreds ! pattern.useClientCreds ! defaultUseClientCredsRequired,
                            pattern.Requests ! {}
                            pattern.Responses ! {}
                        )
                    ]
                    [#local optionsSig4 = optionsSig4 || (pattern.Sig4 ! defaultSig4Required)]
                    [#local optionsApiKey = optionsApiKey || (pattern.ApiKey ! defaultApiKeyRequired)]
                    [#break]
                [/#if]
            [/#list]
            [#if ! extendedVerb?has_content]
                [#local extendedVerb =
                    getSwaggerMethodEntry(
                        context,
                        path,
                        verb,
                        defaultType,
                        defaultVariable,
                        defaultValidationLevel,
                        defaultSig4Required,
                        defaultApiKeyRequired,
                        defaultUserPoolRequired,
                        defaultCognitoPoolName,
                        defaultUseClientCredsRequired
                    )
                ]
                [#local optionsSig4 = optionsSig4 || defaultSig4Required]
                [#local optionsApiKey = optionsApiKey || defaultApiKeyRequired)]
            [/#if]
            [#local verbs +=
                {
                    verb :
                        valueIfTrue(verbObject, merge) +
                        extendedVerb
                } ]
        [/#list]

        [#-- Add default CORS config if not "any" verb and no explicit "options" verb --]
        [#if (!(path.x-amazon-apigateway-any-method??) && (!pathObject?keys?seq_contains("options"))]
            [#local verbs +=
                {
                    "options" : {
                        "responses": {
                            "200": {
                                "description": "Default response for CORS method",
                                "headers": {
                                    "Access-Control-Allow-Headers": {
                                        "type": "string"
                                    },
                                    "Access-Control-Allow-Methods": {
                                        "type": "string"
                                    },
                                    "Access-Control-Allow-Origin": {
                                        "type": "string"
                                    }
                                }
                            }
                        }
                    } +
                    getSwaggerMethodEntry(
                        context,
                        path,
                        "options",
                        "mock-cors",
                        defaultVariable,
                        defaultValidationLevel,
                        optionsSig4,
                        optionsApiKey,
                        false,
                        "",
                        false,
                        {},
                        {},
                        getSwaggerCorsHeaders(defaultCorsHeaders,defaultCorsMethods,defaultCorsOrigin)
                    )
                }
            ]
        [/#if]

        [#local paths += { path : verbs } ]
    [/#list]

    [#return globalConfiguration + { "paths" : paths } ]
[/#function]

[#function getSwaggerDefinitionRoles definition integrations context={} ]
    [#local defaultPathPattern = integrations.Path ! ".*"]
    [#local defaultVerbPattern = integrations.Verb ! ".*"]
    [#local defaultType        = integrations.Type ! ""]
    [#local roles = {} ]

    [#list definition.paths!{} as path, pathObject]
        [#list pathObject as verb, verbObject]
            [#local type = ""]
            [#list integrations.Patterns![] as pattern]
                [#if path?matches(pattern.Path ! defaultPathPattern) &&
                    verb?matches(pattern.Verb ! defaultVerbPattern)]
                        [#local type = pattern.Type ! defaultType]
                        [#break]
                [/#if]
            [/#list]
            [#if !type?has_content]
                [#local type = defaultType]
            [/#if]
            [#switch type]
                [#case "sms"]
                    [#local roles +=
                        {
                            path :
                                [
                                    getPolicyDocument(
                                        getPolicyStatement("sns:Publish"),
                                        "swagger"
                                    )
                                ]
                        } ]
                    [#break]
            [/#switch]
        [/#list]
    [/#list]
    [#return roles]
[/#function]
