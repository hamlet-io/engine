[#ftl]

[@addExtendedAttributeSet
    type=CONTEXTPATH_FULLPATH_ATTRIBUTESET_TYPE
    baseType=CONTEXTPATH_ATTRIBUTESET_TYPE
    provider=SHARED_PROVIDER
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Creates a Segment unique context path by default"
        }]
    attributes=[
        {
            "Names" : "Style",
            "Types" : STRING_TYPE,
            "Description" : "Provide the value as a single string or a file system style path",
            "Values" : [ "path" ],
            "Default" : "path"
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
                    "Default" : true
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
                    "Default": true
                },
                {
                    "Names" : "Component",
                    "Description" : "The name of the component",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Instance",
                    "Description" : "The name of the instance",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Version",
                    "Description" : "The name of the version",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
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
