[#ftl]
[#macro aws_s3_cf_generationcontract_solution occurrence ]
    [@addDefaultGenerationContract subsets="template" /]
[/#macro]

[#macro aws_s3_cf_setup_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]
    [#local links = getLinkTargets(occurrence )]

    [#local s3Id = resources["bucket"].Id ]
    [#local s3Name = resources["bucket"].Name ]

    [#local bucketPolicyId = resources["bucketpolicy"].Id ]

    [#local roleId = resources["role"].Id ]

    [#local versioningEnabled = solution.Lifecycle.Versioning ]

    [#local replicationEnabled = false]
    [#local replicationConfiguration = {} ]
    [#local replicationBucket = ""]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "CDNOriginKey" ])]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local cfAccessId  = getExistingReference(baselineComponentIds["CDNOriginKey"]!"", CANONICAL_ID_ATTRIBUTE_TYPE) ]

    [#local dependencies = [] ]

    [#local notifications = []]

    [#list solution.Notifications as id,notification ]
        [#if notification?is_hash]
            [#list notification.Links?values as link]
                [#if link?is_hash]
                    [#local linkTarget = getLinkTarget(occurrence, link, false) ]
                    [@debug message="Link Target" context=linkTarget enabled=false /]
                    [#if !linkTarget?has_content]
                        [#continue]
                    [/#if]

                    [#local linkTargetResources = linkTarget.State.Resources ]

                    [#if isLinkTargetActive(linkTarget) ]

                        [#local resourceId = "" ]
                        [#local resourceType = ""]

                        [#switch linkTarget.Core.Type]
                            [#case SQS_COMPONENT_TYPE ]
                                [#local resourceId = linkTargetResources["queue"].Id ]
                                [#local resourceType = linkTargetResources["queue"].Type ]

                                [#local policyId =
                                    formatS3NotificationPolicyId(
                                        s3Id,
                                        resourceId) ]

                                [#local dependencies += [policyId] ]

                                [#if deploymentSubsetRequired("s3", true)]
                                    [@createSQSPolicy
                                        id=policyId
                                        queues=resourceId
                                        statements=sqsS3WritePermission(resourceId, s3Name)
                                    /]
                                [/#if]

                                [#break]

                            [#case LAMBDA_FUNCTION_COMPONENT_TYPE ]
                                [#local resourceId = linkTargetResources["lambda"].Id ]
                                [#local resourceType = linkTargetResources["lambda"].Type ]

                                [#local policyId =
                                    formatS3NotificationPolicyId(
                                        s3Id,
                                        resourceId) ]

                                [#local dependencies += [policyId] ]

                                [#if deploymentSubsetRequired("s3", true)]
                                    [@createLambdaPermission
                                        id=policyId
                                        targetId=resourceId
                                        sourceId=s3Id
                                        sourcePrincipal="s3.amazonaws.com"
                                    /]
                                [/#if]

                                [#break]

                            [#case TOPIC_COMPONENT_TYPE]
                                [#local resourceId = linkTargetResources["topic"].Id ]
                                [#local resourceType = linkTargetResources["topic"].Type ]
                                [#local policyId =
                                    formatS3NotificationPolicyId(
                                        s3Id,
                                        resourceId) ]

                                [#local dependencies += [ policyId ]]

                                [#if deploymentSubsetRequired("s3", true )]
                                    [@createSNSPolicy
                                        id=policyId
                                        topics=resourceId
                                        statements=snsS3WritePermission(resourceId, s3Name)
                                    /]
                                [/#if]
                        [/#switch]

                        [#list notification.Events as event ]
                            [#local notifications +=
                                    getS3Notification(resourceId, resourceType, event, notification.Prefix, notification.Suffix) ]
                        [/#list]
                    [/#if]
                [/#if]
            [/#list]
        [/#if]
    [/#list]

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

            [@debug message="Link Target" context=linkTarget enabled=false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]

            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetConfiguration = linkTarget.Configuration ]
            [#local linkTargetResources = linkTarget.State.Resources ]
            [#local linkTargetAttributes = linkTarget.State.Attributes ]
            [#local linkDirection = linkTarget.Direction ]

            [#switch linkTargetCore.Type]
                [#case CDN_ROUTE_COMPONENT_TYPE ]

                    [#local originPath = (linkTargetConfiguration.Solution.Origin.BasePath)?remove_ending("/") ]
                    [#if linkDirection == "inbound" ]
                        [#local policyStatements +=
                                s3ReadPermission(
                                    s3Name,
                                    originPath,
                                    "*",
                                    {
                                        "CanonicalUser": cfAccessId
                                    }
                                )
                        ]
                    [/#if]
                    [#break]

                [#case S3_COMPONENT_TYPE ]
                    [#switch linkTarget.Role ]
                        [#case  "replicadestination" ]
                            [#local replicationEnabled = true]
                            [#if linkTargetAttributes["REGION"] == regionId ]
                                [@fatal
                                    dmessageescription="Replication buckets must be in different regions"
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
                                    [@fatal
                                        message="Replication destination must be deployed before source"
                                        context=
                                            linkTarget
                                    /]
                                [/#if]
                                [#local replicationBucket = linkTargetAttributes["ARN"]]
                            [#else]
                                [@fatal
                                    message="Only one replication destination is supported"
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
                id=roleId
                trustedServices=["s3.amazonaws.com"]
                policies=rolePolicies
            /]
        [/#if]
    [/#if]

    [#if deploymentSubsetRequired("s3", true)]

        [#if policyStatements?has_content ]
            [@createBucketPolicy
                id=bucketPolicyId
                bucket=s3Name
                statements=policyStatements
                dependencies=s3Id
            /]
        [/#if]

        [@createS3Bucket
            id=s3Id
            name=s3Name
            tier=core.Tier
            component=core.Component
            lifecycleRules=
                (solution.Lifecycle.Configured && solution.Lifecycle.Enabled && ((solution.Lifecycle.Expiration!operationsExpiration)?has_content || (solution.Lifecycle.Offline!operationsOffline)?has_content))?then(
                        getS3LifecycleRule(solution.Lifecycle.Expiration!operationsExpiration, solution.Lifecycle.Offline!operationsOffline),
                        []
                )
            notifications=notifications
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
