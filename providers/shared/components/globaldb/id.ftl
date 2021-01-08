[#ftl]

[@addComponentDeployment
    type=GLOBALDB_COMPONENT_TYPE
    defaultGroup="solution"
/]


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
                "Children" : dynamoDbTableChildConfiguration
            },
            {
                "Names" : "PrimaryKey",
                "Description" : "The primary key for the table",
                "Type" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "SecondaryKey",
                "Description" : "The secondary sort key for the table",
                "Type" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "TTLKey",
                "Description" : "A key in the table used to manage the items expiry",
                "Type" : STRING_TYPE,
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
                        "Type" : STRING_TYPE,
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
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "Keys",
                        "Description" : "List of keys",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "KeyTypes",
                        "Description" : "Type of each key - default is hash(0) then range",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Values" : ["hash", "range"]
                    },
                    {
                        "Names" : "Capacity",
                        "Children" : [
                            {
                                "Names" : "Read",
                                "Description" : "When using provisioned billing the maximum RCU of the table",
                                "Type" : NUMBER_TYPE,
                                "Default" : 1
                            },
                            {
                                "Names" : "Write",
                                "Description" : "When using provisioned billing the maximum WCU of the table",
                                "Type" : NUMBER_TYPE,
                                "Default" : 1
                            }
                        ]
                    }
                ]
            }
        ]
/]
