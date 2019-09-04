[#ftl]

[@addComponent
    type=S3_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "HTTP based object storage service"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
            }
        ]
    attributes=
        [
            {
                "Names" : "Lifecycle",
                "Subobjects" : true,
                "Children" : []
            },
            {
                "Names" : "Website",
                "Subobjects" : true,
                "Children" : []
            },
            {
                "Names" : "PublicAccess",
                "Subobjects" : true,
                "Children" : []
            },
            {
                "Names" : "Notifications",
                "Subobjects" : true,
                "Children" : []
            },
            {
                "Names" : "CORSBehaviours",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Replication",
                "Children" : [
                    {
                        "Names" : "Prefixes",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ "" ]
                    },
                    {
                        "Names" : "Enabled",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
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
