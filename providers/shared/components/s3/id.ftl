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
                "Subobjects" : true,
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
                "Subobjects" : true,
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
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
/]
