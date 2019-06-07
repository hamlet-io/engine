[#-- Components --]
[#assign BASELINE_COMPONENT_TYPE = "baseline" ]
[#assign BASELINE_DATA_COMPONENT_TYPE = "baselinedata" ]
[#assign BASELINE_KEY_COMPONENT_TYPE = "baselinekey" ]

[#assign componentConfiguration +=
    {
        BASELINE_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A set of resources required for every segment deployment"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Active",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Seed",
                    "Children" : [
                        {
                            "Names" : "Length",
                            "Type" : NUMBER_TYPE,
                            "Default" : 10
                        }
                    ]
                }
            ],
            "Components" : [
                {
                    "Type" : BASELINE_DATA_COMPONENT_TYPE,
                    "Component" : "DataBuckets",
                    "Link" : ["DataBucket"]
                },
                {
                    "Type" : BASELINE_KEY_COMPONENT_TYPE,
                    "Component" : "Keys",
                    "Link" : ["Key"]
                }
            ]
        },
        BASELINE_DATA_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A segment shared data store"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Role",
                    "Type" : STRING_TYPE,
                    "Values" : [ "appdata", "operations" ],
                    "Mandatory" : true
                },
                {
                    "Names" : "Lifecycles",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "Prefix",
                            "Types" : STRING_TYPE,
                            "Description" : "The prefix to apply the lifecycle to"
                        }
                        {
                            "Names" : "Expiration",
                            "Types" : [STRING_TYPE, NUMBER_TYPE],
                            "Description" : "Provide either a date or a number of days",
                            "Default" : "_operations"
                        },
                        {
                            "Names" : "Offline",
                            "Types" : [STRING_TYPE, NUMBER_TYPE],
                            "Description" : "Provide either a date or a number of days",
                            "Default" : "_operations"
                        }
                    ]
                },
                {
                    "Names" : "Versioning",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Notifications",
                    "Subobjects" : true,
                    "Children" : s3NotificationChildConfiguration
                }
            ]
        },
        BASELINE_KEY_COMPONENT_TYPE : {
                "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "Shared security keys for a segment"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Engine",
                    "Type" : STRING_TYPE,
                    "Values" : [ "cmk", "ssh", "oai" ],
                    "Mandatory" : true
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                }
            ]
        }
    }]
