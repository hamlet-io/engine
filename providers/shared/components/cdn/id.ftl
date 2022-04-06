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
                        "Description" : "The HTTP Respose code returned to the user",
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
            "Names" : "Origin",
            "Description" : "The service which provides the content for the cdn to distribute",
            "Children" : [
                {
                    "Names" : "ConnectionTimeout",
                    "Description" : "How long to wait until a response is received from the origin",
                    "Types" : NUMBER_TYPE,
                    "Default" : 30
                },
                {
                    "Names" : "TLSProtocols",
                    "Description" : "When using a TLS backend the protocols the CDN will use as a client",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Values" : [ "TLSv1.2", "TLSv1.1", "TLSv1", "SSLv3" ],
                    "Default" : [ "TLSv1.2" ]
                },
                {
                    "Names" : "BasePath",
                    "Description" : "The base path at the origin destination",
                    "Types" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "Link",
                    "Mandatory" : true,
                    "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                }
            ]
        },
        {
            "Names" : "CachingTTL",
            "Description" : "Default Time To Live values for cache management",
            "Children" : [
                {
                    "Names" : "Default",
                    "Description" : "The default cache time when the origin has not specified a time - seconds",
                    "Types" : NUMBER_TYPE,
                    "Default" : 600
                },
                {
                    "Names" : "Maximum",
                    "Description" : "The maximum time that an origin can specify to cache content - seconds',
                    "Types" : NUMBER_TYPE,
                    "Default" : 31536000
                },
                {
                    "Names" : "Minimum",
                    "Description" : "The minimum time that an origin can specify to cache content - seconds",
                    "Types" : NUMBER_TYPE,
                    "Default" : 0
                }
            ]
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
                    "Values" : [ LAMBDA_FUNCTION_COMPONENT_TYPE]
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
