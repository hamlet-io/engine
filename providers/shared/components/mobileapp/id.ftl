[#ftl]

[@addComponentDeployment
    type=MOBILEAPP_COMPONENT_TYPE
    defaultGroup="application"
/]

[@addComponent
    type=MOBILEAPP_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "mobile apps with over the air update hosting"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Type" : STRING_TYPE,
                "Default" : "expo",
                "Values" : ["expo"]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "BuildFormats",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "ios", "android" ],
                "Values" : [ "ios", "android" ]
            },
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "UseOTAPrefix",
                "Description" : "Include the OTA Prefix in the OTA Url",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            }
        ]
/]
