[#ftl]

[@addComponent
    type=DATASET_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A data aretefact that is managed in a similar way to a code unit"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Types" : STRING_TYPE,
                "Values" : ["s3", "rds"],
                "Mandatory" : true
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Prefix",
                "Types" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "BuildEnvironment",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Description" : "The environments used to build the dataset",
                "Mandatory" : true
            },
            {
                "Names" : "Image",
                "Description" : "Control the source of the image for dataset components",
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
    type=DATASET_COMPONENT_TYPE
    defaultGroup="application"
/]
