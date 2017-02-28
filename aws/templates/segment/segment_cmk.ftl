[#-- KMS CMK --]
[#if deploymentUnit?contains("cmk")]
    [#if resourceCount > 0],[/#if]
    [#switch segmentListMode]
        [#case "definition"]
            "cmk" : {
                "Type" : "AWS::KMS::Key",
                "Properties" : {
                    "Description" : "${productName}-${segmentName}",
                    "Enabled" : true,
                    "EnableKeyRotation" : ${(rotateKeys)?string("true","false")},
                    "KeyPolicy" : {
                        "Version": "2012-10-17",
                        "Statement": [ 
                            {
                                "Effect": "Allow",
                                "Principal": { 
                                    "AWS": { 
                                        "Fn::Join": [
                                            "", 
                                            [
                                                "arn:aws:iam::",
                                                { "Ref" : "AWS::AccountId" },
                                                ":root"
                                            ]
                                        ]
                                    }
                                },
                                "Action": [ "kms:*" ],
                                "Resource": "*"
                            }
                        ]
                    }
                }
            },
            "aliasXcmk" : {
                "Type" : "AWS::KMS::Alias",
                "Properties" : {
                    "AliasName" : "alias/${productName}-${segmentName}",
                    "TargetKeyId" : { "Fn::GetAtt" : ["cmk", "Arn"] }
                }
            }
            [#break]

        [#case "outputs"]
            "cmkXsegmentXcmk" : {
                "Value" : { "Ref" : "cmk" }
            },
            "cmkXsegmentXcmkXarn" : {
                "Value" : { "Fn::GetAtt" : ["cmk", "Arn"] }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]

