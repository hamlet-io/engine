[#ftl]

[@addReference
    type=BOOTSTRAP_REFERENCE_TYPE
    pluralType="Bootstraps"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "User defined initialisation for virtual machine based components"
            }
        ]
    attributes=[
        {
            "Names" : "ScriptStore",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Prefix",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "InitScript",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Packages",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Name",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Version",
                    "Type" : STRING_TYPE
                }
            ]
        }
    ]
/]
