[#ftl]

[#assign componentConfiguration +=
    {
        S3_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "HTTP based object storage service"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Lifecycle",
                    "Children" : [
                        {
                            "Names" : "Expiration",
                            "Types" : [STRING_TYPE, NUMBER_TYPE],
                            "Description" : "Provide either a date or a number of days"
                        },
                        {
                            "Names" : "Offline",
                            "Types" : [STRING_TYPE, NUMBER_TYPE],
                            "Description" : "Provide either a date or a number of days"
                        },
                        {
                            "Names" : "Versioning",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                },
                {
                    "Names" : "Website",
                    "Children" : [
                        {
                            "Names": "Index",
                            "Type" : STRING_TYPE,
                            "Default": "index.html"
                        },
                        {
                            "Names": "Error",
                            "Type" : STRING_TYPE,
                            "Default": ""
                        }
                    ]
                },
                {
                    "Names" : "PublicAccess",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "Permissions",
                            "Type" : STRING_TYPE,
                            "Values" : ["ro", "wo", "rw"],
                            "Default" : "ro"
                        },
                        {
                            "Names" : "IPAddressGroups",
                            "Type" : ARRAY_OF_STRING_TYPE,
                            "Default" : [ "_localnet" ]
                        },
                        {
                            "Names" : "Paths",
                            "Type" : ARRAY_OF_STRING_TYPE,
                            "Default" : [ ]
                        }
                    ]
                },
                {
                    "Names" : "Style",
                    "Type" : STRING_TYPE,
                    "Description" : "TODO(mfl): Think this can be removed"
                },
                {
                    "Names" : "Notifications",
                    "Subobjects" : true,
                    "Children" : s3NotificationChildConfiguration
                },
                {
                    "Names" : "CORSBehaviours",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
                },
                {
                    "Names" : "Replication",
                    "Children" : [
                        {
                            "Names" : "Prefixes",
                            "Type" : ARRAY_OF_STRING_TYPE,
                            "Default" : [ "" ]
                        },
                        {
                            "Names" : "Enabled",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        }
                    ]
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                }
            ]
        }
    }]
