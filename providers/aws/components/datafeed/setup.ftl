[#ftl]
[#macro aws_datafeed_cf_generationcontract_solution occurrence ]
    [@addDefaultGenerationContract subsets="template" /]
[/#macro]

[#macro aws_datafeed_cf_setup_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]
    [#local resources = occurrence.State.Resources]

    [#local streamId = resources["stream"].Id ]
    [#local streamName = resources["stream"].Name ]

    [#local streamRoleId = resources["role"].Id ]
    [#local streamRolePolicyId = formatDependentPolicyId(streamRoleId, "local")]

    [#local streamLgId = (resources["lg"].Id)!"" ]
    [#local streamLgName = (resources["lg"].Name)!"" ]
    [#local streamLgStreamId = (resources["streamlgstream"].Id)!""]
    [#local streamLgStreamName = (resources["streamlgstream"].Name)!""]
    [#local streamLgBackupId = (resources["backuplgstream"].Id)!""]
    [#local streamLgBackupName = (resources["backuplgstream"].Name)!""]

    [#local logging = solution.Logging ]
    [#local encrypted = solution.Encrypted]

    [#local streamProcessors = []]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "AppData", "Encryption"] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]

    [#local dataBucketId        = baselineComponentIds["AppData"]]
    [#local dataBucket          = getExistingReference(dataBucketId) ]
    [#local dataBucketPrefix    = getAppDataFilePrefix(occurrence) ]

    [#local cmkKeyId            = baselineComponentIds["Encryption"]]

    [#if solution.LogWatchers?has_content ]
        [#local streamSubscriptionRoleId = resources["subscriptionRole"].Id!"" ]
        [#local streamSubscriptionPolicyId = formatDependentPolicyId(streamSubscriptionRoleId, "local")]
    [/#if]

    [#if logging ]
        [#if deploymentSubsetRequired("lg", true) && isPartOfCurrentDeploymentUnit(streamLgId) ]
            [@createLogGroup
                id=streamLgId
                name=streamLgName /]

            [@createLogStream
                id=streamLgStreamId
                name=streamLgStreamName
                logGroup=streamLgName
                dependencies=streamLgId
            /]

            [@createLogStream
                id=streamLgBackupId
                name=streamLgBackupName
                logGroup=streamLgName
                dependencies=streamLgId
            /]

        [/#if]
    [/#if]

    [#list solution.LogWatchers as logWatcherName,logwatcher ]

        [#local logFilter = (logFilters[logwatcher.LogFilter].Pattern)!"" ]

        [#local logSubscriptionRoleRequired = true ]

        [#list logwatcher.Links as logWatcherLinkName,logWatcherLink ]
            [#local logWatcherLinkTarget = getLinkTarget(occurrence, logWatcherLink) ]

            [#if !logWatcherLinkTarget?has_content]
                [#continue]
            [/#if]

            [#local roleSource = logWatcherLinkTarget.State.Roles.Inbound["logwatch"]]

            [#list asArray(roleSource.LogGroupIds) as logGroupId ]

                [#local logGroupArn = getExistingReference(logGroupId, ARN_ATTRIBUTE_TYPE)]

                [#if logGroupArn?has_content ]

                    [#if deploymentSubsetRequired(DATAFEED_COMPONENT_TYPE, true)]
                        [@createLogSubscription
                            id=formatDependentLogSubscriptionId(streamId, logWatcherLink.Id, logGroupId?index)
                            logGroupName=getExistingReference(logGroupId)
                            filter=logFilter
                            destination=streamId
                            role=streamSubscriptionRoleId
                            dependencies=streamId
                        /]
                    [/#if]
                [/#if]
            [/#list]
        [/#list]
    [/#list]

    [#local links = getLinkTargets(occurrence) ]
    [#local linkPolicies = []]

    [#list links as linkId,linkTarget]

        [#local linkTargetCore = linkTarget.Core ]
        [#local linkTargetConfiguration = linkTarget.Configuration ]
        [#local linkTargetResources = linkTarget.State.Resources ]
        [#local linkTargetAttributes = linkTarget.State.Attributes ]

        [#switch linkTargetCore.Type]
            [#case LAMBDA_FUNCTION_COMPONENT_TYPE]

                [#local linkPolicies += lambdaKinesisPermission( linkTargetAttributes["ARN"])]

                [#local streamProcessors +=
                        [ getFirehoseStreamLambdaProcessor(
                            linkTargetAttributes["ARN"],
                            streamRoleId,
                            solution.Buffering.Interval,
                            solution.Buffering.Size
                        )]]
                [#break]

            [#default]
                [#local linkPolicies += getLinkTargetsOutboundRoles( { linkId, linkTarget} ) ]
        [/#switch]
    [/#list]

    [#local destinationLink = getLinkTarget(
                                    occurrence,
                                    solution.Destination.Link +
                                    {
                                        "Role" : "datafeed"
                                    }
                                )]

    [#if destinationLink?has_content ]
        [#local linkPolicies += getLinkTargetsOutboundRoles( { "destination", destinationLink} ) ]
    [/#if]

    [#if deploymentSubsetRequired("iam", true)]

        [#if isPartOfCurrentDeploymentUnit(streamRoleId)]

            [@createRole
                id=streamRoleId
                trustedServices=[ "firehose.amazonaws.com" ]
                policies=
                    [
                        getPolicyDocument(
                            encrypted?then(
                                s3EncryptionPermission(
                                        cmkKeyId,
                                        dataBucket,
                                        dataBucketPrefix,
                                        region
                                ),
                                []
                            ) +
                            logging?then(
                                cwLogsProducePermission(streamLgName),
                                []
                            ) +
                            s3AllPermission(dataBucket, dataBucketPrefix),
                            "base"
                        )
                    ] +
                    arrayIfContent(
                        [getPolicyDocument(linkPolicies, "links")],
                        linkPolicies)
            /]
        [/#if]

        [#if solution.LogWatchers?has_content &&
                isPartOfCurrentDeploymentUnit(streamSubscriptionRoleId)]

            [@createRole
                id=streamSubscriptionRoleId
                trustedServices=[ formatDomainName("logs", regionId, "amazonaws.com") ]
            /]
        [/#if]
    [/#if]

    [#if deploymentSubsetRequired(DATAFEED_COMPONENT_TYPE, true)]

        [#local streamDependencies = []]

        [#if !streamProcessors?has_content && solution.LogWatchers?has_content ]
            [@fatal
                message="Lambda stream processor required for CloudwatchLogs"
                detail="Add the lambda as a link to this feed"
                context=occurrence
            /]
        [/#if]

        [#if solution.LogWatchers?has_content ]
            [@createPolicy
                id=streamSubscriptionPolicyId
                name="local"
                statements=
                            (solution.LogWatchers?has_content)?then(
                                firehoseStreamCloudwatchPermission(streamId)  +
                                    iamPassRolePermission(
                                        getReference(streamSubscriptionRoleId, ARN_ATTRIBUTE_TYPE)
                                ),
                                []
                            )
                roles=streamSubscriptionRoleId
            /]
        [/#if]

        [#local streamLoggingConfiguration = getFirehoseStreamLoggingConfiguration(
                                                logging
                                                streamLgName
                                                streamLgStreamName )]

        [#local streamBackupLoggingConfiguration = getFirehoseStreamLoggingConfiguration(
                                                logging,
                                                streamLgName,
                                                streamLgBackupName )]

        [#local streamS3BackupDestination = getFirehoseStreamBackupS3Destination(
                                                dataBucketId,
                                                dataBucketPrefix,
                                                solution.Buffering.Interval,
                                                solution.Buffering.Size,
                                                streamRoleId,
                                                encrypted,
                                                cmkKeyId,
                                                streamBackupLoggingConfiguration )]


        [#switch (destinationLink.Core.Type)!"notfound" ]
            [#case S3_COMPONENT_TYPE ]
                [#local s3Id = destinationLink.State.Resources["bucket"].Id ]
                [#local streamS3Destination = getFirehoseStreamS3Destination(
                                                s3Id,
                                                solution.Bucket.Prefix,
                                                solution.Bucket.ErrorPrefix,
                                                solution.Buffering.Interval,
                                                solution.Buffering.Size,
                                                streamRoleId,
                                                encrypted,
                                                cmkKeyId,
                                                streamLoggingConfiguration,
                                                solution.Backup.Enabled,
                                                streamS3BackupDestination,
                                                streamProcessors
                )]

                [@createFirehoseStream
                    id=streamId
                    name=streamName
                    destination=streamS3Destination
                    dependencies=streamDependencies
                /]
                [#break]

            [#case ES_COMPONENT_TYPE ]

                [#local esId = destinationLink.State.Resources["es"].Id ]
                [#local streamESDestination = getFirehoseStreamESDestination(
                                                solution.Buffering.Interval,
                                                solution.Buffering.Size,
                                                esId,
                                                streamRoleId,
                                                solution.ElasticSearch.IndexPrefix,
                                                solution.ElasticSearch.IndexRotation,
                                                solution.ElasticSearch.DocumentType,
                                                solution.Backup.FailureDuration,
                                                solution.Backup.Policy,
                                                streamS3BackupDestination,
                                                streamLoggingConfiguration,
                                                streamProcessors)]

                [@createFirehoseStream
                    id=streamId
                    name=streamName
                    destination=streamESDestination
                    dependencies=streamDependencies
                /]
                [#break]

            [#default]
                [@fatal
                    message="Invalid stream destination or destination not found"
                    detail="Supported Destinations - ES"
                    context=occurrence
                /]
        [/#switch]
    [/#if]
[/#macro]
