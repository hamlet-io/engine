[#-- EC2 --]

[#macro autoScaleGroupReadStatement ]
    [@policyStatement
        [
            "autoscaling:DescribeAutoScalingInstances",
            "ec2:DescribeInstances"
        ]
    /]
[/#macro]

[#macro IPAddressWriteStatement ]
    [@policyStatement
        [
            "ec2:DescribeAddresses",
            "ec2:AssociateAddress"
        ]
    /]
[/#macro]


