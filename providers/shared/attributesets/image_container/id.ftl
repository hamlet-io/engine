[#ftl]

[@addExtendedAttributeSet
    type=IMAGE_CONTAINER_ATTRIBUTESET_TYPE
    baseType=IMAGE_ATTRIBUTESET_TYPE
    provider=SHARED_PROVIDER
    properties=[
        {
                "Type"  : "Description",
                "Value" : "An image source to get a container image"
        }]
    attributes=[
        {
            "Names": "Source",
            "Values" : [
                "link",
                "registry",
                "containerregistry",
                "ContainerRegistry"
            ]
        },
        {
            "Names" : [ "Source:ContainerRegistry", "Source:containerregistry" ],
            "Description" : "A docker container registry to source the image from",
            "Children" : [
                {
                    "Names" : "Image",
                    "Description" : "The docker image that you want to use",
                    "Types" : STRING_TYPE
                }
            ]
        }
    ]
/]
