[#ftl]

[@addComponent
    type=GLOBALDB_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A global NoSQL database table"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
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
            }
        ]
/]
