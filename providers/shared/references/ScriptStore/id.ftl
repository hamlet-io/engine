[#ftl]

[@addReference 
    type=SCRIPTSTORE_REFERENCE_TYPE
    pluralType="ScriptStores"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A physical location for infrastructure deployment" 
            }
        ]
    attributes=[
        {
            "Names" : "Engine",
            "Types" : STRING_TYPE,
            "Values" : [ "local", "github" ]
        }
        {
            "Names" : "Destination",
            "Children" : [
                {
                    "Names" : "Prefix",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Source",
            "Children" : [
                {
                    "Names" : "Directory",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Repository",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Branch",
                    "Types" : STRING_TYPE
                }
            ]
        }
    ]
/]