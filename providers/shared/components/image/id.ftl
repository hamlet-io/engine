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
        }
    ]
/]

[@addComponentDeployment
    type=IMAGE_COMPONENT_TYPE
    defaultGroup="application"
/]
