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
                "Names" : "DeploymentGroup",
                "Type" : STRING_TYPE,
                "Default" : "solution"
            },
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
                "Names" : "Pages",
                "Children" : [
                    {
                        "Names" : "Root",
                        "Type" : STRING_TYPE,
                        "Default" : "index.html"
                    }
                    {
                        "Names" : "Error",
                        "Type" : STRING_TYPE,
                        "Default" : "/index.html"
                    },
                    {
                        "Names" : "Denied",
                        "Type" : STRING_TYPE,
                        "Default" : ""
                    },
                    {
                        "Names" : "NotFound",
                        "Type" : STRING_TYPE,
                        "Default" : ""
                    }
                ]
            },
            {
                "Names" : "ErrorResponseOverrides",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "ErrorCode",
                        "Type" : NUMBER_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "ResponseCode",
                        "Type" : NUMBER_TYPE,
                        "Default" : 200
                    },
                    {
                        "Names" : "ResponsePagePath",
                        "Type" : STRING_TYPE
                    }
                ]
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
                "Names" : "Certificate",
                "Children" : certificateChildConfiguration
            },
            {
                "Names" : "AssumeSNI",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Security",
                        "Type" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            }
        ]
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
            "Description" : "The path based pattern to match for this route to apply",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Origin",
            "Children" : [
                {
                    "Names" : "BasePath",
                    "Description" : "The base path at the origin destination",
                    "Type" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "Link",
                    "Children" : linkChildrenConfiguration,
                    "Mandatory" : true
                }
            ]
        },
        {
            "Names" : "CachingTTL",
            "Children" : [
                {
                    "Names" : "Default",
                    "Type" : NUMBER_TYPE,
                    "Default" : 600
                },
                {
                    "Names" : "Maximum",
                    "Type" : NUMBER_TYPE,
                    "Default" : 31536000
                },
                {
                    "Names" : "Minimum",
                    "Type" : NUMBER_TYPE,
                    "Default" : 0
                }
            ]
        },
        {
            "Names" : "Compress",
            "Type" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "InvalidateOnUpdate",
            "Type" : BOOLEAN_TYPE,
            "Default" : true
        }
        {
            "Names" : "RedirectAliases",
            "Description" : "Redirect secondary domains to the primary domain name",
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                }
                {
                    "Names" : "RedirectVersion",
                    "Type" : STRING_TYPE,
                    "Default" : "v1"
                }
            ]
        },
        {
            "Names" : "EventHandlers",
            "Description" : "Attach a function to a stage in the Cloudfront Processing",
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "Tier",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Component",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Function",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Instance",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Version",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Action",
                    "Type" : STRING_TYPE,
                    "Values" : [ "viewer-request", "viewer-response", "origin-request", "origin-response" ],
                    "Mandatory" : true
                }
            ]
        }
    ]
/]
