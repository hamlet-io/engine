[#-- EC2 --]

[#macro autoScaleGroupReadStatement ]
    [@policyStatement
        [
            "autoscaling:DescribeAutoScalingInstances",
            "ec2:DescribeInstances"
        ]
    /]
[/#macro]

[#macro IPAddressUpdateStatement ]
    [@policyStatement
        [
            "ec2:DescribeAddresses",
            "ec2:AssociateAddress"
        ]
    /]
[/#macro]

[#macro routeAllStatement ]
    [@policyStatement
        [
            "ec2:DescribeRouteTables",
            "ec2:CreateRoute",
            "ec2:ReplaceRoute"
        ]
    /]
[/#macro]

[#macro subnetReadStatement ]
    [@policyStatement
        [
            "ec2:DescribeSubnets",
            "ec2:DescribeRouteTables",
            "ec2:CreateRoute",
            "ec2:ReplaceRoute"
        ]
    /]
[/#macro]

[#macro instanceUpdateStatement ]
    [@policyStatement
        [
            "ec2:DescribeInstances",
            "ec2:ModifyInstanceAttribute"
        ]
    /]
[/#macro]
