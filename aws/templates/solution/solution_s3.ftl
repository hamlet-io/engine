[#-- S3 --]
[#if componentType == "s3"]
    [#assign s3 = component.S3]

    [#assign s3Instances=[]]
    [#if s3.Versions??]
        [#list s3.Versions?values as version]
            [#if deploymentRequired(version, deploymentUnit)]
                [#if version.Instances??]
                    [#list version.Instances?values as s3Instance]
                        [#if deploymentRequired(s3Instance, deploymentUnit)]
                            [#assign s3Instances += [s3Instance +
                                {
                                    "Internal" : {
                                        "IdExtensions" : [
                                            version.Id,
                                            (s3Instance.Id == "default")?
                                                string(
                                                    "",
                                                    s3Instance.Id)],
                                        "NameExtensions" : [
                                            version.Name,
                                            (s3Instance.Id == "default")?
                                                string(
                                                    "",
                                                    s3Instance.Name)],
                                        "Lifecycle" : s3Instance.Lifecycle!version.Lifecycle!s3.Lifecycle!-1,
                                        "Style" : s3Instance.Style!version.Style!s3.Style!"domain",
                                        "Notifications" : s3Instance.Notifications!version.Notifications!s3.Notifications!-1
                                    }
                                }
                            ] ]
                        [/#if]
                    [/#list]
                [#else]
                    [#assign s3Instances += [version +
                        {
                            "Internal" : {
                                "IdExtensions" : [
                                    version.Id],
                                "NameExtensions" : [
                                    version.Name],
                                "Lifecycle" : version.Lifecycle!s3.Lifecycle!-1,
                                "Style" : version.Style!s3.Style!"domain",
                                "Notifications" : version.Notifications!s3.Notifications!-1
                            }
                        }
                    ]]
                [/#if]
            [/#if]
        [/#list]
    [#else]
        [#assign s3Instances += [s3 +
            {
                "Internal" : {
                    "IdExtensions" : [],
                    "NameExtensions" : [],
                    "Lifecycle" : s3.Lifecycle!-1,
                    "Style" : s3.Style!"domain",
                    "Notifications" : s3.Notifications!-1
                }
            }
        ]]
    [/#if]

    [#list s3Instances as s3Instance]

        [#assign s3Id = formatComponentS3Id(
                            tier,
                            component,
                            s3Instance)]

        [#if resourceCount > 0],[/#if]
        [#switch solutionListMode]
            [#case "definition"]
                [#-- Current bucket naming --]
                [#assign hostName = (s3.Name != "S3")?then(s3.Name, componentName)]
                [#assign bucketName = formatName(hostName, s3Instance, segmentDomainQualifier) + "." + segmentDomain]
                [#switch s3Instance.Internal.Style]
                    [#case "hyphenated"]
                        [#assign bucketName = bucketName?replace(".", "-")]
                        [#break]
                [/#switch]
                [#-- Support presence of existing s3 buckets (naming has changed over time) --]
                [#assign bucketName = getKey(s3Id)?has_content?then(
                                        getKey(s3Id),
                                        bucketName)]
                "${s3Id}" : {
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
                        [#if s3Instance.Internal.Lifecycle?is_hash]
                            [#assign s3Lifecycle = s3Instance.Internal.Lifecycle]
                            ,"LifecycleConfiguration" : {
                                "Rules" : [
                                    {
                                        "Id" : "default",
                                        [#if s3Lifecycle.Expiration??]
                                            "ExpirationInDays" : ${s3Lifecycle.Expiration},
                                        [/#if]
                                        "Status" : "Enabled"
                                    }
                                ]
                            }
                        [/#if]
                        [#if s3Instance.Internal.Notifications?is_hash]
                            ,"NotificationConfiguration" : {
                            [#if s3Instance.Internal.Notifications.SQS??]
                                [#assign sqsNotifications = s3Instance.Internal.Notifications.SQS]
                                "QueueConfigurations" : [
                                    [#assign queueCount = 0]
                                    [#list sqsNotifications?values as queue]
                                        [#if queue?is_hash]
                                            [#assign sqsArn = getKey(
                                                                formatComponentSQSArnId(
                                                                    queue.Tier!tier,
                                                                    queue.Component!queue.id,
                                                                    s3Instance))]
                                            [#if queueCount > 0],[/#if]
                                            {
                                                "Event" : "s3:ObjectCreated:*",
                                                "Queue" : "${sqsArn}"
                                            },
                                            {
                                                "Event" : "s3:ObjectRemoved:*",
                                                "Queue" : "${sqsArn}"
                                            },
                                            {
                                                "Event" : "s3:ReducedRedundancyLostObject",
                                                "Queue" : "${sqsArn}"
                                            }
                                            [#assign queueCount += 1]
                                        [/#if]
                                    [/#list]
                                ]
                            [/#if]
                            }
                        [/#if]
                    }
                    [#if s3Instance.Internal.Notifications?is_hash]
                        ,"DependsOn" : [
                            [#if s3Instance.Internal.Notifications.SQS??]
                                [#assign sqsNotifications = s3Instance.Internal.Notifications.SQS]
                                [#assign queueCount = 0]
                                [#list sqsNotifications?values as queue]
                                     [#if queue?is_hash]
                                        [#if queueCount > 0],[/#if]
                                        "${formatS3NotificationsQueuePolicyId(
                                            s3Id,
                                            queue)}"
                                        [#assign queueCount += 1]
                                     [/#if]
                                [/#list]
                            [/#if]
                        ]
                    [/#if]
                }
                [#if s3Instance.Internal.Notifications?is_hash &&
                        (s3Instance.Internal.Notifications.SQS)??]
                    [#assign sqsNotifications = s3Instance.Internal.Notifications.SQS]
                    [#assign queueCount = 0]
                    [#list sqsNotifications?values as queue]
                        [#if queue?is_hash]
                            [#assign sqsId = formatComponentSQSId(
                                                    queue.Tier!tier,
                                                    queue.Component!queue.id,
                                                    s3Instance)]
                            [@sqsPolicyHeader formatS3NotificationsQueuePolicyId(
                                                s3Id,
                                                queue) /]
                            [@sqsS3WriteStatement sqsId /]
                            [@sqsPolicyFooter sqsId /]
                        [/#if]
                    [/#list]
                [/#if]
                [#break]
    
            [#case "outputs"]
                [@output s3Id /],
                [@outputS3Url s3Id /]
                [#break]
    
        [/#switch]
        [#assign resourceCount += 1]
    [/#list]
[/#if]
