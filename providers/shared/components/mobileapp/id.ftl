[#ftl]

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
                "Types" : STRING_TYPE,
                "Default" : "expo",
                "Values" : ["expo"]
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "BuildFormats",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "ios", "android" ],
                "Values" : [ "ios", "android" ]
            },
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "UseOTAPrefix",
                "Description" : "Include the OTA Prefix in the OTA Url",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Image",
                "Description" : "Control the source of the image for the mobile ota source zip image",
                "Children" : [
                    {
                        "Names" : "Source",
                        "Description" : "The source of the image - registry: the local hamlet registry - url: an external public url",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true,
                        "Values" : [ "registry", "url" ],
                        "Default" : "registry"
                    },
                    {
                        "Names" : "Source:url",
                        "Description" : "Url Source specific Configuration",
                        "Children" : [
                            {
                                "Names" : "Url",
                                "Description" : "The Url to a zip file containing the mobile app source",
                                "Types" : STRING_TYPE
                            },
                            {
                                "Names" : "ImageHash",
                                "Description" : "The expected sha1 hash of the Url if empty any will be accepted",
                                "Types" : STRING_TYPE,
                                "Default" : ""
                            }
                        ]
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=MOBILEAPP_COMPONENT_TYPE
    defaultGroup="application"
/]
