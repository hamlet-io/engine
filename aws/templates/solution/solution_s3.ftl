[#-- S3 --]

[#if (componentType == "s3") && deploymentSubsetRequired("s3", true)]
    [#assign s3 = component.S3]

    [#list getOccurrences(component, tier, component, deploymentUnit) as occurrence]

        [#assign s3Id = formatComponentS3Id(
                            tier,
                            component,
                            occurrence)]
        [#assign sqsIds = [] ]
        [#assign sqsNotifications = [] ]
        [#assign dependencies = [] ]
        [#list ((occurrence.Notifications.SQS)!{})?values as queue]
            [#if queue?is_hash]
                [#assign sqsId = 
                    formatComponentSQSId(
                        queue.Tier!tier,
                        queue.Component!queue.Id,
                        occurrence) ]
                [#assign sqsIds += [sqsId] ]
                [#assign sqsNotifications +=
                    getS3SQSNotification(sqsId, "s3:ObjectCreated:*") +
                    getS3SQSNotification(sqsId, "s3:ObjectRemoved:*") +
                    getS3SQSNotification(sqsId, "s3:ReducedRedundancyLostObject") ]
                [#assign sqsPolicyId =
                    formatS3NotificationsQueuePolicyId(
                        s3Id,
                        queue) ]
                [#assign dependencies += [sqsPolicyId] ]
                [@createSQSPolicy
                    mode=listMode
                    id=sqsPolicyId
                    queues=sqsId
                    statements=sqsWritePermission(sqsId)
                /]
            [/#if]
        [/#list]
                            
        [@createS3Bucket
            mode=listMode
            id=s3Id
            name=
                firstContent(
                    getExistingReference(s3Id, NAME_ATTRIBUTE_TYPE),
                    formatComponentBucketName(tier, component, occurrence))
            tier=tier
            component=component
            lifecycleRules=
                (occurrence.Lifecycle.Configured && (occurrence.Lifecycle.Expiration!operationsExpiration)?has_content)?then(
                    getS3LifecycleExpirationRule(occurrence.Lifecycle.Expiration!operationsExpiration),
                    [])
            sqsNotifications=sqsNotifications
            websiteConfiguration=
                (occurrence.Website.Configured && occurrence.Website.Enabled)?then(
                    getS3WebsiteConfiguration(occurrence.Website.Index, occurrence.Website.Error),
                    {})
            dependencies=dependencies
        /]

    [/#list]
[/#if]