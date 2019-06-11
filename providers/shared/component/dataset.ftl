[#ftl]

[#assign componentConfiguration +=
    {
        DATASET_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A data aretefact that is managed in a similar way to a code unit"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "application"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Engine",
                    "Type" : STRING_TYPE,
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
                    "Type" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "BuildEnvironment",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Description" : "The environments used to build the dataset",
                    "Mandatory" : true
                }
            ]
        }
    }]
