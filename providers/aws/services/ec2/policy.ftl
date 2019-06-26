[#ftl]

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
                        "Fn::Join" : [
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


[#function ec2EBSVolumeSnapshotAllPermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "ec2:CopySnapshot",
                    "ec2:CreateSnapshot",
                    "ec2:DescribeSnapshots",
                    "ec2:DeleteSnapshot",
                    "ec2:DescribeSnapshotAttribute",
                    "ec2:ModifySnapshotAttribute",
                    "ec2:ResetSnapshotAttribute",
                    "ec2:DescribeVolumes",
                    "ec2:DescribeVolumeStatus",
                    "ec2:DescribeVolumeAttribute",
                    "ec2:DescribeVolumesModifications"
                ]
            )
        ]
    ]
[/#function]

[#function ec2EBSVolumeReadPermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "ec2:DescribeVolumes",
                    "ec2:DescribeVolumeAttribute",
                    "ec2:DescribeVolumeStatus"
                ]
            )
        ]

    ]
[/#function]

[#function ec2EBSVolumeUpdatePermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "ec2:AttachVolume",
                    "ec2:CreateVolume",
                    "ec2:CreateSnapshot",
                    "ec2:CreateTags",
                    "ec2:DeleteVolume",
                    "ec2:DeleteSnapshot",
                    "ec2:DescribeAvailabilityZones",
                    "ec2:DescribeInstances",
                    "ec2:DescribeVolumes",
                    "ec2:DescribeVolumeAttribute",
                    "ec2:DescribeVolumeStatus",
                    "ec2:DescribeSnapshots",
                    "ec2:CopySnapshot",
                    "ec2:DescribeSnapshotAttribute",
                    "ec2:DetachVolume",
                    "ec2:ModifySnapshotAttribute",
                    "ec2:ModifyVolumeAttribute",
                    "ec2:DescribeTags"
                ]
            )
        ]
    ]
[/#function]