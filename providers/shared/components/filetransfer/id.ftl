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
                "Names" : [ "MultiAZ", "MultiZone"],
                "Description" : "Deploy resources to multiple Availablity Zones",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : [ "Certificate", "Hostname" ],
                "AttributeSet" : CERTIFICATE_ATTRIBUTESET_TYPE
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
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            }
        ]
/]

[@addComponentDeployment
    type=FILETRANSFER_COMPONENT_TYPE
    defaultGroup="solution"
/]
