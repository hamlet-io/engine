[#ftl]
[#macro aws_datafeed_cf_solution occurrence ]
    [@cfDebug listMode occurrence false /]

    [#assign core = occurrence.Core]
    [#assign solution = occurrence.Configuration.Solution]
    [#assign resources = occurrence.State.Resources]

    [#assign streamId = resources["stream"].Id ]
    [#assign streamName = resources["stream"].Name ]

    [#assign streamRoleId = resources["role"].Id ]
    [#assign streamRolePolicyId = formatDependentPolicyId(streamRoleId, "local")]

    [#assign streamSubscriptionRoleId = resources["subscriptionRole"].Id!"" ]
    [#assign streamSubscriptionPolicyId = formatDependentPolicyId(streamSubscriptionRoleId, "local")]

    [#assign streamLgId = (resources["lg"].Id)!"" ]
    [#assign streamLgName = (resources["lg"].Name)!"" ]
    [#assign streamLgStreamId = (resources["streamlgstream"].Id)!""]
    [#assign streamLgStreamName = (resources["streamlgstream"].Name)!""]
    [#assign streamLgBackupId = (resources["backuplgstream"].Id)!""]
    [#assign streamLgBackupName = (resources["backuplgstream"].Name)!""]

    [#assign logging = solution.Logging ]
    [#assign encrypted = solution.Encrypted]

    [#assign streamProcessors = []]

    [#assign appDataLink = getLinkTarget(occurrence,
                                {
                                    "Tier" : "mgmt",
                                    "Component" : "baseline",
                                    "Instance" : "",
                                    "Version" : "",
                                    "DataBucket" : "appdata"
                                }
    )]

    [#assign appdataBucketId = appDataLink.State.Resources["bucket"].Id ]
    [#assign dataBucketPrefix = getAppDataFilePrefix(occurrence) ]

    [#if logging ]
        [#if deploymentSubsetRequired("lg", true) && isPartOfCurrentDeploymentUnit(streamLgId) ]
            [@createLogGroup
                mode=listMode
                id=streamLgId
                name=streamLgName /]

            [@createLogStream
                mode=listMode
                id=streamLgStreamId
                name=streamLgStreamName
                logGroup=streamLgName
                dependencies=streamLgId
            /]

            [@createLogStream
                mode=listMode
                id=streamLgBackupId
                name=streamLgBackupName
                logGroup=streamLgName
                dependencies=streamLgId
            /]

        [/#if]
    [/#if]

    [#list solution.LogWatchers as logWatcherName,logwatcher ]

        [#assign logFilter = (logFilters[logwatcher.LogFilter].Pattern)!"" ]

        [#assign logSubscriptionRoleRequired = true ]

        [#list logwatcher.Links as logWatcherLinkName,logWatcherLink ]
            [#assign logWatcherLinkTarget = getLinkTarget(occurrence, logWatcherLink) ]

            [#if !logWatcherLinkTarget?has_content]
                [#continue]
            [/#if]

            [#assign roleSource = logWatcherLinkTarget.State.Roles.Inbound["logwatch"]]

            [#list asArray(roleSource.LogGroupIds) as logGroupId ]

                [#assign logGroupArn = getExistingReference(logGroupId, ARN_ATTRIBUTE_TYPE)]

                [#if logGroupArn?has_content ]

                    [#if deploymentSubsetRequired(DATAFEED_COMPONENT_TYPE, true)]
                        [@createLogSubscription
                            mode=listMode
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

    [#assign links = getLinkTargets(occurrence) ]
    [#assign linkPolicies = []]

    [#list links as linkId,linkTarget]

        [#assign linkTargetCore = linkTarget.Core ]
        [#assign linkTargetConfiguration = linkTarget.Configuration ]
        [#assign linkTargetResources = linkTarget.State.Resources ]
        [#assign linkTargetAttributes = linkTarget.State.Attributes ]

        [#switch linkTargetCore.Type]
            [#case LAMBDA_FUNCTION_COMPONENT_TYPE]

                [#assign linkPolicies += lambdaKinesisPermission( linkTargetAttributes["ARN"])]

                [#assign streamProcessors +=
                        [ getFirehoseStreamLambdaProcessor(
                            linkTargetAttributes["ARN"],
                            streamRoleId,
                            solution.Buffering.Interval,
                            solution.Buffering.Size
                        )]]
                [#break]

            [#default]
                [#assign linkPolicies += getLinkTargetsOutboundRoles( { linkId, linkTarget} ) ]
        [/#switch]
    [/#list]

    [#assign destinationLink = getLinkTarget(
                                    occurrence,
                                    solution.Destination.Link +
                                    {
                                        "Role" : "datafeed"
                                    }
                                )]

    [#if destinationLink?has_content ]
        [#assign linkPolicies += getLinkTargetsOutboundRoles( { "destination", destinationLink} ) ]
    [/#if]

    [#if deploymentSubsetRequired("iam", true)]

        [#if isPartOfCurrentDeploymentUnit(streamRoleId)]

            [@createRole
                mode=listMode
                id=streamRoleId
                trustedServices=[ "firehose.amazonaws.com" ]
                policies=
                    [
                        getPolicyDocument(
                            encrypted?then(
                                s3EncryptionPermission(
                                        formatSegmentCMKId(),
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
                mode=listMode
                id=streamSubscriptionRoleId
                trustedServices=[ formatDomainName("logs", regionId, "amazonaws.com") ]
            /]
        [/#if]
    [/#if]

    [#if deploymentSubsetRequired(DATAFEED_COMPONENT_TYPE, true)]

        [#assign streamDependencies = []]

        [#if !streamProcessors?has_content && solution.LogWatchers?has_content ]
            [@cfException
                mode=listMode
                description="Lambda stream processor required for CloudwatchLogs"
                detail="Add the lambda as a link to this feed"
                context=occurrence
            /]
        [/#if]

        [#if solution.LogWatchers?has_content ]
            [@createPolicy
                mode=listMode
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

        [#assign streamLoggingConfiguration = getFirehoseStreamLoggingConfiguration(
                                                logging
                                                streamLgName
                                                streamLgStreamName )]

        [#assign streamBackupLoggingConfiguration = getFirehoseStreamLoggingConfiguration(
                                                logging,
                                                streamLgName,
                                                streamLgBackupName )]

        [#assign streamS3BackupDestination = getFirehoseStreamS3Destination(
                                                appdataBucketId,
                                                dataBucketPrefix,
                                                solution.Buffering.Interval,
                                                solution.Buffering.Size,
                                                streamRoleId,
                                                encrypted,
                                                streamBackupLoggingConfiguration )]


        [#switch (destinationLink.Core.Type)!"notfound" ]
            [#case ES_COMPONENT_TYPE ]

                [#assign esId = destinationLink.State.Resources["es"].Id ]
                [#assign streamESDestination = getFirehoseStreamESDestination(
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
                    mode=listMode
                    id=streamId
                    name=streamName
                    destination=streamESDestination
                    dependencies=streamDependencies
                /]
                [#break]

            [#default]
                [@cfException
                    mode=listMode
                    description="Invalid stream destination or destination not found"
                    detail="Supported Destinations - ES"
                    context=occurrence
                /]
        [/#switch]
    [/#if]
[/#macro]