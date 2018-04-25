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
                    "ecs:StopTask",
		            "ecs:DescribeTasks"
                ]
            )
        ]
    ]
[/#function]
