[#ftl]

[@addComponent
    type=CONTENTHUB_NODE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Node for decentralised content hosting with centralised publishing"
            }
        ]
    attributes=
        [
            {
                "Names" : "Path",
                "AttributeSet" : CONTEXTPATH_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Image",
                "Description" : "Control the source of the content node zip package",
                "Children" : [
                    {
                        "Names" : "Source",
                        "Description" : "The source of the image - registry: the local hamlet registry - url: an external public url",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true,
                        "Values" : [ "link", "registry", "url" ],
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
                    },
                    {
                        "Names": "Link",
                        "AttributeSet": LINK_ATTRIBUTESET_TYPE
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=CONTENTHUB_NODE_COMPONENT_TYPE
    defaultGroup="application"
/]
