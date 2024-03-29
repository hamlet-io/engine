[#ftl]

[@addComponent
    type=SPA_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A statically hosted web application"
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
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "InvalidateOnUpdate",
                "Description" : "Invalidate all CDNs that host this content",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "ConfigPathPattern",
                "Description" : "The CDN pattern used to access the config",
                "Types" : STRING_TYPE,
                "Default" : "config/*"
            },
            {
                "Names" : "ConfigPath",
                "Description" : "The path appended to files that will be used for config",
                "Types" : STRING_TYPE,
                "Default" : "config"
            },
            {
                "Names" : "Port",
                "Description" : "The port used to access the SPA content.",
                "Children" : [
                    {
                        "Names" : "HTTP",
                        "Types" : STRING_TYPE,
                        "Default" : "http"
                    },
                    {
                        "Names" : "HTTPS",
                        "Types" : STRING_TYPE,
                        "Default" : "https"
                    }
                ]
            },
            {
                "Names" : "Image",
                "Description" : "Control the source of the image that is used for the function",
                "AttributeSet" : IMAGE_URL_ATTRIBUTESET_TYPE
            }
        ]
/]

[@addComponentDeployment
    type=SPA_COMPONENT_TYPE
    defaultGroup="application"
/]
