[#ftl]

[@addAttributeSet
    type=CONTEXTPATH_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Combined with the getContextPath() function creates a name or path based on your current context"
        }]
    attributes=[
        {
            "Names" : [ "Custom", "Host" ],
            "Description" : "The custom string to include if custom is included in the path",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "Style",
            "Types" : STRING_TYPE,
            "Description" : "Provide the value as a single string or a file system style path",
            "Values" : [ "single", "path" ],
            "Default" : "single"
        },
        {
            "Names" : "Order",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : [
                "Account",
                "ProviderId",
                "Product",
                "Environment",
                "Segment",
                "Tier",
                "Component",
                "Instance",
                "Version",
                "Host",
                "Custom"
            ]
        },
        {
            "Names" : "IncludeInPath",
            "Children" : [
                {
                    "Names" : "Account",
                    "Description" : "The name of the Account",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "ProviderId",
                    "Description" : "The Provider Id for the account",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                }
                {
                    "Names" : "Product",
                    "Description" : "The name of the product",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Environment",
                    "Description" : "The name of the environment",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Segment",
                    "Description" : "The name of the segment",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Tier",
                    "Description" : "The name of the tier",
                    "Types" : BOOLEAN_TYPE,
                    "Default": false
                },
                {
                    "Names" : "Component",
                    "Description" : "The name of the component",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Instance",
                    "Description" : "The name of the instance",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Version",
                    "Description" : "The name of the version",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : ["Custom", "Host"],
                    "Description" : "Include a custom string",
                    "Types" : BOOLEAN_TYPE,
                    "Default": false
                }
            ]
        }
    ]
/]
