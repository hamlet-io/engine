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
        },
        {
            "Names" : "Index",
            "Description" : "Determines script execution sequence.",
            "Type" : NUMBER_TYPE
        },
        {
            "Names" : "Type",
            "Children" : [
                {
                    "Names" : "Name",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "HandlerVersion",
                    "Type" : STRING_TYPE
                }
            ]
        }
        {
            "Names" : "Publisher",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "AutoUpgradeOnMinorVersion",
            "Type" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "Settings",
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "Key",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Value",
                    "Type" : STRING_TYPE,
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
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Value",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                }
            ]
        }
    ]
/]
