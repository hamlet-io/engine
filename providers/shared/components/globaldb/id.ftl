[#ftl]

[@addComponent
    type=GLOBALDB_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A global NoSQL database table"
            }
        ]
    attributes=
        [
            {
                "Names" : "Table",
                "AttributeSet" : TABLE_HOSTING_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "PrimaryKey",
                "Description" : "The primary key for the table",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "SecondaryKey",
                "Description" : "The secondary sort key for the table",
                "Types" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "TTLKey",
                "Description" : "A key in the table used to manage the items expiry",
                "Types" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "KeyTypes",
                "Description" : "Key types - default is string",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Type",
                        "Description" : "Key value type",
                        "Types" : STRING_TYPE,
                        "Values" : [STRING_TYPE, NUMBER_TYPE, "binary"]
                    }
                ]
            },
            {
                "Names" : "SecondaryIndexes",
                "Description" : "Alternate indexes for query efficiency",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Name",
                        "Description" : "Index name",
                        "Types" : STRING_TYPE
                    },
                    {
                        "Names" : "Keys",
                        "Description" : "List of keys",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "KeyTypes",
                        "Description" : "Type of each key - default is hash(0) then range",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Values" : ["hash", "range"]
                    },
                    {
                        "Names" : "Capacity",
                        "Children" : [
                            {
                                "Names" : "Read",
                                "Description" : "When using provisioned billing the maximum RCU of the table",
                                "Types" : NUMBER_TYPE,
                                "Default" : 1
                            },
                            {
                                "Names" : "Write",
                                "Description" : "When using provisioned billing the maximum WCU of the table",
                                "Types" : NUMBER_TYPE,
                                "Default" : 1
                            }
                        ]
                    }
                ]
            },
            {
                "Names" : "ChangeStream",
                "Description" : "Provides a stream of changes made to the table",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "ChangeView",
                        "Description" : "The format of changes that will be provided in the stream",
                        "Types" : STRING_TYPE,
                        "Values": [ "KeysOnly", "NewItem", "OldItem", "NewAndOldItem" ],
                        "Default" : "KeysOnly"
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=GLOBALDB_COMPONENT_TYPE
    defaultGroup="solution"
/]
