[#ftl]

[@addTask
    type=DOCKER_PUSH_IMAGE_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Perfom a docker login using credentials from AWS ECR"
            }
        ]
    attributes=[
        {
            "Names" : "DestinationImage",
            "Description" : "The destination image name",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "SourceImage",
            "Description" : "The local image to push to the destination",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]
