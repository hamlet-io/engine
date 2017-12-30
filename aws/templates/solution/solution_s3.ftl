[#-- S3 --]

[#if (componentType == "s3") && deploymentSubsetRequired("s3", true)]
    [#assign s3 = component.S3]

    [#list getOccurrences(component, deploymentUnit) as occurrence]

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
                getExistingReference(s3Id)?has_content?then(
                    getExistingReference(s3Id),
                    formatHostDomainName(
                        [
                            (s3.Name != "S3")?then(s3.Name, componentName),
                            occurrence,
                            segmentDomainQualifier
                        ],
                        segmentDomain,
                        occurrence.Style))
            tier=tier
            component=component
            lifecycleRules=
                (occurrence.LifecycleIsConfigured && (occurrence.Lifecycle.Expiration!operationsExpiration)?has_content)?then(
                    getS3LifecycleExpirationRule(occurrence.Lifecycle.Expiration!operationsExpiration),
                    [])
            sqsNotifications=sqsNotifications
            dependencies=dependencies
        /]

    [/#list]
[/#if]
