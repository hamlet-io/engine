[#case "filter"]
    [#switch containerListMode]
        [#case "definition"]
            "Name" : "${tier.Name + "-" + component.Name + "-" + container.Name}",
            "Image" : "${docker.Registry}/esfilter${dockerTag}",
            "Environment" : [
                [@standardEnvironmentVariables /],
                {
                    "Name" : "CONFIGURATION",
                    "Value" : "${appsettings?json_string}"
                },
                [#assign es = component.Links["es"]]
                {
                    "Name" : "ES",
                    "Value" : "${getKey("esX" + es.Tier + "X" + es.Component + "Xdns") + ":443"}"
                },
                [#assign sharedCredential = credentialsObject["shared"]]
                {
                    "Name" : "DATA_USERNAME",
                    "Value" : "${sharedCredential.Data.Username}"
                },
                {
                    "Name" : "DATA_PASSWORD",
                    "Value" : "${sharedCredential.Data.Password}"
                },
                {
                    "Name" : "QUERY_USERNAME",
                    "Value" : "${sharedCredential.Query.Username}"
                },
                {
                    "Name" : "QUERY_PASSWORD",
                    "Value" : "${sharedCredential.Query.Password}"
                }
            ],
            "Essential" : true,
            [#break]

        [#case "policyCount"]
            [#assign policyCount += 1]
            [#break]

        [#case "policy"]
            "policyX${tier.Id}X${component.Id}X${task.Id}X${container.Id}": {
                "Type" : "AWS::IAM::Policy",
                "Properties" : {
                    "PolicyDocument" : {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Action": [
                                    "kms:Decrypt"
                                ],
                                "Resource": [
                                     {
                                        "Fn::Join" : [
                                            "",
                                            [
                                                "arn:aws:kms:${regionId}:",
                                                {"Ref" : "AWS::AccountId"},
                                                ":key/${getKey("cmkXsegmentXcmk")}"
                                            ]
                                        ]
                                    }
                                ],
                                "Effect": "Allow"
                            }
                        ]
                    },
                    "PolicyName" : "${tier.Name + "-" + component.Name + "-" + task.Name + "-" + container.Name}",
                    "Roles" : [
                        { "Ref" : "roleX${tier.Id}X${component.Id}X${task.Id}" }
                    ]
                }
            },
            [#break]

    [/#switch]
    [#break]

