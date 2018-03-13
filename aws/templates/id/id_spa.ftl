[#-- SPA --]

[#assign componentConfiguration +=
    {
        "spa" : [
            {
                "Name" : "Links",
                "Default" : {}
            },
            {
                "Name" : "WAF",
                "Children" : [
                    {
                        "Name" : "Enabled",
                        "Default" : true
                    },
                    {
                        "Name" : "IPAddressGroups",
                        "Default" : []
                    },
                    {
                        "Name" : "Default"
                    },
                    {
                        "Name" : "RuleDefault"
                    }
                ]
            },
            {
                "Name" : "CloudFront",
                "Children" : [
                    {
                        "Name" : "AssumeSNI",
                        "Default" : true
                    },
                    {
                        "Name" : "EnableLogging",
                        "Default" : true
                    },
                    {
                        "Name" : "CountryGroups",
                        "Default" : []
                    },
                    {
                        "Name" : "ErrorPage",
                        "Default" : "/index.html"
                    },
                    {
                        "Name" : "DeniedPage",
                        "Default" : ""
                    },
                    {
                        "Name" : "NotFoundPage",
                        "Default" : ""
                    },
                    {
                        "Name" : "CachingTTL",
                        "Children" : [
                            {
                                "Name" : "Default",
                                "Default" : 600
                            },
                            {
                                "Name" : "Maximum",
                                "Default" : 31536000
                            },
                            {
                                "Name" : "Minimum",
                                "Default" : 0
                            }
                        ]
                    }
                ]
            },
            {
                "Name" : "Certificate",
                "Children" : [
                    {
                        "Name" : "Enabled",
                        "Default" : true
                    },
                    {
                        "Name" : "*"
                    }
                ]
            }
        ]
    }]
    
[#function getSPAState occurrence]
    [#return
        {
            "Resources" : {},
            "Attributes" : {}
        }
    ]
[/#function]

