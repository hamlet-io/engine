[#ftl]

[@addComponentDeployment
    type=DATAFEED_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=DATAFEED_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A service which feeds data into the ES index currently based on kineses data firehose"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            }
        ]
    attributes=
        [
            {
                "Names" : "ElasticSearch",
                "Children" : [
                    {
                        "Names" : "IndexPrefix",
                        "Types" : STRING_TYPE,
                        "Description" : "The prefix applied to generate the index name ( if not using roll over this will be the index name)"
                    },
                    {
                        "Names" : "IndexRotation",
                        "Types" : STRING_TYPE,
                        "Description" : "When to rotate the index ( the timestamp will be appended to the indexprefix)",
                        "Values" : [ "NoRotation", "OneDay", "OneHour", "OneMonth", "OneWeek" ],
                        "Default" : "OneMonth"
                    },
                    {
                        "Names" : "DocumentType",
                        "Types" : STRING_TYPE,
                        "Description" : "The document type used when creating the document"
                    }
                ]
            },
            {
                "Names" : "Bucket",
                "Children" : [
                    {
                        "Names" : "Prefix",
                        "Types" : STRING_TYPE,
                        "Description" : "The prefix appeneded to the object name when processed succesfully",
                        "Default" : "data/"
                    },
                    {
                        "Names" : "ErrorPrefix",
                        "Types" : STRING_TYPE,
                        "Description" : "The prefix appeneded to the object name when processing failed",
                        "Default" : "error/"
                    },
                    {
                        "Names" : "Include",
                        "Description" : "Deployment specific details to add to prefix",
                        "Children" : [
                            {
                                "Names" : "Order",
                                "Description" : "The order of the included prefixes",
                                "Types" : ARRAY_OF_STRING_TYPE,
                                "Default" : [ "AccountId", "ComponentPath" ]
                            }
                            {
                                "Names" : "AccountId",
                                "Description" : "The deployment account id",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : false
                            },
                            {
                                "Names" : "ComponentPath",
                                "Description" : "The full component path defaults",
                                "Type": BOOLEAN_TYPE,
                                "Default" : false
                            }
                        ]
                    }
                ]
            },
            {
                "Names" : "Buffering",
                "Description" : "How long data should be bufferred before being deliverd to ES",
                "Children" : [
                    {
                        "Names" : "Interval",
                        "Types" : NUMBER_TYPE,
                        "Description" : "The time in seconds before data should be delivered",
                        "Default" : 60
                    },
                    {
                        "Names" : "Size",
                        "Types" : NUMBER_TYPE,
                        "Description" : "The size in MB before data should be delivered",
                        "Default" : 1
                    }
                ]
            },
            {
                "Names" : "Logging",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Encrypted",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Logging",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            },
            {
                "Names" : "Backup",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "FailureDuration",
                        "Types" : NUMBER_TYPE,
                        "Description" : "The time in seconds that the data feed will attempt to deliver the data before it is sent to backup",
                        "Default" : 3600
                    },
                    {
                        "Names" : "Policy",
                        "Types" : STRING_TYPE,
                        "Description" : "The backup policy to apply to records",
                        "Values" : [ "AllDocuments", "FailedDocumentsOnly" ],
                        "Default" : "FailedDocumentsOnly"
                    }
                ]
            },
            {
                "Names" : "Destination",
                "Children" : [
                    {
                        "Names" : "Link",
                        "Children" : linkChildrenConfiguration,
                        "Mandatory" : true
                    }
                ]
            }
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "LogWatchers",
                "Subobjects" : true,
                "Children" : logWatcherChildrenConfiguration
            }
        ]
/]
