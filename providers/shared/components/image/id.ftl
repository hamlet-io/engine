[#ftl]

[@addComponent
    type=IMAGE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "An Application image used by other components in the solution"
            }
        ]
    attributes=[
        {
            "Names" : "Format",
            "Description" : "The format of the image whih defines the components that support the image",
            "Values" : [
                "scripts",
                "spa",
                "docker",
                "dataset",
                "contentnode",
                "lambda",
                "lambda_jar",
                "openapi"
            ]
        },
        {
            "Names" : "Source",
            "Description" : "The source of the image - Local: an image built locally - ContainerRegistry: a public container registry - URL: a public URL",
            "Types" : STRING_TYPE,
            "Mandatory" : true,
            "Values" : [ "Local", "ContainerRegistry", "containerregistry", "URL" ],
            "Default" : "Local"
        },
        {
            "Names" : [ "Source:ContainerRegistry" "Source:containerregistry" ],
            "Description" : "A docker container registry to source the image from",
            "Children" : [
                {
                    "Names" : "Image",
                    "Description" : "The docker image that you want to use",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Source:URL",
            "Description" : "Download the image from an external service based on URL",
            "Children" : [
                {
                    "Names" : "URL",
                    "Description" : "The URL to the image to download",
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
            "Names" : "Format:docker",
            "Description": "Format specific configuration for docker images",
            "Children" : [
                {
                    "Names" : "ImmutableTags",
                    "Description" : "Make tags immutablable",
                    "Types": BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names": "Scanning",
                    "Description" : "Start scanning of images for vulnerabilities on upload",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Description" : "Enable scanning on upload",
                            "Types" : BOOLEAN_TYPE,
                            "Default": true
                        }
                    ]
                },
                {
                    "Names": "Encryption",
                    "Children" : [
                        {
                            "Names": "Enabled",
                            "Description" : "Enable encryption at rest for the repository",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : true
                        }
                    ]
                },
                {
                    "Names" : "Lifecycle",
                    "Description" : "Control the lifecycle of images in the container registry",
                    "Children" : [
                        {
                            "Names" : "ConfiguratonSource",
                            "Description": "Defines where the lifecycle policy comes from - Solution = simple configuration as part of solution, Extension = Use policy defined in an extension",
                            "Types" : STRING_TYPE,
                            "Values" : [ "Solution", "Extension" ],
                            "Default": "Solution"
                        },
                        {
                            "Names" : "Expiry",
                            "Description" : "Control when images are removed from the registry",
                            "Children" : [
                                {
                                    "Names" : "UntaggedDays",
                                    "Description" : "How long (Days) until untagged images are removed - use _operations: to follow the layer configuration, or a number for a fixed value - set to 0 for no expiry",
                                    "Types" : [ NUMBER_TYPE, STRING_TYPE],
                                    "Default" : "_operations"
                                },
                                {
                                    "Names" : "UntaggedMaxCount",
                                    "Description": "How many untagged images to retain - set 0 for keep all",
                                    "Types" : NUMBER_TYPE,
                                    "Default" : 0
                                },
                                {
                                    "Names" : "TaggedMaxCount",
                                    "Description" : "How many tagged images to retain - set 0 to keep all",
                                    "Types" : NUMBER_TYPE,
                                    "Default" : 0
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    ]
/]

[@addComponentDeployment
    type=IMAGE_COMPONENT_TYPE
    defaultGroup="application"
/]
