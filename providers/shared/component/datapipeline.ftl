[#ftl]

[@addComponent
    type=DATAPIPELINE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Managed Data ETL Processing"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "application"
            }
        ]
/]

[@addComponentResourceGroup
    type=DATAPIPELINE_COMPONENT_TYPE
    attributes=
        [
            {
                "Names" : ["Fragment", "Container"],
                "Type" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "Permissions",
                "Children" : [
                    {
                        "Names" : "Decrypt",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AsFile",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppData",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppPublic",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Profiles",
                "Children" : profileChildConfiguration +
                                [
                                    {
                                        "Names" : "Processor",
                                        "Type" : STRING_TYPE,
                                        "Default" : "default"
                                    }
                                ]
            }
        ]
/]
