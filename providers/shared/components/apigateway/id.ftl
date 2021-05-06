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
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "AccessLogging",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Description" : "Logging of the API Gateway Access Logs.",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "WAF",
                "Children" : wafChildConfiguration
            },
            {
                "Names" : "EndpointType",
                "Types" : STRING_TYPE,
                "Values" : ["EDGE", "REGIONAL"],
                "Default" : "EDGE"
            },
            {
                "Names" : "IPAddressGroups",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Authentication",
                "Types" : STRING_TYPE,
                "Values" : ["IP", "SIG4ORIP", "SIG4ANDIP"],
                "Default" : "IP"
            },
            {
                "Names" : "CloudFront",
                "Children" : [
                    {
                        "Names" : "AssumeSNI",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "EnableLogging",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "CountryGroups",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    },
                    {
                        "Names" : "CustomHeaders",
                        "Types" : ARRAY_OF_ANY_TYPE,
                        "Default" : []
                    },
                    {
                        "Names" : "Mapping",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "Compress",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Certificate",
                "Children" : certificateChildConfiguration
            },
            {
                "Names" : "MutualTLS",
                "Description" : "Configuration for enabling mutualTLS authentication for clients",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "CertificateAuthority",
                        "Description" : "The configuration for the certificate authority used to validate client certificates",
                        "Children" : [
                            {
                                "Names" : "Source",
                                "Description" : "The way to source the certificate authority details",
                                "Value" : [ "link", "filesetting" ],
                                "Default" : "filesetting"
                            },
                            {
                                "Names" : "Source:link",
                                "Description" : "Use a component to source the RootCA Value",
                                "Children" : [
                                    {
                                        "Names" : "Link",
                                        "Description" : "A link to a component that has tbe PEM file",
                                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                                    },
                                    {
                                        "Names" : "RootCACertAttribute",
                                        "Description" : "The attribute of the linked component which provides the certificate for the rootCA",
                                        "Types" : STRING_TYPE,
                                        "Default" : "ROOTCA_PEM"
                                    }
                                ]
                            },
                            {
                                "Names" : "Source:filesetting",
                                "Description" : "Use an asFile Setting on the apigateway for RootCA Public cert",
                                "Children" : [
                                    {
                                        "Names" : "FileName",
                                        "Description" : "The name of the asFile setting",
                                        "Types" : STRING_TYPE,
                                        "Default" : "rootCA.pem"
                                    }
                                ]
                            }
                        ]
                    }
                ]
            },
            {
                "Names" : "Publish",
                "Description" : "Deprecated - Please switch to the publishers configuration",
                "Children" : [
                    {
                        "Names" : "DnsNamePrefix",
                        "Types" : STRING_TYPE,
                        "Default" : "docs"
                    },
                    {
                        "Names" : "IPAddressGroups",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    }
                ]
            },
            {
                "Names" : "Publishers",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Links",
                        "SubObjects" : true,
                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                    },
                    {
                        "Names" : "Path",
                        "AttributeSet" : CONTEXTPATH_ATTRIBUTESET_TYPE
                    },
                    {
                        "Names" : "UsePathInName",
                        "Description" : "Name the Swagger Spec file using the path",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Mapping",
                "Children" : [
                    {
                        "Names" : "IncludeStage",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Security",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Alert",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Logging",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            },
            {
                "Names" : "Alerts",
                "SubObjects" : true,
                "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "LogMetrics",
                "SubObjects" : true,
                "Children" : logMetricChildrenConfiguration
            },
            {
                "Names" : "BasePathBehaviour",
                "Description" : "How to handle base paths provided in the spec",
                "Types" : STRING_TYPE,
                "Values" : [ "ignore", "prepend", "split" ],
                "Default" : "ignore"
            },
            {
                "Names" : "Tracing",
                "Children" : tracingChildConfiguration
            },
            {
                "Names" : "Image",
                "Description" : "Control the source of the image for the openapi specification",
                "Children" : [
                    {
                        "Names" : "Source",
                        "Description" : "The source of the image - registry: the local hamlet registry - url: an external public url - none: no source image",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true,
                        "Values" : [ "registry", "url", "none" ],
                        "Default" : "registry"
                    },
                    {
                        "Names" : "Source:url",
                        "Description" : "Url Source specific Configuration",
                        "Children" : [
                            {
                                "Names" : "Url",
                                "Description" : "The Url to the openapi file",
                                "Types" : STRING_TYPE
                            },
                            {
                                "Names" : "ImageHash",
                                "Description" : "The expected sha1 hash of the Url if empty any will be accepted",
                                "Types" : STRING_TYPE,
                                "Default" : ""
                            }
                        ]
                    }
                ]
            }
        ]
/]
