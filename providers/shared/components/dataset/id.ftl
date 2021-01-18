[#ftl]

[@addComponentDeployment
    type=DATASET_COMPONENT_TYPE
    defaultGroup="application"
/]

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
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
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
            }
        ]
/]
