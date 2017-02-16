[#case "xxx"]
    [#switch policyListMode]
        [#case "policyCount"]
            [#assign policyCount += 1]
            [#break]

        [#case "policies"]
            [#if policyCount > 0],[/#if]
            "policyX${tier.Id}X${component.Id}": {
                "Type": "AWS::IAM::Policy",
                "Properties": {
                    "PolicyDocument" : {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Resource": [],
                                "Action": [],
                                "Effect": "Allow"
                            }
                        ]
                    },
                    "PolicyName" : "${tier.Name + "-" + component.Name + "-" + task.Name + "-" + container.Name}",
                    "Roles" : [
                        { "Ref" : "roleX${tier.Id}X${component.Id}X${task.Id}" }
                    ]
                }
            }
            [#assign policyCount += 1]
            [#break]

    [/#switch]
    [#break]

