[#-- Standard set of buckets for a segment --]
[#if slice?contains("s3")]
    [#if resourceCount > 0],[/#if]
    [#switch segmentListMode]
        [#case "definition"]
            [#-- Create operations bucket --]
            "s3X${operationsBucketType}" : {
                "Type" : "AWS::S3::Bucket",
                "Properties" : {
                    "BucketName" : "${operationsBucket}",
                    "Tags" : [ 
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" }
                    ],
                    "LifecycleConfiguration" : {
                        "Rules" : [
                            {
                                "Id" : "default",
                                "ExpirationInDays" : ${operationsExpiration},
                                "Status" : "Enabled"
                            }
                        ]
                    }
                }
            },
            [#-- Ensure ELBs can write to the operations bucket for logs --]
            "s3X${operationsBucketType}Xpolicy" : {
                "DependsOn" : [ "s3X${operationsBucketType}" ],
                "Type" : "AWS::S3::BucketPolicy",
                "Properties" : {
                    "Bucket" : "${operationsBucket}",
                    "PolicyDocument" : {
                        "Statement": [
                            {
                                "Effect": "Allow",
                                "Principal": {
                                    "AWS": "arn:aws:iam::${regionObject.Accounts["ELB"]}:root"
                                },
                                "Action": "s3:PutObject",
                                "Resource": "arn:aws:s3:::${operationsBucket}/AWSLogs/*"
                            }
                        ]
                    }
                }
            },
            [#-- Create data bucket --]
            "s3X${dataBucketType}" : {
                "Type" : "AWS::S3::Bucket",
                "Properties" : {
                    "BucketName" : "${dataBucket}",
                    "Tags" : [ 
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" }
                    ],
                    "LifecycleConfiguration" : {
                        "Rules" : [
                            {
                                "Id" : "default",
                                "ExpirationInDays" : ${dataExpiration},
                                "Status" : "Enabled"
                            }
                        ]
                    }
                }
            }
            [#break]

        [#case "outputs"]
            [#-- Current naming --]
            "s3XsegmentXoperations" : {
                "Value" : { "Ref" : "s3X${operationsBucketType}" }
            },
            "s3XsegmentXdata" : {
                "Value" : { "Ref" : "s3X${dataBucketType}" }
            },
            [#-- Legacy naming --]
            "s3X${operationsBucketSegment}X${operationsBucketType}" : {
                "Value" : { "Ref" : "s3X${operationsBucketType}" }
            },
            "s3X${dataBucketSegment}X${dataBucketType}" : {
                "Value" : { "Ref" : "s3X${dataBucketType}" }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]

