[#-- S3 --]

[#if (componentType == S3_COMPONENT_TYPE) && deploymentSubsetRequired("s3", true)]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#assign s3Id = resources["bucket"].Id ]
        [#assign s3Name = resources["bucket"].Name ]

        [#assign sqsIds = [] ]
        [#assign sqsNotifications = [] ]
        [#assign dependencies = [] ]
        [#list ((solution.Notifications.SQS)!{})?values as queue]
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

        [#assign bucketPolicyId = resources["bucketpolicy"].Id ]
        [#assign policyStatements = [] ]

        [#list solution.PublicAccess?values as publicAccessConfiguration]
            [#list asArray(publicAccessConfiguration.Paths) as publicPrefix]
                [#if publicAccessConfiguration.Enabled ]
                    [#assign publicIPWhiteList =
                        getIPCondition(getGroupCIDRs(publicAccessConfiguration.IPAddressGroups, true)) ]

                    [#switch publicAccessConfiguration.Permissions ]
                        [#case "ro" ]
                            [#assign policyStatements += s3ReadPermission(
                                                            s3Name,
                                                            publicPrefix,
                                                            "*",
                                                            "*",
                                                            publicIPWhiteList)]
                            [#break]
                        [#case "wo" ]
                            [#assign policyStatements += s3WritePermission(
                                                            s3Name,
                                                            publicPrefix,
                                                            "*",
                                                            "*",
                                                            publicIPWhiteList)]
                            [#break]
                        [#case "rw" ]
                            [#assign policyStatements += s3AllPermission(
                                                            s3Name,
                                                            publicPrefix,
                                                            "*",
                                                            "*",
                                                            publicIPWhiteList)]
                            [#break]
                    [/#switch]
                [/#if]
            [/#list]
        [/#list]
        
        [#if policyStatements?has_content ]

            [@createBucketPolicy
                mode=listMode
                id=bucketPolicyId
                bucket=s3Name
                statements=policyStatements
                dependencies=s3Id
            /]
        [/#if]

        [@createS3Bucket
            mode=listMode
            id=s3Id
            name=s3Name
            tier=tier
            component=component
            lifecycleRules=

                (solution.Lifecycle.Configured && ((solution.Lifecycle.Expiration!operationsExpiration)?has_content || (solution.Lifecycle.Offline!operationsOffline)?has_content))?then(
                        getS3LifecycleRule(solution.Lifecycle.Expiration!operationsExpiration, solution.Lifecycle.Offline!operationsOffline),
                        []
                )
            sqsNotifications=sqsNotifications
            websiteConfiguration=
                (solution.Website.Configured && solution.Website.Enabled)?then(
                    getS3WebsiteConfiguration(solution.Website.Index, solution.Website.Error),
                    {})
            versioning=solution.Lifecycle.Versioning
            CORSBehaviours=solution.CORSBehaviours
            dependencies=dependencies
        /]

    [/#list]
[/#if]