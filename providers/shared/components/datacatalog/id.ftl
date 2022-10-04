[#ftl]

[@addComponent
    type=DATACATALOG_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Defines a catalog of data sources"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            }
        ]
    attributes=
        [
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            }
        ]
/]

[@addComponentDeployment
    type=DATACATALOG_COMPONENT_TYPE
    defaultGroup="solution"
/]


[@addChildComponent
    type=DATACATALOG_TABLE_COMPONENT_TYPE
    parent=DATACATALOG_COMPONENT_TYPE
    childAttribute="Tables"
    linkAttributes=["Table"]
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A Tabular data store in the catalog"
            }
        ]
    attributes=
        [
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Parameters",
                "Description" : "Additional key/value parameters to configure the table - Key of the object is used as key by default",
                "SubObjects" : true,
                "Children": [
                    {
                        "Names": "Enabled",
                        "Default" : "Include the parameter",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names": "Key",
                        "Description" : "The Key of the parameter",
                        "Types" : STRING_TYPE
                    },
                    {
                        "Names": "Value",
                        "Description" : "The value of the parameter",
                        "Types" : ANY_TYPE
                    }
                ]
            },
            {
                "Names" : "Source",
                "Description" : "The source of the data to reference in the catalog",
                "Children": [
                    {
                        "Names" : "Link",
                        "Description" : "A link to the data source",
                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                    },
                    {
                        "Names" : "Prefix",
                        "Description" : "If using a path based source a prefix to use as the start of the data source",
                        "Types" : STRING_TYPE,
                        "Default" : ""
                    },
                    {
                        "Names": "DecompressData",
                        "Description" : "If data is compressed it should be decompressed before processing",
                        "Types": BOOLEAN_TYPE,
                        "Default": true
                    }
                ]
            },
            {
                "Names": "Layout",
                "Description" : "The layout of the data in the table",
                "Children" : [
                    {
                        "Names": "Partitioning",
                        "Description" : "How data is partitioned within the layout - name is the key of the object by default",
                        "SubObjects" : true,
                        "Children": [
                            {
                                "Names" : "Enabled",
                                "Description": "Should the column be included",
                                "Types": BOOLEAN_TYPE,
                                "Default": true
                            },
                            {
                                "Names": "Name",
                                "Description": "The name of the column",
                                "Types": STRING_TYPE
                            },
                            {
                                "Names" : "Type",
                                "Description": "The data type of the column",
                                "Types": STRING_TYPE,
                                "Default" : ""
                            },
                            {
                                "Names": "Description",
                                "Description": "A descrpition of the column",
                                "Types": STRING_TYPE,
                                "Default" : ""
                            }
                        ]
                    },
                    {
                        "Names": "Columns",
                        "Description" : "The base columns in the data article - name is the key of the object by default",
                        "SubObjects": true,
                        "Children" : [
                            {
                                "Names" : "Enabled",
                                "Description": "Should the column be included",
                                "Types": BOOLEAN_TYPE,
                                "Default": true
                            },
                            {
                                "Names": "Name",
                                "Description": "The name of the column",
                                "Types": STRING_TYPE
                            },
                            {
                                "Names" : "Type",
                                "Description": "The data type of the column",
                                "Types": STRING_TYPE,
                                "Default" : ""
                            },
                            {
                                "Names": "Description",
                                "Description": "A descrpition of the column",
                                "Types": STRING_TYPE,
                                "Default" : ""
                            }
                        ]
                    }
                ]
            },
            {
                "Names": "Format",
                "Description" : "Defines the format of the data",
                "Children": [
                    {
                        "Names": "Serialisation",
                        "Description" : "Sets how the data should be serialised/deserialised",
                        "Children" : [
                            {
                                "Names" : "Library",
                                "Description": "The library to use for the Serialisation process",
                                "Types" : STRING_TYPE
                            },
                            {
                                "Names" : "Parameters",
                                "Description" : "Additional key/value parameters to configure the Library - Key of the object is used as key by default",
                                "SubObjects" : true,
                                "Children": [
                                    {
                                        "Names": "Enabled",
                                        "Default" : "Include the parameter",
                                        "Types" : BOOLEAN_TYPE,
                                        "Default" : true
                                    },
                                    {
                                        "Names": "Key",
                                        "Description" : "The Key of the parameter",
                                        "Types" : STRING_TYPE
                                    },
                                    {
                                        "Names": "Value",
                                        "Description" : "The value of the parameter",
                                        "Types" : ANY_TYPE
                                    }
                                ]
                            }
                        ]
                    },
                    {
                        "Names": "Input",
                        "Description": "The input processer used to proceses the data into table format",
                        "Types" : STRING_TYPE
                    },
                    {
                        "Names": "Output",
                        "Description" : "The output processor used to standardise the output of the table",
                        "Types" : STRING_TYPE
                    }
                ]
            }
            {
                "Names": "Crawler",
                "Description" : "Crawl table to find new columns and update partitioning",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Description": "Enable the use of a Crawler for the table",
                        "Types" : BOOLEAN_TYPE,
                        "Default": false
                    },
                    {
                        "Names": "Schedule",
                        "Description" : "The schedule to run the crawler on - Format should in in the AWS Rate format",
                        "Types": STRING_TYPE
                    },
                    {
                        "Names" : "SchemaChanges",
                        "Default" : "How to handle changes to data schema when crawling",
                        "Children" : [
                            {
                                "Names" : "Update",
                                "Description": "What to do when new columns are found",
                                "Types" : STRING_TYPE,
                                "Values" : [ "Log", "Update" ],
                                "Default" : "Log"
                            },
                            {
                                "Names" : "Delete",
                                "Description" : "What to do when coloumns can't be found",
                                "Types" : STRING_TYPE,
                                "Values" : [ "Log", "Deprecate", "Delete"],
                                "Default": "Log"
                            }
                        ]
                    },
                    {
                        "Names": "RecrawlingPolicy",
                        "Description": "What to do when recrawling the same data",
                        "Types": STRING_TYPE,
                        "Values" : [ "Everything", "NewOnly" ],
                        "Default" : "NewOnly"
                    }
                ]
            }
        ]
/]
