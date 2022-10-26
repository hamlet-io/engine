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
                "AttributeSet" : IMAGE_URL_ATTRIBUTESET_TYPE
            }
        ]
/]

[@addComponentDeployment
    type=DATASET_COMPONENT_TYPE
    defaultGroup="application"
/]
