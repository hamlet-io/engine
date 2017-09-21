[#-- EC2 --]

[#function getAutoScaleGroupReadStatement ]
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

[#macro autoScaleGroupReadStatement ]
    [@policyStatements getAutoScaleGroupReadStatement() /]
[/#macro]

[#function getIPAddressUpdateStatement ]
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

[#macro IPAddressUpdateStatement ]
    [@policyStatements getIPAddressUpdateStatement() /]
[/#macro]

[#function getRouteAllStatement ]
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

[#macro routeAllStatement ]
    [@policyStatements getRouteAllStatement() /]
[/#macro]

[#function getSubnetReadStatement ]
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

[#macro subnetReadStatement ]
    [@policyStatements getSubnetReadStatement() /]
[/#macro]

[#function getInstanceUpdateStatement ]
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

[#macro instanceUpdateStatement ]
    [@policyStatements getInstanceUpdateStatement() /]
[/#macro]

