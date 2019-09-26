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
            "Type" : STRING_TYPE,
            "Values" : [ "local", "github" ]
        }
        {
            "Names" : "Destination",
            "Children" : [
                {
                    "Names" : "Prefix",
                    "Type" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Source",
            "Children" : [
                {
                    "Names" : "Directory",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Repository",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Branch",
                    "Type" : STRING_TYPE
                }
            ]
        }
    ]
/]