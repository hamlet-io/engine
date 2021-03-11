[#ftl]

[#assign globalDefaults =
    {
        "SecuritySchemes" : {
            "api_key": {
                "Header" : "x-api-key",
                "Type" : "apiKey"
            },
            "sigv4": {
                "Header" : "Authorization",
                "AuthType": "awsSigv4",
                "Type" : "apiKey"
            }
        },
        "GatewayErrorReporting" : {
            "Enabled" : true,
            "Map" : {
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
                    "Status" : 403,
                    "Code" : "gen04",
                    "Title" : "Authorisation Failure",
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
        },
        "Proxy" : false

    }
]

[#assign globalChildren =
    [
        {
            "Names" : ["SecuritySchemes"],
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : ["Type", "type"],
                    "Types" : STRING_TYPE,
                    "Values" : ["basic", "http", "apiKey", "oauth2", "openIdConnect"],
                    "Default" : "apiKey"
                },
                {
                    "Names" : ["Header", "name"],
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : ["In", "in"],
                    "Types" : STRING_TYPE,
                    "Values" : ["header", "query", "cookie"],
                    "Default" : "header"
                },
                {
                    "Names" : "AuthType",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : ["Authorizer", "Authoriser"],
                    "PopulateMissingChildren" : false,
                    "Children" : [
                        {
                            "Names" : "Type",
                            "Types" : STRING_TYPE,
                            "Values" : ["token", "request", "cognito_user_pools"],
                            "Mandatory" : true
                        },
                        {
                            "Names" : "Variable",
                            "Types" : STRING_TYPE
                        },
                        {
                            "Names" : "TTL",
                            "Types" : NUMBER_TYPE,
                            "Default" : 300
                        },
                        {
                            "Names" : "ValidityExpression",
                            "Types" : STRING_TYPE,
                            "Default" : r"^[ \t]*[a-zA-Z0-9\-_]+[ \t]+[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+[ \t]*$"
                        },
                        {
                            "Names" : "Arns",
                            "Types" : ARRAY_OF_STRING_TYPE
                        },
                        {
                            "Names" : "Default",
                            "Types" : BOOLEAN_TYPE
                        }
                    ]
                }
            ]
        },
        {
            "Names" : ["BinaryTypes"],
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : ["GatewayErrorReporting"],
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Template",
                    "Types" : STRING_TYPE,
                    "Default" : "[{ \"Code\": code, \"Title\": title, \"Detail\": (arrayIfContent(\"Description: \" + description, description) + arrayIfContent(\"Action: \" + action, action) + [\"Diagnostics: $context.error.message\"])?join(\", \") }]"
                },
                {
                    "Names" : "Map",
                    "SubObjects" : true,
                    "Children" : [
                        {
                            "Names" : "Template",
                            "Types" : STRING_TYPE
                        },
                        {
                            "Names" : "Status",
                            "Types" : NUMBER_TYPE,
                            "Mandatory" : true
                        },
                        {
                            "Names" : "Code",
                            "Types" : STRING_TYPE,
                            "Mandatory" : true
                        },
                        {
                            "Names" : "Title",
                            "Types" : STRING_TYPE,
                            "Mandatory" : true
                        },
                        {
                            "Names" : "Description",
                            "Types" : STRING_TYPE
                        },
                        {
                            "Names" : "Action",
                            "Types" : STRING_TYPE
                        }
                    ]
                }
            ]
        },
        {
            "Names" : ["Proxy"],
            "Types" : [BOOLEAN_TYPE, STRING_TYPE],
            "Default" : false
        },
        {
            "Names" : ["Options"],
            "Types" : [BOOLEAN_TYPE],
            "Default" : true
        },
        {
            "Names" : ["OptionsSecurity"],
            "Types" : STRING_TYPE,
            "Values" : [ "UseVerb", "disabled" ],
            "Default" : "UseVerb"
        }
    ]
]

[#assign globalDeprecatedChildren =
    [
        {
            "Names" : ["CognitoPoolName", "cognitoPoolName"],
            "Types" : STRING_TYPE,
            "Default" : "CognitoUserPool"
        },
        {
            "Names" : ["CognitoAuthHeader", "cognitoAuthHeader"],
            "Types" : STRING_TYPE,
            "Default" : "Authorization"
        },
        {
            "Names" : ["UserPoolArns", "userPoolArns"],
            "Types" : OBJECT_TYPE,
            "Default" : {}
        }
    ]
]

[#assign methodDefaults =
    {
        "Path" : ".*",
        "Verb" : ".*",
        "Type" : "",
        "Variable" : "",
        "Validation" : "all",
        "UseClientCreds" : false,
        "ContentHandling" : "",
        "Requests" : {},
        "Responses" : {},
        "Cors" : {
            "Headers" : ["Content-Type","X-Amz-Date","Authorization","X-Api-Key"],
            "Methods" : ["*"],
            "Origin" : ["*"]
        },
        "Throttling" : {}
    }
]

[#assign methodChildren =
    [
        {
            "Names" : ["Path"],
            "Types" : STRING_TYPE
        },
        {
            "Names" : ["Verb"],
            "Types" : STRING_TYPE
        },
        {
            "Names" : ["Type"],
            "Types" : STRING_TYPE
        },
        {
            "Names" : ["Variable"],
            "Types" : STRING_TYPE
        },
        {
            "Names" : ["Validation"],
            "Types" : STRING_TYPE,
            "Values" : ["all", "params", "body", "none"]
        },
        {
            "Names" : ["UseClientCreds", "useClientCreds"],
            "Types" : BOOLEAN_TYPE
        },
        {
            "Names" : ["ContentHandling", "contentHandling"],
            "Types" : STRING_TYPE,
            "Values" : ["", "CONVERT_TO_BINARY", "CONVERT_TO_TEXT"]
        },
        {
            "Names" : ["Requests"],
            "Types" : OBJECT_TYPE
        },
        {
            "Names" : ["Responses"],
            "Types" : OBJECT_TYPE
        },
        {
            "Names" : ["Cors"],
            "Children" : [
                {
                    "Names" : "Headers",
                    "Types" : ARRAY_OF_STRING_TYPE
                },
                {
                    "Names" : "Methods",
                    "Types" : ARRAY_OF_STRING_TYPE
                },
                {
                    "Names" : "Origin",
                    "Types" : ARRAY_OF_STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Throttling",
            "Children" : [
                {
                    "Names" : "BurstLimit",
                    "Description" : "The maximum number of concurrent requests.",
                    "Types" : NUMBER_TYPE
                },
                {
                    "Names" : "RateLimit",
                    "Description" : "The request limit per second.",
                    "Types" : NUMBER_TYPE
                }
            ]
        }
    ]
]

[#assign configurationSecurityChildren =
    [
        {
            "Names" : ["Security"],
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : ["Enabled"],
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : ["ScopeBehaviour"],
                    "Types" : STRING_TYPE,
                    "Values" : [REPLACE_COMBINE_BEHAVIOUR, UNIQUE_COMBINE_BEHAVIOUR],
                    "Default" : UNIQUE_COMBINE_BEHAVIOUR
                },
                {
                    "Names" : ["Scopes"],
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        }
    ]
]

[#assign configurationDeprecatedSecurityChildren =
    [
        {
            "Names" : ["Sig4", "Sigv4"],
            "Types" : BOOLEAN_TYPE
        },
        {
            "Names" : ["ApiKey", "apikey", "Apikey"],
            "Types" : BOOLEAN_TYPE
        },
        {
            "Names" : ["UserPool", "userPool"],
            "Types" : BOOLEAN_TYPE
        }
    ]
]

[#assign definitionSecurityChildren =
    [
        {
            "Names" : ["security"],
            "Types" : ARRAY_OF_OBJECT_TYPE,
            "Default" : []
        }
    ]
]

[#function formatLambdaArnUsingStageVariable context stageVariable]
    [#return
        "arn:aws:apigateway:" +
        context["Region"] +
        ":lambda:path/2015-03-31/functions/arn:aws:lambda:" +
        context["Region"] + ":" +
        context["Account"] +
        ":function:$\{stageVariables." + stageVariable + "}/invocations"
    ]
[/#function]

[#function getAWSValidationLevels]
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

[#function getAWSValidation configuration ]
    [#return
        {
            "x-amazon-apigateway-request-validator" : configuration.Validation
        }
    ]
[/#function]

[#function getDeploymentDetails context configuration ]
    [#local version = formatName(configuration.OpenAPI.Information.Version, context["BuildReference"])]
    [#if configuration.OpenAPI.MajorVersion gte 3 ]
        [#return
            {
                "servers" : [
                    {
                        "url" : context["Scheme"] + "://" + context["FQDN"] + formatAbsolutePath( context["BasePath"] ),
                        "description" : context["Name"]
                    }
                ],
                "info" : {
                    "version" : version
                }
            }
        ]
    [#else]
        [#return
            {
                "basePath" : formatAbsolutePath(context["BasePath"]),
                "schemes" : [ context["Scheme"] ],
                "host" : context["FQDN"],
                "info" : {
                    "version" : version,
                    "description" : "**Hamlet Deployment** " + context["Name"] + "/n" + configuration.OpenAPI.Information.Description
                }
            }
        ]
    [/#if]
[/#function]

[#function getSecuritySchemes context configuration ]
    [#local result = {} ]
    [#list configuration.SecuritySchemes!{} as key, value]
        [#local scheme =
            {
                "type" : value.Type
            } +
            attributeIfContent("x-amazon-apigateway-authtype", value.AuthType!"")
        ]
        [#switch value.Type]
            [#case "apiKey"]
                [#local scheme +=
                    {
                        "name" : value.Header!("HamletFatal: No header specified for scheme " + key),
                        "in" : value.In
                    }
                ]
                [#local Authorizer = value.Authorizer!{} ]
                [#if Authorizer?has_content]
                    [#switch Authorizer.Type]
                        [#-- Default validity expression is for bearer based JWT --]
                        [#case "token"]
                            [#local scheme +=
                                {
                                    "x-amazon-apigateway-authorizer": {
                                        "type": "token",
                                        "authorizerUri" : formatLambdaArnUsingStageVariable(context, Authorizer.Variable),
                                        "authorizerResultTtlInSeconds" : Authorizer.TTL,
                                        "identityValidationExpression" : Authorizer.ValidityExpression
                                    }
                                }
                            ]
                            [#break]

                        [#case "cognito_user_pools"]
                            [#local scheme +=
                                {
                                    "x-amazon-apigateway-authorizer": {
                                        "type": "cognito_user_pools",
                                        "providerARNs": Authorizer.Arns
                                    }
                                }
                            ]
                            [#break]
                    [/#switch]
                [/#if]
                [#local result += {key : scheme}]
                [#break]
        [/#switch]
    [/#list]

    [#-- Format depends on OpenAPI version --]
    [#if configuration.OpenAPI.MajorVersion gte 3 ]
        [#return {
            "components" : {
                "securitySchemes" : result
            }
        }]
    [#else]
        [#return { "securityDefinitions" : result } ]
    [/#if]
[/#function]

[#function getDeprecatedSecurityConfiguration globalConfiguration configurationObjects ]
    [#local result = {} ]
    [#local deprecated = getCompositeObject(configurationDeprecatedSecurityChildren, configurationObjects) ]
    [#if deprecated.Sig4??]
        [#local result +=
            {
                "sigv4" : {
                    "Enabled" : deprecated.Sig4,
                    "Scopes": []
                }
            }
        ]
    [/#if]
    [#if deprecated.ApiKey??]
        [#local result +=
            {
                "api_key" : {
                    "Enabled" : deprecated.ApiKey,
                    "Scopes": []
                }
            }
        ]
    [/#if]
    [#if deprecated.UserPool??]
        [#list globalConfiguration.SecuritySchemes!{} as scheme, value]
            [#if value.Authorizer?has_content]
                [#if (value.Authorizer.Type == "cognito_user_pools") && value.Authorizer.Default ]
                    [#local result +=
                        {
                            scheme : {
                                "Enabled" : deprecated.UserPool,
                                "Scopes": []
                            }
                        }
                    ]
                    [#break]
                [/#if]
            [/#if]
        [/#list]
    [/#if]
    [#return { "Security" : result } ]
[/#function]

[#--
Security config has to be handled specially as it is an array
of objects in the openAPI specification which getCompositeObject()
doesn't handle very well.

The elements in the array are alternatives, while the attributes of each
array object are ANDed. Configured schemes are added into each array object,
thus adding to the requirements specified in the definition itself.

A security attribute is explicitly written out every time so technically
the method security attribute will always override the global one, but it
is useful to see what the global settings are from a debug perspective
--]
[#function getSecurity globalConfiguration definitionObjects configurationObjects ]

    [#-- Get the security present in the openAPI definition --]
    [#local definitionOptions =
        getCompositeObject(definitionSecurityChildren, definitionObjects).security
    ]

    [#-- Get the security present in the configuration --]
    [#local configuration =
        mergeObjects(
            getCompositeObject(configurationSecurityChildren, configurationObjects),
            getDeprecatedSecurityConfiguration(globalConfiguration, configurationObjects)
        ).Security
    ]

    [#-- Apply the configuration security to the definition security --]
    [#local result = [] ]
    [#if definitionOptions?has_content]
        [#-- Add configured schemes to defined schemes --]
        [#list definitionOptions as definitionOption]
            [#local option = definitionOption]
            [#list configuration as scheme,value]
                [#if value.Enabled]
                    [#-- Combine scopes with any existing definition --]
                    [#local option +=
                        {
                            scheme :
                                combineEntities(
                                    (option[scheme])![],
                                    value.Scopes,
                                    value.ScopeBehaviour
                                )
                        }
                    ]
                [/#if]
            [/#list]
            [#local result += [option] ]
        [/#list]
    [#else]
        [#-- Rely on the configured schemes alone --]
        [#local option = {}]
        [#list configuration as scheme,value]
            [#if value.Enabled]
                [#local option += { scheme : value.Scopes } ]
            [/#if]
        [/#list]
        [#if option?has_content]
            [#local result = [option] ]
        [/#if]
    [/#if]

    [#return
        {
            "security" : result
        }
    ]
[/#function]

[#function mergeSecurity currentSecurity newSecurity]
    [#local current = (currentSecurity.security)![] ]
    [#local new = (newSecurity.security)![] ]

    [#-- Check for previously unseen entries --]
     [#list new as newOption]
        [#local unseen = true ]
        [#list current as currentOption]
            [#-- First check if the schemes are different --]
            [#if
                (getUniqueArrayElements(newOption?keys, currentOption?keys)?size !=
                newOption?keys?size) ||
                (newOption?keys?size != currentOption?keys?size) ]
                [#continue]
            [/#if]
            [#-- Now check for different scopes --]
            [#local sameValues = true]
            [#list newOption as key, value]
                [#if
                    (getUniqueArrayElements(value, currentOption[key])?size !=
                    value?size) ||
                    (value?size != currentOption[key]?size) ]
                    [#local sameValues = false]
                [/#if]
            [/#list]
            [#if sameValues]
                [#-- current entry matches new entryso ignore new entry --]
                [#local unseen = false]
                [#break]
            [/#if]
        [/#list]
        [#if unseen]
            [#local current += [newOption] ]
        [/#if]
    [/#list]

    [#return
        {
            "security" : current
        }
    ]
[/#function]

[#function getAWSProxyPaths configuration]
    [#-- 404 support --]
    [#-- "/{proxy+}" and "/" paths to passthrough requests for urls which are not in the specification   --]
    [#-- otherwise API Gateway will report 403. https://forums.aws.amazon.com/thread.jspa?threadID=216684 --]
    [#return
        valueIfTrue(
            {
                "{proxy+}" : { "x-amazon-apigateway-any-method" : {} },
                "/" : { "x-amazon-apigateway-any-method": {} }
            },
            configuration.Proxy
        )
     ]
[/#function]

[#function getAWSBinaryMediaTypes configuration]
    [#return
        valueIfContent(
            {
                "x-amazon-apigateway-binary-media-types" : configuration.BinaryTypes
            },
            configuration.BinaryTypes
        )
    ]
[/#function]

[#function getAWSErrorResponses configuration ]
    [#local result = {}]
    [#if configuration.GatewayErrorReporting.Enabled]
        [#local templates = {}]
        [#local defaultTemplate = configuration.GatewayErrorReporting.Template ]

        [#list configuration.GatewayErrorReporting.Map as key,value]
            [#local code = value.Code]
            [#local title = value.Title]
            [#local description = value.Description!""]
            [#local action = value.Action!""]

            [#-- Apply the desired template format --]
            [#local template = (value.Template!defaultTemplate)?eval]

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

[#function getCorsHeaders configuration ]
    [#return
        {
            "method.response.header.Access-Control-Allow-Headers": "\'" + configuration.Cors.Headers?join(",")?j_string + "\'",
            "method.response.header.Access-Control-Allow-Methods": "\'" + configuration.Cors.Methods?join(",")?j_string + "\'",
            "method.response.header.Access-Control-Allow-Origin" : "\'" + configuration.Cors.Origin?join(",")?j_string + "\'"
        }
    ]
[/#function]

[#function getGlobalConfiguration definition integrations context]

    [#-- Get OpenAPI Specification Version --]
    [#local definitionVersion = definition.openapi!definition.swagger ]
    [#local majorVersion = (definitionVersion?split(".")[0])?number ]

    [#-- Determine security schemes explicitly in the definition --]
    [#-- This permits the config to augment/override the definition if required --]
    [#if majorVersion gte 3 ]
        [#local schemes = (definition.Components.SecuritySchemes)!{} ]
    [#else]
        [#local schemes = (definition.securityDefinitions)!{} ]
    [/#if]

    [#-- Add in any deprecated userpool schemes           --]
    [#-- Userpools should now be configured via links --]
    [#local deprecated = getCompositeObject(globalDeprecatedChildren, integrations) ]
    [#list deprecated.UserPoolArns as key, value]
        [#if key == context["Account"] ]
            [#local schemes +=
                {
                    deprecated.CognitoPoolName : {
                        "Type": "apiKey",
                        "Header": deprecated.CognitoAuthHeader,
                        "AuthType" : "cognito_user_pools",
                        "Authorizer" : {
                            "Type" : "cognito_user_pools",
                            "Arns" : [ value ],
                            "Default" : true
                        }

                    }
                } ]
        [/#if]
    [/#list]

    [#-- Add in the context(link) defined schemes --]
    [#list context.CognitoPools!{} as name,value]
        [#local schemes +=
            {
                name : {
                    "Type": "apiKey",
                    "Header": value.Header,
                    "AuthType" : "cognito_user_pools",
                    "Authorizer" : {
                        "Type" : "cognito_user_pools",
                        "Arns" : [ value.UserPoolArn ],
                        "Default" : true
                    }
                }
            }
        ]
    [/#list]

    [#list context.LambdaAuthorizers!{} as name,value]
        [#local schemes +=
            {
                name : {
                    "Type": "apiKey",
                    "Header" : "Authorization",
                    "AuthType" : "oauth2",
                    "Authorizer" : {
                        "Type": "token",
                        "Variable" : value.StageVariable
                    }
                }
            }
        ]
    [/#list]

    [#-- Get the global configuration --]
    [#local result =
        getCompositeObject(
            globalChildren + methodChildren,
            globalDefaults,
            methodDefaults,
            {
                "SecuritySchemes" : schemes
            },
            integrations
        ) ]

    [#-- Correct typing error with Proxy --]
    [#if result.Proxy?? && result.Proxy?is_string]
        [#local result += {"Proxy" : (result.Proxy?lower_case == "true")}]
    [/#if]

    [#return
        result +
        {
            "OpenAPI" : {
                "Version" : definitionVersion,
                "MajorVersion" : majorVersion,
                "Information" : {
                    "Description" : (definition.info.description)!"",
                    "Version" : definition.info.version
                }
            }
        }
    ]

[/#function]

[#function getMethodConfiguration globalConfiguration pattern ]

    [#-- Get the desired method configuration --]
    [#return getCompositeObject(methodChildren, globalConfiguration, pattern) ]

[/#function]

[#function getMethodEntry path verb context configuration ]

    [#local result = getAWSValidation(configuration) ]

    [#switch configuration.Type]
        [#case "docker"]
        [#case "http_proxy"]
            [#local result +=
                {
                    "x-amazon-apigateway-integration" : {
                        "type": "http_proxy",
                        "uri" : "https://$\{stageVariables." + configuration.Variable + "}",
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
                        "uri" : formatLambdaArnUsingStageVariable(context, configuration.Variable),
                        "passthroughBehavior" : "never",
                        "httpMethod" : "POST"
                    } +
                    valueIfTrue(
                        {
                            "credentials" : "arn:aws:iam::*:user/*"
                        },
                        configuration.UseClientCreds
                    ) +
                    attributeIfContent(
                        "contentHandling",
                        configuration.ContentHandling
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
                            configuration.Responses
                    } +
                    configuration.Requests
                }
            ]
            [#break]

        [#case "lambda_plain"]
            [#-- Force the content type so the api returns the response body as JSON --]
            [#local result +=
                {
                    "x-amazon-apigateway-integration" : {
                        "type": "aws",
                        "uri" : formatLambdaArnUsingStageVariable(context, configuration.Variable),
                        "passthroughBehavior" : "never",
                        "httpMethod" : "POST",
                        "responses" :
                            {
                                "default" : {
                                    "statusCode" : "200"
                                }
                            } +
                            configuration.Responses
                    } +
                    valueIfTrue(
                        {
                            "credentials" : "arn:aws:iam::*:user/*"
                        },
                        configuration.UseClientCreds
                    ) +
                    attributeIfContent(
                        "contentHandling",
                        configuration.ContentHandling
                    ) +
                    configuration.Requests
                }
            ]
            [#break]

        [#case "mock"]
            [#local result +=
                {
                    "x-amazon-apigateway-integration" : {
                        "type": "mock",
                        "passthroughBehavior" : "never",
                        "responses" :
                            {
                                "default" : {
                                    "statusCode" : "200"
                                }
                            } +
                            configuration.Responses
                    } +
                    attributeIfContent(
                        "contentHandling",
                        configuration.ContentHandling
                    ) +
                    configuration.Requests
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
                                "responseParameters": getCorsHeaders(configuration)
                            }
                        }
                    }
                }
            ]
            [#break]
    [/#switch]
    [#return result]
[/#function]

[#-- Verbs we know about --]
[#assign knownHttpVerbs =
    [
        "get", "put", "post", "delete", "options", "head", "patch", "trace",
        "x-amazon-apigateway-any-method"
    ]
]

[#function extendOpenapiDefinition definition integrations context={} merge=false]

    [#-- Determine the global configuration --]
    [#local globalConfiguration =
        getGlobalConfiguration(definition, integrations, context) ]

    [#-- Start with global content --]
    [#local globalContent =
        mergeObjects(
            valueIfTrue(definition, merge),
            getAWSValidationLevels(),
            getAWSValidation(globalConfiguration),
            getAWSBinaryMediaTypes(globalConfiguration),
            getAWSErrorResponses(globalConfiguration),
            getDeploymentDetails(context, globalConfiguration),
            getSecuritySchemes(context, globalConfiguration)
        )
    ]

    [#-- Add the global security --]
    [#local globalContent +=
        getSecurity(globalConfiguration, definition, integrations) ]

    [#local paths = {} ]
    [#list (definition.paths!{}) + getAWSProxyPaths(globalConfiguration) as path, pathObject]
        [#local verbs = {} ]
        [#-- If we add an OPTIONS verb, it reflects what other verbs require --]
        [#local optionsSecurity = {} ]

        [#list pathObject as verb, verbObject]
            [#if !knownHttpVerbs?seq_contains(verb)]
                [#-- Only interested in verb fields --]
                [#if merge]
                    [#local verbs +=
                        {
                            verb : verbObject
                        } ]
                [/#if]
                [#continue]
            [/#if]
            [#local extendedVerb = {} ]
            [#list integrations.Patterns![] as pattern]
                [#local methodConfiguration = getMethodConfiguration(globalConfiguration, pattern)]
                [#if path?matches(methodConfiguration.Path) &&
                    verb?matches(methodConfiguration.Verb)]
                    [#local extendedVerb =
                        getMethodEntry(
                            path,
                            verb,
                            context,
                            methodConfiguration
                        )
                    ]
                    [#local security =
                        getSecurity(globalConfiguration, [definition, verbObject], [integrations, pattern]) ]

                    [#local optionsSecurity = mergeSecurity(optionsSecurity, security) ]
                    [#local extendedVerb += security ]
                    [#break]
                [/#if]
            [/#list]
            [#if ! extendedVerb?has_content]
                [#local extendedVerb =
                    getMethodEntry(
                        path,
                        verb,
                        context,
                        globalConfiguration
                    )
                ]
                [#local security =
                    getSecurity(globalConfiguration, [definition, verbObject], [integrations]) ]

                [#local optionsSecurity = mergeSecurity(optionsSecurity, security) ]
                [#local extendedVerb += security ]
            [/#if]
            [#local verbs +=
                {
                    verb :
                        valueIfTrue(verbObject, merge) +
                        extendedVerb
                } ]
        [/#list]

        [#-- Add default CORS config if not "any" verb and no explicit "options" verb --]
        [#if
            (
                !(
                    pathObject["x-amazon-apigateway-any-method"]?? ||
                    pathObject["options"]??
                )
            ) && globalConfiguration.Options ]
            [#local verbs +=
                {
                    "options" : {
                        "responses": {
                            "200": {
                                "description": "Default response for CORS method",
                                "headers":
                                    (globalConfiguration.OpenAPI.MajorVersion gte 3)?then(
                                        {
                                            "Access-Control-Allow-Headers": {
                                                "schema" : {
                                                    "type": "string"
                                                }
                                            },
                                            "Access-Control-Allow-Methods": {
                                                "schema" : {
                                                    "type": "string"
                                                }
                                            },
                                            "Access-Control-Allow-Origin": {
                                                "schema" : {
                                                    "type": "string"
                                                }
                                            }
                                        },
                                        {
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
                                    )
                            }
                        }
                    } +
                    getMethodEntry(
                        path,
                        "options",
                        context,
                        globalConfiguration +
                        {
                            "Type" : "mock-cors"
                        }
                    ) +
                    valueIfTrue(
                        optionsSecurity,
                        globalConfiguration.OptionsSecurity == "UseVerb",
                        { "security" : [ {} ] }
                    )
                }
            ]
        [/#if]

        [#local paths += { path : verbs } ]
    [/#list]

    [#return mergeObjects( globalContent, { "paths" : paths } ) ]
[/#function]

[#function getOpenapiDefinitionRoles definition integrations context={} ]
    [#local defaultPathPattern = integrations.Path ! ".*"]
    [#local defaultVerbPattern = integrations.Verb ! ".*"]
    [#local defaultType        = integrations.Type ! ""]
    [#local roles = {} ]

    [#list definition.paths!{} as path, pathObject]
        [#list pathObject as verb, verbObject]
            [#if !knownHttpVerbs?seq_contains(verb)]
                [#-- Only interested in verb fields --]
                [#continue]
            [/#if]
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
                                        "openapi"
                                    )
                                ]
                        } ]
                    [#break]
            [/#switch]
        [/#list]
    [/#list]
    [#return roles]
[/#function]
