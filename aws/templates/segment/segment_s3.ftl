[#-- Standard set of buckets for a segment --]

[#if deploymentUnit?contains("s3")]

    [#-- TODO: Should be using formatSegmentS3Id() not formatS3Id() --]
    [#assign s3OperationsId = formatS3Id(operationsBucketType)]
    [#assign s3DataId = formatS3Id(dataBucketType)]
    [#assign s3OperationsPolicyId = formatS3BucketPolicyId(s3OperationsId)]

    [#if resourceCount > 0],[/#if]
    [#switch segmentListMode]
        [#case "definition"]
            [#-- Create operations bucket --]
            "${s3OperationsId}" : {
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
                                    "ExpirationInDays" : ${operationsExpiration},
                                    "Prefix" : "AWSLogs",
                                    "Status" : "Enabled"
                                },
                                {
                                    "ExpirationInDays" : ${operationsExpiration},
                                    "Prefix" : "CLOUDFRONTLogs",
                                    "Status" : "Enabled"
                                },
                                {
                                    "ExpirationInDays" : ${operationsExpiration},
                                    "Prefix" : "DOCKERLogs",
                                    "Status" : "Enabled"
                                }
                            ]
                        }
                    [/#if]
                }
            },
            [#-- Ensure ELBs can write to the operations bucket for logs --]
            "${s3OperationsPolicyId}" : {
                "DependsOn" : [ "${s3OperationsId}" ],
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
            "${s3DataId}" : {
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
            [#-- TODO: Should be using s3OperationsId not formatSegmentS3Id("ops") --]
            "${formatSegmentS3Id("ops")}" : {
                "Value" : { "Ref" : "${s3OperationsId}" }
            },
            [#-- TODO: Should be using s3DataId not formatSegmentS3Id("data") --]
            "${formatSegmentS3Id("data")}" : {
                "Value" : { "Ref" : "${s3DataId}" }
            },
            [#-- Legacy naming --]
            [#-- TODO: Remove --]
            "${formatSegmentS3Id("operations")}" : {
                "Value" : { "Ref" : "${s3OperationsId}" }
            },
            "${formatSegmentS3Id("logs")}" : {
                "Value" : { "Ref" : "${s3OperationsId}" }
            },
            "${formatContainerS3Id("logs")}" : {
                "Value" : { "Ref" : "${s3OperationsId}" }
            },
            "${formatSegmentS3Id("backups")}" : {
                "Value" : { "Ref" : "${s3DataId}" }
            },
            "${formatContainerS3Id("backups")}" : {
                "Value" : { "Ref" : "${s3DataId}" }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]

