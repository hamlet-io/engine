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


