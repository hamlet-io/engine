[#ftl]

[@addReference 
    type=ENVIRONMENT_REFERENCE_TYPE
    pluralType="Environments"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A instance of a product"
            }
        ]
    attributes=[
        {
            "Names" : "Id",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Name",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Title",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Description",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Category",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "MultiAZ",
            "Type" : BOOLEAN_TYPE,
            "Default" : false
        }
        {
            "Names" : "Profiles",
            "Children" : [
                {
                    "Names" : "Deployment",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        }
        {
            "Names" : "Operations",
            "Children" : [
                {
                    "Names" : "Expiration",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "Offline",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "FlowLogs",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Type" : BOOLEAN_TYPE
                        }
                    ]
                },
                {
                    "Names" : "DeadLetterQueue",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "MaxReceives",
                            "Type" : NUMBER_TYPE,
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
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "Offline",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "Public",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : [ "IPAddressGroups", "IPWhitelist"],
                            "Type" : ARRAY_OF_STRING_TYPE,
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
                    "Type" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "RDS",
            "Children" : [
                {
                    "Names" : "AutoMinorVersionUpgrade",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                }
            ]
        },
        {
            "Names" : "FlowLogs",
            "Children" : [
                {
                    "Names" : "Expiration",
                    "Type" : NUMBER_TYPE,
                    "Default" : 7
                }
            ]
        }
    ]
/]