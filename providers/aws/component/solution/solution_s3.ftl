[#ftl]
[#macro aws_s3_cf_solution occurrence ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["template"])
        /]
        [#return]
    [/#if]

    [@cfDebug listMode occurrence false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]
    [#local links = getLinkTargets(occurrence )]

    [#local s3Id = resources["bucket"].Id ]
    [#local s3Name = resources["bucket"].Name ]

    [#local roleId = resources["role"].Id ]

    [#local versioningEnabled = solution.Lifecycle.Versioning ]

    [#local replicationEnabled = false]
    [#local replicationConfiguration = {} ]
    [#local replicationBucket = ""]

    [#local sqsNotifications = [] ]
    [#local sqsNotificationIds = [] ]
    [#local dependencies = [] ]

    [#list solution.Notifications as id,notification ]
        [#if notification?is_hash]
            [#list notification.Links?values as link]
                [#if link?is_hash]
                    [#local linkTarget = getLinkTarget(occurrence, link, false) ]
                    [@cfDebug listMode linkTarget false /]
                    [#if !linkTarget?has_content]
                        [#continue]
                    [/#if]

                    [#local linkTargetResources = linkTarget.State.Resources ]

                    [#switch linkTarget.Core.Type]
                        [#case AWS_SQS_RESOURCE_TYPE ]
                            [#if isLinkTargetActive(linkTarget) ]
                                [#local sqsId = linkTargetResources["queue"].Id ]
                                [#local sqsNotificationIds = [ sqsId ]]
                                [#list notification.Events as event ]
                                    [#local sqsNotifications +=
                                            getS3SQSNotification(sqsId, event, notification.Prefix, notification.Suffix) ]
                                [/#list]

                            [/#if]
                            [#break]
                    [/#switch]
                [/#if]
            [/#list]
        [/#if]
    [/#list]

    [#if deploymentSubsetRequired("s3", true)]
        [#list sqsNotificationIds as sqsId ]
            [#local sqsPolicyId =
                formatS3NotificationsQueuePolicyId(
                    s3Id,
                    sqsId) ]
            [@createSQSPolicy
                    mode=listMode
                    id=sqsPolicyId
                    queues=sqsId
                    statements=sqsS3WritePermission(sqsId, s3Name)
                /]
            [#local dependencies += [sqsPolicyId] ]
        [/#list]
    [/#if]

    [#local policyStatements = [] ]

    [#list solution.PublicAccess?values as publicAccessConfiguration]
        [#list publicAccessConfiguration.Paths as publicPrefix]
            [#if publicAccessConfiguration.Enabled ]
                [#local publicIPWhiteList =
                    getIPCondition(getGroupCIDRs(publicAccessConfiguration.IPAddressGroups, true)) ]

                [#switch publicAccessConfiguration.Permissions ]
                    [#case "ro" ]
                        [#local policyStatements += s3ReadPermission(
                                                        s3Name,
                                                        publicPrefix,
                                                        "*",
                                                        "*",
                                                        publicIPWhiteList)]
                        [#break]
                    [#case "wo" ]
                        [#local policyStatements += s3WritePermission(
                                                        s3Name,
                                                        publicPrefix,
                                                        "*",
                                                        "*",
                                                        publicIPWhiteList)]
                        [#break]
                    [#case "rw" ]
                        [#local policyStatements += s3AllPermission(
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

    [#list solution.Links?values as link]
        [#if link?is_hash]

            [#local linkTarget = getLinkTarget(occurrence, link, false) ]

            [@cfDebug listMode linkTarget false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]

            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetConfiguration = linkTarget.Configuration ]
            [#local linkTargetResources = linkTarget.State.Resources ]
            [#local linkTargetAttributes = linkTarget.State.Attributes ]

            [#switch linkTargetCore.Type]
                [#case S3_COMPONENT_TYPE ]
                    [#switch linkTarget.Role ]
                        [#case  "replicadestination" ]
                            [#local replicationEnabled = true]
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

                            [#local versioningEnabled = true]

                            [#if !replicationBucket?has_content ]
                                [#if !linkTargetAttributes["ARN"]?has_content ]
                                    [@cfException
                                        mode=listMode
                                        description="Replication destination must be deployed before source"
                                        context=
                                            linkTarget
                                    /]
                                [/#if]
                                [#local replicationBucket = linkTargetAttributes["ARN"]]
                            [#else]
                                [@cfException
                                    mode=listMode
                                    description="Only one replication destination is supported"
                                    context=links
                                /]
                            [/#if]
                            [#break]

                        [#case "replicasource" ]
                            [#local versioningEnabled = true]
                            [#break]
                    [/#switch]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]

    [#-- Add Replication Rules --]
    [#if replicationEnabled ]
        [#local replicationRules = [] ]
        [#list solution.Replication.Prefixes as prefix ]
            [#local replicationRules +=
                [ getS3ReplicationRule(
                    replicationBucket,
                    solution.Replication.Enabled,
                    prefix,
                    false
                )]]
        [/#list]

        [#local replicationConfiguration = getS3ReplicationConfiguration(
                                                roleId,
                                                replicationRules
                                            )]
    [/#if]

    [#if deploymentSubsetRequired("iam", true) &&
            isPartOfCurrentDeploymentUnit(roleId)]
        [#local linkPolicies = getLinkTargetsOutboundRoles(links) ]

        [#local rolePolicies =
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

        [#if policyStatements?has_content ]
            [#local bucketPolicyId = resources["bucketpolicy"].Id ]
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
            tier=core.Tier
            component=core.Component
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
[/#macro]
