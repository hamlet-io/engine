[#ftl]

[@addLayer
    type=SEGMENT_LAYER_TYPE
    referenceLookupType=SEGMENT_LAYER_REFERENCE_TYPE
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
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Modules",
            "Subobjects" : true,
            "Children"  : moduleReferenceConfiguration
        },
        {
            "Names" : "Profiles",
            "Children" : [
                {
                    "Names" : "Deployment",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Policy",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        },
        {
            "Names" : "IPAddressGroups",
            "Type" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : [ "Bastion", "SSH" ],
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                }
                {
                    "Names" : "Active",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "IPAddressGroups",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        },
        {
            "Names" : "Operations",
            "Children" : [
                {
                    "Names" : "FlowLogs",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Type"  : BOOLEAN_TYPE
                        },
                        {
                            "Names" : "Expiration",
                            "Type" : [ NUMBER_TYPE, STRING_TYPE ]
                        }
                    ]
                },
                {
                    "Names" : "Expiration",
                    "Type" : [ NUMBER_TYPE, STRING_TYPE]
                },
                {
                    "Names" : "Offline",
                    "Type" : [ NUMBER_TYPE, STRING_TYPE]
                }
            ]
        },
        {
            "Names" : "Network",
            "Children" : [
                {
                    "Names" : "Tiers",
                    "Children" : [
                        {
                            "Names" : "Order",
                            "Type" : ARRAY_OF_STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "Zones",
                    "Children" : [
                        {
                            "Names" : "Order",
                            "Type" : ARRAY_OF_STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "InternetAccess",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "DNSSupport",
                    "Type" : BOOLEAN_TYPE
                },
                {
                    "Names" : "DNSHostnames",
                    "Type" : BOOLEAN_TYPE
                },
                {
                    "Names" : "CIDR",
                    "Children" : [
                        {
                            "Names" : "Address",
                            "Type" : STRING_TYPE,
                            "Default" : ""
                        },
                        {
                            "Names" : "Mask",
                            "Type" : NUMBER_TYPE,
                            "Default" : 0
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "NAT",
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Hosted",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "MultiAZ",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                }
            ]
        },
        {
            "Names" : "RotateKeys",
            "Type" : BOOLEAN_TYPE,
            "Default" : true
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
        }
        {
            "Names" : "S3",
            "Children" : [
                {
                    "Names" : "IncludeTenant",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                }
            ]
        },
        {
            "Names" : "Tiers",
            "Children" : [
                {
                    "Names" : "Order",
                    "Type" : ARRAY_OF_STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Data",
            "Children" : [
                {
                    "Names" : "Public",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : [ "IPAddressGroups", "IPWhitelist" ],
                            "Type" : ARRAY_OF_STRING_TYPE,
                            "Default" : []
                        }
                    ]
                },
                {
                    "Names" : "Expiration",
                    "Types" : [ NUMBER_TYPE, STRING_TYPE ]
                },
                {
                    "Names" : "Offline",
                    "Types" : [ NUMBER_TYPE, STRING_TYPE ]
                }
            ]
        }
    ]
/]
