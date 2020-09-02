[#ftl]

[@addComponentDeployment
    type=SPA_COMPONENT_TYPE
    defaultGroup="application"
/]

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
                "Names" : ["Fragment", "Container"],
                "Type" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "InvalidateOnUpdate",
                "Description" : "Invalidate all CDNs that host this content",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "ConfigPathPattern",
                "Description" : "The CDN pattern used to access the config",
                "Type" : STRING_TYPE,
                "Default" : "config/*"
            },
            {
                "Names" : "ConfigPath",
                "Description" : "The path appended to files that will be used for config",
                "Type" : STRING_TYPE,
                "Default" : "config"
            },
            {
                "Names" : "Port",
                "Description" : "The port used to access the SPA content.",
                "Children" : [
                    {
                        "Names" : "HTTP",
                        "Type" : STRING_TYPE,
                        "Default" : "http"
                    },
                    {
                        "Names" : "HTTPS",
                        "Type" : STRING_TYPE,
                        "Default" : "https"
                    }
                ]
            }
        ]
/]
