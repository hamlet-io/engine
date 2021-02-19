[#ftl]

[@addComponentDeployment
    type=CDN_COMPONENT_TYPE
    defaultGroup="solution"
/]

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
                "Children" : wafChildConfiguration
            },
            {
                "Names" : "Pages",
                "Children" : [
                    {
                        "Names" : "Root",
                        "Types" : STRING_TYPE,
                        "Default" : "index.html"
                    }
                    {
                        "Names" : "Error",
                        "Types" : STRING_TYPE,
                        "Default" : "/index.html"
                    },
                    {
                        "Names" : "Denied",
                        "Types" : STRING_TYPE,
                        "Default" : ""
                    },
                    {
                        "Names" : "NotFound",
                        "Types" : STRING_TYPE,
                        "Default" : ""
                    }
                ]
            },
            {
                "Names" : "ErrorResponseOverrides",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "ErrorCode",
                        "Types" : NUMBER_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "ResponseCode",
                        "Types" : NUMBER_TYPE,
                        "Default" : 200
                    },
                    {
                        "Names" : "ResponsePagePath",
                        "Types" : STRING_TYPE
                    }
                ]
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
                "Names" : "Certificate",
                "Children" : certificateChildConfiguration
            },
            {
                "Names" : "AssumeSNI",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Security",
                        "Types" : STRING_TYPE,
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
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Origin",
            "Children" : [
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
            "Children" : [
                {
                    "Names" : "Default",
                    "Types" : NUMBER_TYPE,
                    "Default" : 600
                },
                {
                    "Names" : "Maximum",
                    "Types" : NUMBER_TYPE,
                    "Default" : 31536000
                },
                {
                    "Names" : "Minimum",
                    "Types" : NUMBER_TYPE,
                    "Default" : 0
                }
            ]
        },
        {
            "Names" : "Compress",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "InvalidateOnUpdate",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        }
        {
            "Names" : "RedirectAliases",
            "Description" : "Redirect secondary domains to the primary domain name",
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
            "Description" : "Attach a function to a stage in the Cloudfront Processing",
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
                    "Names" : "Function",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
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
                    "Types" : STRING_TYPE,
                    "Values" : [ "viewer-request", "viewer-response", "origin-request", "origin-response" ],
                    "Mandatory" : true
                }
            ]
        }
    ]
/]
