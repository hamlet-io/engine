[#ftl]

[@addComponentDeployment
    type=S3_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=S3_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "HTTP based object storage service"
            }
        ]
    attributes=
        [
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
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    }
                ]
            },
            {
                "Names" : "Website",
                "Children" : [
                    {
                        "Names": "Index",
                        "Types" : STRING_TYPE,
                        "Default": "index.html"
                    },
                    {
                        "Names": "Error",
                        "Types" : STRING_TYPE,
                        "Default": ""
                    }
                ]
            },
            {
                "Names" : "PublicAccess",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "Permissions",
                        "Types" : STRING_TYPE,
                        "Values" : ["ro", "wo", "rw"],
                        "Default" : "ro"
                    },
                    {
                        "Names" : "IPAddressGroups",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ "_localnet" ]
                    },
                    {
                        "Names" : "Paths",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ ]
                    }
                ]
            },
            {
                "Names" : [ "Extensions" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Style",
                "Types" : STRING_TYPE,
                "Description" : "TODO(mfl): Think this can be removed"
            },
            {
                "Names" : "Notifications",
                "SubObjects" : true,
                "Children" : s3NotificationChildConfiguration
            },
            {
                "Names" : "CORSBehaviours",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Replication",
                "Children" : [
                    {
                        "Names" : "Prefixes",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ "" ]
                    },
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Encryption",
                "Children" : s3EncryptionChildConfiguration
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "InventoryReports",
                "Description" : "Provides a listing of all objects in the store on a schedule basis",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Destination",
                        "Description" : "The destination of the reports",
                        "Children" : [
                            {
                                "Names" : "Type",
                                "Values" : [ "self", "link" ],
                                "Default" : "self",
                                "Types" : STRING_TYPE,
                                "Description" : "The type of destination for the report"
                            },
                            {
                                "Names" : "Links",
                                "Description" : "If destination type is link these are the links that will be used",
                                "SubObjects" : true,
                                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                            }
                        ]
                    },
                    {
                        "Names" : "IncludeVersions",
                        "Description" : "Include versions of objects in report",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "InventoryPrefix",
                        "Description" : "A filter prefix to generate the report for",
                        "Types" : STRING_TYPE,
                        "Default" : ""
                    },
                    {
                        "Names" : "InventoryFormat",
                        "Description" : "The filter for the inventory report",
                        "Types" : STRING_TYPE,
                        "Default" : "CSV"
                    }
                    {
                        "Names" : "DestinationPrefix",
                        "Description" : "A prefix to store the report under in the destination",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true
                    }
                    {
                        "Names" : "Schedule",
                        "Description" : "How often to generate the report",
                        "Values" : [ "Daily", "Weekly" ],
                        "Types" : STRING_TYPE,
                        "Default" : "Daily"
                    }
                ]
            }
        ]
/]
