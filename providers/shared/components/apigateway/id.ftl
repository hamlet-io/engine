[#ftl]
[#--
Ideally stages should be a separate subcomponent. However the deployment
model makes that tricky with the openAPI definition associated to the api
object.
--]

[#assign apiGatewayDescription = [
"There are multiple modes of deployment offered for the API Gateway, mainly to",
"support use of product domains for endpoints. The key",
"consideration is the handling of the host header. The modes reflect the",
"changes and improvements AWS have made to the API Gateway over time.",
"For whitelisted APIs, mode 4 is the recommended one now.",
"\n",
"1. Multi-domain cloudfront + EDGE endpoint",
"    - waf based IP whitelisting",
"    - multiple cloudfront aliases",
"    - host header blocked",
"    - EDGE based API Gateway",
"    - signing based on AWS assigned API domain name",
"    - API-KEY used as shared secret between cloudfront and the API",
"2. Single domain cloudfront + EDGE endpoint",
"    - waf based IP whitelisting",
"    - single cloudfront alias",
"    - host header blocked",
"    - EDGE based API Gateway",
"    - signing based on \"sig4-\" + alias",
"    - API-KEY used as shared secret between cloudfront and the API",
"3. Multi-domain cloudfront + REGIONAL endpoint",
"    - waf based IP whitelisting",
"    - multiple cloudfront aliases",
"    - host header passed through to endpoint",
"    - REGIONAL based API Gateway",
"    - signing based on any of the aliases",
"    - API-KEY used as shared secret between cloudfront and the API",
"4. API endpoint",
"    - waf or policy based IP whitelisting",
"    - multiple aliases or AWS assigned domain",
"    - EDGE or REGIONAL",
"    - signing based on any of the aliases",
"    - API-KEY can be used for client metering",
"\n",
"If multiple domains are provided, the primary domain is used to provide the",
"endpoint for the the API documentation and for the gateway attributes. For",
"documentation, the others redirect to the primary."
] ]

[@addComponentDeployment
    type=APIGATEWAY_COMPONENT_TYPE
    defaultGroup="application"
    defaultPriority=50
/]

[@addComponent
    type=APIGATEWAY_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" :
                    [
                        "Application level API proxy",
                        ""
                    ] + apiGatewayDescription
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            }
        ]
    attributes=
        [
            {
                "Names" : ["Fragment", "Container"],
                "Type" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "WAF",
                "Children" : wafChildConfiguration
            },
            {
                "Names" : "EndpointType",
                "Type" : STRING_TYPE,
                "Values" : ["EDGE", "REGIONAL"],
                "Default" : "EDGE"
            },
            {
                "Names" : "IPAddressGroups",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Authentication",
                "Type" : STRING_TYPE,
                "Values" : ["IP", "SIG4ORIP", "SIG4ANDIP"],
                "Default" : "IP"
            },
            {
                "Names" : "CloudFront",
                "Children" : [
                    {
                        "Names" : "AssumeSNI",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "EnableLogging",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "CountryGroups",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    },
                    {
                        "Names" : "CustomHeaders",
                        "Type" : ARRAY_OF_ANY_TYPE,
                        "Default" : []
                    },
                    {
                        "Names" : "Mapping",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "Compress",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Certificate",
                "Children" : certificateChildConfiguration
            },
            {
                "Names" : "Publish",
                "Description" : "Deprecated - Please switch to the publishers configuration",
                "Children" : [
                    {
                        "Names" : "DnsNamePrefix",
                        "Type" : STRING_TYPE,
                        "Default" : "docs"
                    },
                    {
                        "Names" : "IPAddressGroups",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    }
                ]
            },
            {
                "Names" : "Publishers",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Links",
                        "Subobjects" : true,
                        "Children" : linkChildrenConfiguration
                    },
                    {
                        "Names" : "Path",
                        "Children" : pathChildConfiguration
                    },
                    {
                        "Names" : "UsePathInName",
                        "Description" : "Name the Swagger Spec file using the path",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Mapping",
                "Children" : [
                    {
                        "Names" : "IncludeStage",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Security",
                        "Type" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Alert",
                        "Type" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Logging",
                        "Type" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            },
            {
                "Names" : "LogMetrics",
                "Subobjects" : true,
                "Children" : logMetricChildrenConfiguration
            },
            {
                "Names" : "LogStore",
                "Description" : "The logging destination for the API Gateway.",
                "Type" : STRING_TYPE
            },
            {
                "Names" : "BasePathBehaviour",
                "Description" : "How to handle base paths provided in the spec",
                "Type" : STRING_TYPE,
                "Values" : [ "ignore", "prepend", "split" ],
                "Default" : "ignore"
            },
            {
                "Names" : "Tracing",
                "Children" : tracingChildConfiguration
            }
        ]
/]
