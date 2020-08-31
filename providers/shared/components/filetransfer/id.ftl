[#ftl]

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
                "Names" : "DeploymentyGroup",
                "Type" : STRING_TYPE,
                "Default" : "solution"
            },
            {
                "Names" : "Protocols",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Values" : [ "sftp" ],
                "Mandatory" : true
            },
            {
                "Names" : "IPAddressGroups",
                "Type" : ARRAY_OF_STRING_TYPE,
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
                        "Type" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Logging",
                        "Type" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Security",
                        "Type" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
/]
