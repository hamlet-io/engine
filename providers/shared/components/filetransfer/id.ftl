[#ftl]

[@addComponentDeployment
    type=FILETRANSFER_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=FILETRANSFER_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "File Transfer Service based on standard protocols"
            }
        ]
    attributes=
        [
            {
                "Names" : "Protocols",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Values" : [ "sftp" ],
                "Mandatory" : true
            },
            {
                "Names" : "IPAddressGroups",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Certificate",
                "Children" : certificateChildConfiguration
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Network",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Logging",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Security",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            }
        ]
/]
