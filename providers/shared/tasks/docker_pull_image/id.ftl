[#ftl]

[@addTask
    type=DOCKER_PULL_IMAGE_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Perfom a docker login using credentials from AWS ECR"
            }
        ]
    attributes=[
        {
            "Names" : "Image",
            "Description" : "The image to pull from a registry",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]
