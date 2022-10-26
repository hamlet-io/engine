[#ftl]

[@addComponent
    type=DATAPIPELINE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Managed Data ETL Processing"
            }
        ]
    attributes=
        [
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Permissions",
                "Children" : [
                    {
                        "Names" : "Decrypt",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AsFile",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppData",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
                        {
                            "Names" : "Processor",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Network",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Image",
                "Description" : "Control the source of the image for the mobile ota source zip image",
                "AttributeSet" : IMAGE_URL_ATTRIBUTESET_TYPE
            }
        ]
/]

[@addComponentDeployment
    type=DATAPIPELINE_COMPONENT_TYPE
    defaultGroup="application"
/]
