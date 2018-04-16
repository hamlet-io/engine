[#-- S3 --]

[#if (componentType == S3_COMPONENT_TYPE) && deploymentSubsetRequired("s3", true)]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]
        [#assign resources = occurrence.State.Resources ]

        [#assign s3Id = resources["bucket"].Id ]
        [#assign s3Name = resources["bucket"].Name ]

        [#assign sqsIds = [] ]
        [#assign sqsNotifications = [] ]
        [#assign dependencies = [] ]
        [#list ((configuration.Notifications.SQS)!{})?values as queue]
            [#if queue?is_hash]
                [#assign linkTarget =
                    getLinkTarget(
                        occurrence,
                        {
                            "Tier" : queue.Tier!tier,
                            "Component" : queue.Component!queue.Id
                        }) ]
                [#if !linkTarget?has_content]
                    [#continue]
                [/#if]

                [#assign sqsId = (linkTarget.State.Resources["queue"].Id)!"" ]
                [#if sqsId?has_content]
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
            [/#if]
        [/#list]

        [@createS3Bucket
            mode=listMode
            id=s3Id
            name=s3Name
            tier=tier
            component=component
            lifecycleRules=
                (configuration.Lifecycle.Configured && ((configuration.Lifecycle.Expiration!operationsExpiration)?has_content || (configuration.Lifecycle.Offline!operationsOffline)?has_content))?then(
                        getS3LifecycleRule(configuration.Lifecycle.Expiration!operationsExpiration,configuration.Lifecycle.Offline!operationsOffline),
                        []
                )
            sqsNotifications=sqsNotifications
            websiteConfiguration=
                (configuration.Website.Configured && configuration.Website.Enabled)?then(
                    getS3WebsiteConfiguration(configuration.Website.Index, configuration.Website.Error),
                    {})
            versioning=configuration.Lifecycle.Versioning
            dependencies=dependencies
        /]

    [/#list]
[/#if]