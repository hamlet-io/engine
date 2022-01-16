[#ftl]

[@addAttributeSet
    type=ENVIRONMENTFORMAT_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "How to format environment variables from settings"
        }]
    attributes=[
        {
            "Names" : "AsFile",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "FileFormat",
            "Types" : STRING_TYPE,
            "Description" : "The format of the file when using AsFile",
            "Values" : [ "json", "yaml" ],
            "Default" : "json"
        },
        {
            "Names" : "Json",
            "Children" : [
                {
                    "Names" : "Escaped",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Prefix",
                    "Types" : STRING_TYPE,
                    "Values" : ["json", ""],
                    "Default" : "json"
                }
            ]
        }
     ]
/]
