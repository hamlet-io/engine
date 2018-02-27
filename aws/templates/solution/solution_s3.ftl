[#-- S3 --]

[#if (componentType == "s3") && deploymentSubsetRequired("s3", true)]
    [#assign s3 = component.S3]

    [#list requiredOccurrences(
            getOccurrences(component, tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]
        
        [#assign s3Id = formatComponentS3Id(
                            tier,
                            component,
                            occurrence)]
        [#assign sqsIds = [] ]
        [#assign sqsNotifications = [] ]
        [#assign dependencies = [] ]
        [#list ((configuration.Notifications.SQS)!{})?values as queue]
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
                (configuration.Lifecycle.Configured && (configuration.Lifecycle.Expiration!operationsExpiration)?has_content)?then(
                    getS3LifecycleExpirationRule(configuration.Lifecycle.Expiration!operationsExpiration),
                    [])
            sqsNotifications=sqsNotifications
            websiteConfiguration=
                (configuration.Website.Configured && configuration.Website.Enabled)?then(
                    getS3WebsiteConfiguration(configuration.Website.Index, configuration.Website.Error),
                    {})
            dependencies=dependencies
        /]

    [/#list]
[/#if]