[#ftl]

[@addAttributeSet
    type=ANTIVIRUS_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Standard Configuration options to define antivirus configuration"
        }]
    attributes=[
        {
            "Names": "Mode",
            "Types" : STRING_TYPE,
            "Values" : [ "Active", "Passive", "Disabled" ],
            "Default" : "Active"
        },
        {
            "Names" : "ControlledFolders",
            "Children" : [
                {
                    "Names": "Folders",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names": "AllowedApps",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        },
        {
            "Names" : "Exclusions",
            "Children" : [
                {
                    "Names": "FilePaths",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names": "Folders",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names": "FileTypes",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        }
     ]
/]
