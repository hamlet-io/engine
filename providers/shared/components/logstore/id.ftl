[#ftl]

[@addComponent
    type=LOGSTORE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Defines a standalong log store used to capture function base logs"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Description": "The service used to store the logs",
                "Types" : [ STRING_TYPE ],
                "Values" : []
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Lifecycle",
                "Description" : "The lifecycle policy for the log store",
                "Children" : [
                    {
                        "Names": "Expiration",
                        "Description" : "The time in days to keep logs for, _operations follows the layer expiration policy",
                        "Types" : [ STRING_TYPE, NUMBER_TYPE],
                        "Default" : "_operations"
                    }
                ]
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Logging",
                        "Description" : "Profile to define where logs are forwarded to from this component",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            },
            {
                "Names" : "Path",
                "Description" : "The log store path based on occurrence attributes",
                "AttributeSet" : CONTEXTPATH_FULLPATH_ATTRIBUTESET_TYPE
            }
        ]
/]

[@addComponentDeployment
    type=LOGSTORE_COMPONENT_TYPE
    defaultGroup="segment"
/]
