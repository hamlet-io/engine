[#ftl]

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

[#function ecsTaskRunPermission ecsId taskId="" ]

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
                    "ecs:StartTask",
                    "ecs:StopTask"
                ],
                taskId?has_content?then(
                    getReference(taskId, ARN_ATTRIBUTE_TYPE),
                    "*"
                ),
                "",
                {
                    "ArnEquals" :{
                        "ecs:cluster" : clusterArn
                    }
                }
            )
        ]
    ]
[/#function]