[#-- S3 --]
[#if componentType == "s3"]
    [#assign s3 = component.S3]
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            [#-- Current bucket naming --]
            [#if s3.Name != "S3"]
                [#assign bucketName = formatName(s3.Name, segmentDomainQualifier) + "." + segmentDomain]
            [#else]
                [#assign bucketName = formatName(component.Name, segmentDomainQualifier) + "." + segmentDomain]
            [/#if]
            [#-- Support presence of existing s3 buckets (naming has changed over time) --]
            [#assign bucketName = getKey("s3", componentIdStem)!bucketName]
            "${primaryResourceIdStem}" : {
                "Type" : "AWS::S3::Bucket",
                "Properties" : {
                    "BucketName" : "${bucketName}",
                    "Tags" : [
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" },
                        { "Key" : "cot:tier", "Value" : "${tierId}" },
                        { "Key" : "cot:component", "Value" : "${componentId}" }
                    ]
                    [#if s3.Lifecycle??]
                        ,"LifecycleConfiguration" : {
                            "Rules" : [
                                {
                                    "Id" : "default",
                                    [#if s3.Lifecycle.Expiration??]
                                        "ExpirationInDays" : ${s3.Lifecycle.Expiration},
                                    [/#if]
                                    "Status" : "Enabled"
                                }
                            ]
                        }
                    [/#if]
                    [#if s3.Notifications??]
                        ,"NotificationConfiguration" : {
                        [#if s3.Notifications.SQS??]
                            "QueueConfigurations" : [
                                [#assign queueCount = 0]
                                [#list s3.Notifications.SQS?values as queue]
                                    [#if queue?is_hash]
                                        [#if queueCount > 0],[/#if]
                                        {
                                            "Event" : "s3:ObjectCreated:*",
                                            "Queue" : "${getKey("sqs", tierId, queue.Id, "arn")}"
                                        },
                                        {
                                            "Event" : "s3:ObjectRemoved:*",
                                            "Queue" : "${getKey("sqs", tierId, queue.Id, "arn")}"
                                        },
                                        {
                                            "Event" : "s3:ReducedRedundancyLostObject",
                                            "Queue" : "${getKey("sqs", tierId, queue.Id, "arn")}"
                                        }
                                        [#assign queueCount += 1]
                                    [/#if]
                                [/#list]
                            ]
                        [/#if]
                        }
                    [/#if]
                }
                [#if s3.Notifications??]
                    ,"DependsOn" : [
                        [#if (s3.Notifications.SQS)??]
                            [#assign queueCount = 0]
                            [#list s3.Notifications.SQS?values as queue]
                                 [#if queue?is_hash]
                                    [#if queueCount > 0],[/#if]
                                    "${formatId(primaryResourceIdStem, queue.Id, "policy")}"
                                    [#assign queueCount += 1]
                                 [/#if]
                            [/#list]
                        [/#if]
                    ]
                [/#if]
            }
            [#if (s3.Notifications.SQS)??]
                [#assign queueCount = 0]
                [#list s3.Notifications.SQS?values as queue]
                    [#if queue?is_hash]
                        ,"${formatId(primaryResourceIdStem, queue.Id, "policy")}" : {
                            "Type" : "AWS::SQS::QueuePolicy",
                            "Properties" : {
                                "PolicyDocument" : {
                                    "Version" : "2012-10-17",
                                    "Id" : "${formatId(primaryResourceIdStem, queue.Id, "policy")}",
                                    "Statement" : [
                                        {
                                            "Effect" : "Allow",
                                            "Principal" : "*",
                                            "Action" : "sqs:SendMessage",
                                            "Resource" : "*",
                                            "Condition" : {
                                                "ArnLike" : {
                                                    "aws:sourceArn" : "arn:aws:s3:::*"
                                                }
                                            }
                                        }
                                    ]
                                },
                                "Queues" : [ "${getKey("sqs", componentIdStem, "url")}" ]
                            }
                        }
                    [/#if]
                [/#list]
            [/#if]
            [#break]

        [#case "outputs"]
            "${primaryResourceIdStem}" : {
                "Value" : { "Ref" : "${primaryResourceIdStem}" }
            },
            "${formatId(primaryResourceIdStem, "url")}" : {
                "Value" : { "Fn::GetAtt" : ["${primaryResourceIdStem}", "WebsiteURL"] }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]