[#-- S3 --]

[#if componentType == "s3"]
    [#assign s3 = component.S3]

    [#list getComponentOccurrences(component, deploymentUnit) as occurrence]

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
                    mode=solutionListMode
                    id=sqsPolicyId
                    queues=sqsId
                    statements=getSqsWriteStatement(sqsId)
                /]
            [/#if]
        [/#list]
                            
        [@createS3Bucket
            mode=solutionListMode
            id=s3Id
            name=
                getKey(s3Id)?has_content?then(
                    getKey(s3Id),
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
                ((occurrence.Lifecycle.Expiration)!"")?has_content?then(
                    getS3LifecycleExpirationRule(occurrence.Lifecycle.Expiration),
                    [])
            sqsNotifications=sqsNotifications
            dependencies=dependencies
        /]

    [/#list]
[/#if]
