
[#ftl]

[#function dataPipelineGlobalAccess ]
    [#return
        getPolicyStatement(
            [
                "cloudwatch:*",
                "datapipeline:DescribeObjects",
                "datapipeline:EvaluateExpression",
                "dynamodb:BatchGetItem",
                "dynamodb:DescribeTable",
                "dynamodb:GetItem",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:UpdateTable",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CancelSpotInstanceRequests",
                "ec2:CreateSecurityGroup",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:Describe*",
                "ec2:ModifyImageAttribute",
                "ec2:ModifyInstanceAttribute",
                "ec2:RequestSpotInstances",
                "ec2:RunInstances",
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:DeleteSecurityGroup",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DetachNetworkInterface",
                "elasticmapreduce:*",
                "iam:GetInstanceProfile",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListRolePolicies",
                "iam:ListInstanceProfiles",
                "iam:PassRole",
                "rds:DescribeDBInstances",
                "rds:DescribeDBSecurityGroups",
                "redshift:DescribeClusters",
                "redshift:DescribeClusterSecurityGroups",
                "s3:CreateBucket",
                "s3:DeleteObject",
                "s3:Get*",
                "s3:List*",
                "s3:Put*",
                "sdb:BatchPutAttributes",
                "sdb:Select*",
                "sns:GetTopicAttributes",
                "sns:ListTopics",
                "sns:Publish",
                "sns:Subscribe",
                "sns:Unsubscribe",
                "sqs:CreateQueue",
                "sqs:Delete*",
                "sqs:GetQueue*",
                "sqs:PurgeQueue",
                "sqs:ReceiveMessage"
            ])
    ]
[/#function]

[#function dataPipelineSerivceLinkedRole ]
    [#return
        getPolicyStatement(
            [ "iam:CreateServiceLinkedRole" ],
            "*",
            "",
            {
                "StringLike": {
                "iam:AWSServiceName": ["elasticmapreduce.amazonaws.com","spot.amazonaws.com"]
            }
         }
        )
    ]
[/#function]

[#function dataPipelineBaseResourceAccess ]
    [#return
        getPolicyStatement(
            [
                "cloudwatch:*",
                "datapipeline:*",
                "dynamodb:*",
                "ec2:Describe*",
                "elasticmapreduce:AddJobFlowSteps",
                "elasticmapreduce:Describe*",
                "elasticmapreduce:ListInstance*",
                "rds:Describe*",
                "redshift:DescribeClusters",
                "redshift:DescribeClusterSecurityGroups",
                "s3:*",
                "sdb:*",
                "sns:*",
                "sqs:*"
            ]
        )
    ]
[/#function]