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
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Prefix",
            "Types" : STRING_TYPE
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
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Version",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Index",
            "Description" : "Determines script execution sequence.",
            "Types" : NUMBER_TYPE
        },
        {
            "Names" : "Type",
            "Children" : [
                {
                    "Names" : "Name",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "HandlerVersion",
                    "Types" : STRING_TYPE
                }
            ]
        }
        {
            "Names" : "Publisher",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "AutoUpgradeOnMinorVersion",
            "Types" : BOOLEAN_TYPE
        },
        {
            "Names" : "Settings",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Key",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Value",
                    "Types" : ANY_TYPE,
                    "Mandatory" : true
                }
            ]
        },
        {
            "Names" : "ProtectedSettings",
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "Key",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Value",
                    "Types" : ANY_TYPE,
                    "Mandatory" : true
                }
            ]
        }
    ]
/]
