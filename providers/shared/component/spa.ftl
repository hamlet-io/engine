[#ftl]

[@addComponent
    type=SPA_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Object stored hosted web application with content distribution management"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "application"
            }
        ]
/]

[@addComponentResourceGroup
    type=SPA_COMPONENT_TYPE
    attributes=
        [
            {
                "Names" : ["Fragment", "Container"],
                "Type" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "Links",
                "Type" : OBJECT_TYPE,
                "Default" : {}
            },
            {
                "Names" : "WAF",
                "Children" : wafChildConfiguration
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
                        "Names" : "ErrorPage",
                        "Type" : STRING_TYPE,
                        "Default" : "/index.html"
                    },
                    {
                        "Names" : "DeniedPage",
                        "Type" : STRING_TYPE,
                        "Default" : ""
                    },
                    {
                        "Names" : "NotFoundPage",
                        "Type" : STRING_TYPE,
                        "Default" : ""
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
                        "Default" : true
                    },
                    {
                        "Names" : "RedirectAliases",
                        "Description" : "Redirect secondary domains to the primary domain name",
                        "Children" : [
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
                    },
                    {
                        "Names" : "Paths",
                        "Subobjects" : true,
                        "Description" : "Additional path based routes to other components",
                        "Children" : [
                            {
                                "Names" : "PathPattern",
                                "Type" : STRING_TYPE,
                                "Mandatory" : true
                            },
                            {
                                "Names" : "Link",
                                "Children" : linkChildrenConfiguration,
                                "Mandatory" : true
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
                            }
                        ]
                    }
                ]
            },
            {
                "Names" : "Certificate",
                "Children" : certificateChildConfiguration
            },
            {
                "Names" : "Profiles",
                "Children" : profileChildConfiguration + [
                    {
                        "Names" : "Security",
                        "Type" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            }
        ]
/]
