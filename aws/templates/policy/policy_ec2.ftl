[#-- EC2 --]

[#function ec2AutoScaleGroupReadPermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "autoscaling:DescribeAutoScalingInstances",
                    "ec2:DescribeInstances"
                ])
        ]
    ]
[/#function]

[#function ec2IPAddressUpdatePermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "ec2:DescribeAddresses",
                    "ec2:AssociateAddress"
                ])
        ]
    ]
[/#function]

[#function ec2RouteAllPermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "ec2:DescribeRouteTables",
                    "ec2:CreateRoute",
                    "ec2:ReplaceRoute"
                ])
        ]
    ]
[/#function]

[#function ec2SubnetReadPermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "ec2:DescribeSubnets",
                    "ec2:DescribeRouteTables",
                    "ec2:CreateRoute",
                    "ec2:ReplaceRoute"
                ])
        ]
    ]
[/#function]

[#function ec2InstanceUpdatePermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "ec2:DescribeInstances",
                    "ec2:ModifyInstanceAttribute"
                ])
        ]
    ]
[/#function]

[#function ec2SSMSessionManagerPermission ]
    [#return 
        [
            getPolicyStatement(
                [
                    "ssm:UpdateInstanceInformation",
                    "ssmmessages:CreateControlChannel",
                    "ssmmessages:CreateDataChannel",
                    "ssmmessages:OpenControlChannel",
                    "ssmmessages:OpenDataChannel",
                    "s3:GetEncryptionConfiguration"
                ]
            )
        ]
    ]
[/#function]

[#function ec2SSMAgentUpdatePermission os="linux" region={ "Ref" : "AWS::Region" } ]
    [#return 
        [
            getPolicyStatement(
                [
                    "s3:GetObject"
                ],
                [
                    {
                        "Fn::Join" : [
                            "",
                            [
                                "arn:aws:s3:::aws-ssm-",
                                region,
                                "/*"
                            ]
                        ]
                    },
                    {
                        "Fn::Join" : [
                            "",
                            [
                                "arn:aws:s3:::amazon-ssm-",
                                region,
                                "/*"
                            ]
                        ]
                    },
                    {
                        "" : [
                            "",
                            [
                                "arn:aws:s3:::amazon-ssm-packages-",
                                region,
                                "/*"
                            ]
                        ]
                    },
                    {
                        "Fn::Join" : [
                            "",
                            [
                                "arn:aws:s3:::",
                                region,
                                "-birdwatcher-prod/*"
                            ]
                        ]
                    } + 
                    ( os == "windows" )?then(
                        { 
                            "Fn::Join" : [
                                "",
                                [
                                    "arn:aws:s3:::aws-windows-downloads-",
                                    region,
                                    "/*"
                                ]
                            ]
                        },
                        {}
                    )
                ]
            )
        ]
    ]
[/#function]