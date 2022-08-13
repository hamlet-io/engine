[#ftl]

[@addComponent
    type=CDN_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A content distribution network which provides caching and global distribution of content"
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
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "WAF",
                "Description" : "Configuration for Web Application Firewall on CDN",
                "AttributeSet" : WAF_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Pages",
                "Description" : "The default page to return for a given response",
                "Children" : [
                    {
                        "Names" : "Root",
                        "Description" : "The page to return when accessing the root url '/'",
                        "Types" : STRING_TYPE,
                        "Default" : "index.html"
                    }
                    {
                        "Names" : "Error",
                        "Description" : "The page to return when 4XX or 5XX response is returned from the origin - set to an empty string to disable",
                        "Types" : STRING_TYPE,
                        "Default" : "/index.html"
                    },
                    {
                        "Names" : "Denied",
                        "Description" : "The page to return when 403 HTTP response is returned from the origin - set to an empty string to disable",
                        "Types" : STRING_TYPE,
                        "Default" : ""
                    },
                    {
                        "Names" : "NotFound",
                        "Description" : "The page to return when 404 HTTP response is returned from the origin - set to an empty string to disable",
                        "Types" : STRING_TYPE,
                        "Default" : ""
                    }
                ]
            },
            {
                "Names" : "ErrorResponseOverrides",
                "Description" : "Error code specific overrides for origin responses based on HTTP codes",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "ErrorCode",
                        "Description" : "The code to trigger the response for",
                        "Types" : NUMBER_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "ResponseCode",
                        "Description" : "The HTTP Response code returned to the user",
                        "Types" : NUMBER_TYPE,
                        "Default" : 200
                    },
                    {
                        "Names" : "ResponsePagePath",
                        "Description" : "The path to return content from in the client response",
                        "Types" : STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "EnableLogging",
                "Description" : "Enable request logging for client requests sent to the CDN",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "CountryGroups",
                "Description" : "A list of Country Group reference Ids that will be used to restrict access",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : [ "Certificate", "Hostname" ],
                "Description" : "The hostname to use of the CDN",
                "Children" : certificateChildConfiguration
            },
            {
                "Names" : "AssumeSNI",
                "Description" : "Use TLS Server Name Identification to route clients requests to the CDN",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Profiles",
                "Description" : "Standard configuration profiles applied across components",
                "Children" : [
                    {
                        "Names" : "Security",
                        "Description": "Controls the TLS protocols using a SecurityProfile reference id",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Logging",
                        "Description" : "Controls log management",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=CDN_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addChildComponent
    type=CDN_ROUTE_COMPONENT_TYPE
    parent=CDN_COMPONENT_TYPE
    childAttribute="Routes"
    linkAttributes="Route"
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A path based route on the CDN instance"
            }
        ]
    attributes=[
        {
            "Names" : "Priority",
            "Description" : "The priority of this route, lower routes evaluated first",
            "Types": NUMBER_TYPE,
            "Default" : 100
        },
        {
            "Names" : "PathPattern",
            "Description" : "The path based pattern to match for this route to apply - one _default path pattern must be supplied",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Links",
            "SubObjects" : true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "CachePolicy",
            "Description" : "The Cache Policy to use Default - use the Default CDN policy or Custom for custom policy defined on the CDN",
            "Types" : STRING_TYPE,
            "Values": [ "Default", "Custom"],
            "Default" : "Default"
        },
        {
            "Names": "CachePolicy:Custom",
            "Description" : "Configuration for the Custom Cache policy",
            "Children" : [
                {
                    "Names" : "Id",
                    "Description" : "The Id of the CachePolicy",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Instance",
                    "Description" : "The instance id of the CachePolicy",
                    "Types" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "Version",
                    "Description" : "The version id of the CachePolicy",
                    "Types" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        },
        {
            "Names" : "ResponsePolicy",
            "Description" : "A Response Policy to use for the route",
            "Children" : [
                {
                    "Names" : "Id",
                    "Description" : "The Id of the origin in the CDN Origins",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Instance",
                    "Description" : "The instance id of the origin to use",
                    "Types" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "Version",
                    "Description" : "The version id of the origin to use",
                    "Types" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        },
        {
            "Names" : "OriginSource",
            "Description" : "Use an origin for the route only ( defined under the Origin object) or CDN for subcomponent origins",
            "Types" : STRING_TYPE,
            "Values" : [ "Route", "CDN", "Placeholder"],
            "Default": "Route"
        },
        {
            "Names" : "OriginSource:CDN",
            "Description" : "Configuration for the CDN origin source",
            "Children" : [
                {
                    "Names" : "Id",
                    "Description" : "The Id of the origin in the CDN Origins",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Instance",
                    "Description" : "The instance id of the origin to use",
                    "Types" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "Version",
                    "Description" : "The version id of the origin to use",
                    "Types" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        },
        {
            "Names" : [ "OriginSource:Route", "Origin"],
            "Description" : "The origin the route forwards requests to",
            "AttributeSet" : CDNORIGIN_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "CachingTTL",
            "Description" : "Default Time To Live values for cache management",
            "AttributeSet" : CDNTTL_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "Compress",
            "Description": "Compress content from the origin to the client using the CDN",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "InvalidateOnUpdate",
            "Description" : "Clear the CDN cache on deployment updates to the CDN",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        }
        {
            "Names" : "RedirectAliases",
            "Description" : "Redirect secondary domains to the primary domain name ",
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                }
                {
                    "Names" : "RedirectVersion",
                    "Types" : STRING_TYPE,
                    "Default" : "v1"
                }
            ]
        },
        {
            "Names" : "EventHandlers",
            "Description" : "Attach a function to a stage in the CDN request workflow",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Tier",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Component",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : [ "SubComponent", "Function" ],
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Type",
                    "Types" : STRING_TYPE,
                    "Values" : [ LAMBDA_FUNCTION_COMPONENT_TYPE],
                    "Default" : LAMBDA_FUNCTION_COMPONENT_TYPE
                },
                {
                    "Names" : "Instance",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Version",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Action",
                    "Description" : "The action in the workflow that the function handles",
                    "Types" : STRING_TYPE,
                    "Values" : [ "viewer-request", "viewer-response", "origin-request", "origin-response" ],
                    "Mandatory" : true
                },
                {
                    "Names" : "Enabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                }
            ]
        }
    ]
/]

[@addChildComponent
    type=CDN_CACHE_POLICY_COMPONENT_TYPE
    parent=CDN_COMPONENT_TYPE
    childAttribute="CachePolicies"
    linkAttributes="CachePolicy"
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A policy for how content should be cached"
            }
        ]
    attributes=[
        {
            "Names" : "Cookies",
            "Description" : "A list of cookie names that will be included in cache entry ( _all - all cookies )",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : ["_all"]
        },
        {
            "Names" : "Headers",
            "Description" : "A list of header names that will be included in the cache entry ( _all - all cookies)",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "QueryParams",
            "Description" : "A list of query parameter names to be included in the cache entry ( _all - all parameters )",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : ["_all"]
        },
        {
            "Names" : "CompressionEncoding",
            "Description" : "A list of compression processes that are normalised and included in the cache policy",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Values" : [ "gzip", "brotli"],
            "Default": [ "gzip", "brotli" ]
        },
        {
            "Names" : "Methods",
            "Description" : "A list of HTTP methods which will allow caching",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Values" : [ "GET", "HEAD", "OPTIONS" ],
            "Default" : [ "GET", "HEAD" ]
        },
        {
            "Names" : "TTL",
            "Description" : "Default Time To Live values for cache management",
            "AttributeSet" : CDNTTL_ATTRIBUTESET_TYPE
        }
    ]
/]

[@addChildComponent
    type=CDN_RESPONSE_POLICY_COMPONENT_TYPE
    parent=CDN_COMPONENT_TYPE
    childAttribute="ResponsePolicys"
    linkAttributes="ResponsePolicy"
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A policy to control how the CDN controls responses"
            }
        ]
    attributes=[
        {
            "Names" : "HeaderInjection",
            "Description" : "Include headers as part of the response",
            "Children" : [
                {
                    "Names": "CORS",
                    "Description" : "Manage the CORS Headers that will be included",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Description" : "Manage CORS responses from the CDN",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "PreferOrigin",
                            "Description" : "Prefer the headers provided by the origin over these",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "AccessControlAllowCredentials",
                            "Description" : "Include the Allow Credentials header",
                            "Types": BOOLEAN_TYPE,
                            "Default": false
                        },
                        {
                            "Names": "AccessControlAllowMethods",
                            "Description" : "A list of methods permitted on this route",
                            "Types": ARRAY_OF_STRING_TYPE,
                            "Default": [ "ALL" ]
                        },
                        {
                            "Names": "AccessControlAllowHeaders",
                            "Description" : "A list of methods permitted on this route",
                            "Types": ARRAY_OF_STRING_TYPE,
                            "Default": [ "*" ]
                        },
                        {
                            "Names" : "AccessControlAllowOrigins",
                            "Description" : "A list of origins permitted on this route",
                            "Types": ARRAY_OF_STRING_TYPE,
                            "Default" : [
                                "*"
                            ]
                        },
                        {
                            "Names" : "AccessControlExposeHeaders",
                            "Description" : "A list of headers that will be exposed",
                            "Types": ARRAY_OF_STRING_TYPE,
                            "Default" : [
                                "*"
                            ]
                        },
                        {
                            "Names" : "AccessControlMaxAgeSec",
                            "Description" : "How long the CORS headers are cached for",
                            "Types" : NUMBER_TYPE,
                            "Default" : 3600
                        }
                    ]
                },
                {
                    "Names": "Security",
                    "Description" : "Manage the standard security that will be included",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Description" : "Manage Security header repsponses with the CDN",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "PreferOrigin",
                            "Description" : "Prefer the headers provided by the origin over these",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "ContentSecurityPolicy",
                            "Description" : "Include a ContentSecurityPolicy header",
                            "Types": STRING_TYPE,
                            "Default" : ""
                        },
                        {
                            "Names": "ContentTypeOptions",
                            "Description" : "Set the X-Content-Type-Options to nosniff",
                            "Types": BOOLEAN_TYPE,
                            "Default": true
                        },
                        {
                            "Names" : "FrameOptions",
                            "Description" : "Control the X-Frame-Options header",
                            "Types": STRING_TYPE,
                            "Values" : [ "DENY", "SAMEORIGIN"],
                            "Default" : "DENY"
                        },
                        {
                            "Names" : "ReferrerPolicy",
                            "Description" : "Set the Referrer-Policy that is used",
                            "Types": STRING_TYPE,
                            "Values" : [
                                "no-referrer",
                                "no-referrer-when-downgrade",
                                "origin",
                                "origin-when-cross-origin",
                                "same-origin",
                                "strict-origin",
                                "strict-origin-when-cross-origin"
                                "unsafe-url"
                            ],
                            "Default" : "strict-origin-when-cross-origin"
                        }
                    ]
                },
                {
                    "Names" : "StrictTransportSecurity",
                    "Description" : "Set how HSTS manages requests",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Description" : "Enable the inclusion of HSTS",
                            "Types": BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "PreferOrigin",
                            "Description" : "Prefer the headers provided by the origin over these",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names": "MaxAge",
                            "Description": "How long the HSTS policy should be valid for",
                            "Types": NUMBER_TYPE,
                            "Default": 31536000
                        },
                        {
                            "Names": "IncludeSubdomains",
                            "Description": "Should subdomains be included in the policy",
                            "Type": BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                },
                {
                    "Names": "Additional",
                    "Default": "Custom headers to include in the responses",
                    "SubObjects": true,
                    "Children" : [
                        {
                            "Names" : "Name",
                            "Description" : "The name of the header ( object id used if not provided)",
                            "Types": STRING_TYPE
                        },
                        {
                            "Names": "Value",
                            "Description" : "The value of the header",
                            "Types": STRING_TYPE,
                            "Mandatory": true
                        },
                        {
                            "Names" : "PreferOrigin",
                            "Description" : "Prefer the origin value over this value",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                }
            ]
        }
    ]
/]

[@addChildComponent
    type=CDN_ORIGIN_COMPONENT_TYPE
    parent=CDN_COMPONENT_TYPE
    childAttribute="Origins"
    linkAttributes="Origin"
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A Origin which serves content"
            }
        ]
    attributes=getAttributeSet(CDNORIGIN_ATTRIBUTESET_TYPE).Attributes
/]
