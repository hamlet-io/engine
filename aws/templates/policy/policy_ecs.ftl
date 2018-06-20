[#-- ECS --]

[#function ecsTaskAllPermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "ecs:RegisterTaskDefinition",
                    "ecs:ListClusters",
                    "ecs:DescribeContainerInstances",
                    "ecs:ListTaskDefinitions",
                    "ecs:DescribeTaskDefinition",
                    "ecs:StopTask",
                    "ecs:ListContainerInstances",
                    "ecs:RunTask",
		            "ecs:DescribeTasks"
                ]
            )
        ]
    ]
[/#function]

[#function ecsTaskRunPermission ecsId taskId ]

    [#local clusterArn = formatEcsClusterArn(ecsId)]
    [#return
        [
            getPolicyStatement(
                [
                    "ecs:ListClusters",
                    "ecs:DescribeContainerInstances",
                    "ecs:ListTaskDefinitions",
                    "ecs:DescribeTaskDefinition",
                    "ecs:DescribeTasks",
                    "ecs:ListContainerInstances"
                ]
            ),
            getPolicyStatement(
                [
                    "ecs:RunTask",
                    "ecs:StartTask"
                ],
                getReference(taskId),
                {
                    "ArnEquals" :{
                        "ecs:cluster" : clusterArn 
                    }
                }
            ),
            getPolicyStatement(
                [
                    "ecs:StopTask"
                ],
                "*",
                {
                    "ArnEquals" :{
                        "ecs:cluster" : clusterArn
                    }
                }
            )
        ]
    ]
[/#function]