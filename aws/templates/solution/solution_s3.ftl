[#-- S3 --]

[#if (componentType == S3_COMPONENT_TYPE)]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]
        [#assign links = getLinkTargets(occurrence )]

        [#assign s3Id = resources["bucket"].Id ]
        [#assign s3Name = resources["bucket"].Name ]

        [#assign roleId = resources["role"].Id ]

        [#assign versioningEnabled = solution.Lifecycle.Versioning ]

        [#assign replicationEnabled = false]
        [#assign replicationConfiguration = {} ]
        [#assign replicationBucket = ""]

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

        [#assign policyStatements = [] ]

        [#list solution.PublicAccess?values as publicAccessConfiguration]
            [#list publicAccessConfiguration.Paths as publicPrefix]
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
            [#assign bucketPolicyId = resources["bucketpolicy"].Id ]
            [@createBucketPolicy
                mode=listMode
                id=bucketPolicyId
                bucket=s3Name
                statements=policyStatements
                dependencies=s3Id
            /]
        [/#if]

        [#list solution.Links?values as link]
            [#if link?is_hash]

                [#assign linkTarget = getLinkTarget(occurrence, link, false) ]

                [@cfDebug listMode linkTarget false /]

                [#if !linkTarget?has_content]
                    [#continue]
                [/#if]

                [#assign linkTargetCore = linkTarget.Core ]
                [#assign linkTargetConfiguration = linkTarget.Configuration ]
                [#assign linkTargetResources = linkTarget.State.Resources ]
                [#assign linkTargetAttributes = linkTarget.State.Attributes ]

                [#switch linkTargetCore.Type]
                    [#case S3_COMPONENT_TYPE ]
                        [#switch linkTarget.Role ]
                            [#case  "replicadestination" ]
                                [#assign replicationEnabled = true]
                                [#if linkTargetAttributes["REGION"] == regionId ]
                                    [@cfException 
                                        mode=listMode
                                        description="Replication buckets must be in different regions" 
                                        context=
                                            { 
                                                "SourceBucket" : regionId,
                                                "DestinationBucket" : linkTargetAttributes["REGION"]
                                            }
                                    /]
                                [/#if]

                                [#assign versioningEnabled = true]

                                [#if !replicationBucket?has_content ]
                                    [#if !linkTargetAttributes["ARN"]?has_content ]
                                        [@cfException 
                                            mode=listMode
                                            description="Replication destination must be deployed before source" 
                                            context=
                                                linkTarget
                                        /]
                                    [/#if]
                                    [#assign replicationBucket = linkTargetAttributes["ARN"]]
                                [#else]
                                    [@cfException 
                                        mode=listMode 
                                        description="Only one replication destination is supported" 
                                        context=links
                                    /]
                                [/#if]
                                [#break]

                            [#case "replicasource" ]
                                [#assign versioningEnabled = true]
                                [#break]
                        [/#switch]
                        [#break]
                [/#switch]
            [/#if]
        [/#list]

        [#-- Add Replication Rules --]
        [#if replicationEnabled ]
            [#assign replicationRules = [] ]
            [#list solution.Replication.Prefixes as prefix ]
                [#assign replicationRules += 
                    [ getS3ReplicationRule(
                        replicationBucket,
                        solution.Replication.Enabled,
                        prefix,
                        false
                    )]]
            [/#list]

            [#assign replicationConfiguration = getS3ReplicationConfiguration(
                                                    roleId,
                                                    replicationRules
                                                )]
        [/#if]

        [#if deploymentSubsetRequired("iam", true) &&
                isPartOfCurrentDeploymentUnit(roleId)]
            [#assign linkPolicies = getLinkTargetsOutboundRoles(links) ]

            [#assign rolePolicies = 
                    arrayIfContent(
                        [getPolicyDocument(linkPolicies, "links")],
                        linkPolicies) +
                    arrayIfContent(
                        getPolicyDocument( 
                            s3ReplicaSourcePermission(s3Id) + 
                            s3ReplicationConfigurationPermission(s3Id), 
                            "replication"),
                        replicationConfiguration
                    )]
            
            [#if rolePolicies?has_content ]
                [@createRole
                    mode=listMode
                    id=roleId
                    trustedServices=["s3.amazonaws.com"]
                    policies=rolePolicies
                /]
            [/#if]
        [/#if]

        [#if deploymentSubsetRequired("s3", true)]
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
                    (isPresent(solution.Website))?then(
                        getS3WebsiteConfiguration(solution.Website.Index, solution.Website.Error),
                        {})
                versioning=versioningEnabled
                CORSBehaviours=solution.CORSBehaviours
                replicationConfiguration=replicationConfiguration
                dependencies=dependencies
            /]
        [/#if]

    [/#list]
[/#if]
