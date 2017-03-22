[#-- Standard set of buckets for a segment --]
[#if deploymentUnit?contains("s3")]
    [#if resourceCount > 0],[/#if]
    [#switch segmentListMode]
        [#case "definition"]
            [#-- Create operations bucket --]
            "${formatId("s3", operationsBucketType)}" : {
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
                    ]
                    [#if operationsExpiration?is_number]
                        ,"LifecycleConfiguration" : {
                            "Rules" : [
                                {
                                    "Id" : "default",
                                    "ExpirationInDays" : ${operationsExpiration},
                                    "Status" : "Enabled"
                                }
                            ]
                        }
                    [/#if]
                }
            },
            [#-- Ensure ELBs can write to the operations bucket for logs --]
            "${formatId("s3", operationsBucketType, "policy")}" : {
                "DependsOn" : [ "${formatId("s3", operationsBucketType)}" ],
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
            "${formatId("s3", dataBucketType)}" : {
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
                    ]
                    [#if dataExpiration?is_number]
                        ,"LifecycleConfiguration" : {
                            "Rules" : [
                                {
                                    "Id" : "default",
                                    "ExpirationInDays" : ${dataExpiration},
                                    "Status" : "Enabled"
                                }
                            ]
                        }
                    [/#if]
                }
            }
            [#break]

        [#case "outputs"]
            [#-- Current naming --]
            "${formatId("s3", "segment", "operations")}" : {
                "Value" : { "Ref" : "${formatId("s3", operationsBucketType)}" }
            },
            "${formatId("s3", "segment", "data")}" : {
                "Value" : { "Ref" : "${formatId("s3", dataBucketType)}" }
            },
            [#-- Legacy naming --]
            "${formatId("s3", operationsBucketSegment, operationsBucketType)}" : {
                "Value" : { "Ref" : "${formatId("s3", operationsBucketType)}" }
            },
            "${formatId("s3", dataBucketSegment, dataBucketType)}" : {
                "Value" : { "Ref" : "${formatId("s3", dataBucketType)}" }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]

