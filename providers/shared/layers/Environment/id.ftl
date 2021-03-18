[#ftl]

[@addLayer
    type=ENVIRONMENT_LAYER_TYPE
    referenceLookupType=ENVIRONMENT_LAYER_REFERENCE_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "The environment layer"
        }
    ]
    inputFilterAttributes=[
            {
                "Id" : ENVIRONMENT_LAYER_TYPE,
                "Description" : "The environment"
            }
        ]
    attributes=[
        {
            "Names" : "Id",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Name",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Title",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Description",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Region",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Category",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "MultiAZ",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        }
        {
            "Names" : "Profiles",
            "Children" : [
                {
                    "Names" : "Deployment",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Policy",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        }
        {
            "Names" : "Operations",
            "Children" : [
                {
                    "Names" : "Expiration",
                    "Types" : NUMBER_TYPE,
                    "Default" : 7
                },
                {
                    "Names" : "Offline",
                    "Types" : NUMBER_TYPE
                },
                {
                    "Names" : "FlowLogs",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Types" : BOOLEAN_TYPE
                        },
                        {
                            "Names" : "Expiration",
                            "Types" : NUMBER_TYPE
                        }
                    ]
                },
                {
                    "Names" : "DeadLetterQueue",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "MaxReceives",
                            "Types" : NUMBER_TYPE,
                            "Default" : 3
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "Data",
            "Children" : [
                {
                    "Names" : "Expiration",
                    "Types" : NUMBER_TYPE
                },
                {
                    "Names" : "Offline",
                    "Types" : NUMBER_TYPE
                },
                {
                    "Names" : "Public",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : [ "IPAddressGroups", "IPWhitelist"],
                            "Types" : ARRAY_OF_STRING_TYPE,
                            "Default" : []
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "DomainBehaviours",
            "Children" : [
                {
                    "Names" : "Segment",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "RDS",
            "Children" : [
                {
                    "Names" : "AutoMinorVersionUpgrade",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                }
            ]
        },
        {
            "Names" : "FlowLogs",
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Description" : "Deprecated - here to override automatically added enabled attribute",
                    "Types"  : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Expiration",
                    "Types" : NUMBER_TYPE,
                    "Default" : 7
                }
            ]
        },
        {
            "Names" : "OSPatching",
            "Children" : osPatchingChildConfiguration
        }
    ]
/]
