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
            "Names" : "Category",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Modules",
            "Subobjects" : true,
            "Children"  : moduleReferenceConfiguration
        },
        {
            "Names" : "Plugins",
            "Subobjects" : true,
            "Children" : pluginReferenceConfiguration
        },
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
        },
        {
            "Names" : "IPAddressGroups",
            "Types" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : [ "Bastion", "SSH" ],
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                }
                {
                    "Names" : "Active",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "IPAddressGroups",
                    "Types" : ARRAY_OF_STRING_TYPE,
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
                            "Types"  : BOOLEAN_TYPE
                        },
                        {
                            "Names" : "Expiration",
                            "Types" : [ NUMBER_TYPE, STRING_TYPE ]
                        }
                    ]
                },
                {
                    "Names" : "Expiration",
                    "Types" : [ NUMBER_TYPE, STRING_TYPE]
                },
                {
                    "Names" : "Offline",
                    "Types" : [ NUMBER_TYPE, STRING_TYPE]
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
                            "Types" : ARRAY_OF_STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "Zones",
                    "Children" : [
                        {
                            "Names" : "Order",
                            "Types" : ARRAY_OF_STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "InternetAccess",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "DNSSupport",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "DNSHostnames",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "CIDR",
                    "Children" : [
                        {
                            "Names" : "Address",
                            "Types" : STRING_TYPE,
                            "Default" : ""
                        },
                        {
                            "Names" : "Mask",
                            "Types" : NUMBER_TYPE,
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
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Hosted",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "MultiAZ",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                }
            ]
        },
        {
            "Names" : "RotateKeys",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
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
        }
        {
            "Names" : "S3",
            "Children" : [
                {
                    "Names" : "IncludeTenant",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                }
            ]
        },
        {
            "Names" : "Tiers",
            "Children" : [
                {
                    "Names" : "Order",
                    "Types" : ARRAY_OF_STRING_TYPE
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
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : [ "IPAddressGroups", "IPWhitelist" ],
                            "Types" : ARRAY_OF_STRING_TYPE,
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
