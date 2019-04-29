[#-- ElasticSearch --]

[#if (componentType == ES_COMPONENT_TYPE || componentType == "elasticsearch" || componentType == "es") ]

    [#list requiredOccurrences(
        getOccurrences(tier, component),
        deploymentUnit) as occurrence]
        
        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign solution = occurrence.Configuration.Solution]
        [#assign resources = occurrence.State.Resources]
        [#assign roles = occurrence.State.Roles]

        [#assign esId = resources["es"].Id]
        [#assign esName = resources["es"].Name]
        [#assign esServiceRoleId = resources["servicerole"].Id]

        [#assign processorProfile = getProcessor(tier, component, "ElasticSearch")]
        [#assign master = processorProfile.Master!{}]

        [#assign esUpdateCommand = "updateESDomain" ]

        [#assign esAuthentication = solution.Authentication]

        [#assign cognitoIntegration = false ]
        [#assign cognitoCliConfig = {} ]

        [#assign esPolicyStatements = [] ]

        [#assign storageProfile = getStorage(tier, component, "ElasticSearch")]
        [#assign volume = (storageProfile.Volumes["codeontap"])!{}]
        [#assign esCIDRs = getGroupCIDRs(solution.IPAddressGroups) ]

        [#if !esCIDRs?has_content ]
            [@cfException
                mode=listMode
                description="No IP Policy Found"
                context=component
                detail="You must provide an IPAddressGroups list, for access from anywhere use the global IP Address Group"
            /]
        [/#if]

        [#if esCIDRs?seq_contains("0.0.0.0/0") && esAuthentication == "SIG4ORIP" ]
            [@cfException
                mode=listMode
                description="Invalid Authentication Config"
                context=component
                detail="Using a global IP Address with SIG4ORIP will remove SIG4 Auth. If this is intented change to IP authentication"
            /]
        [/#if]

        [#assign esAdvancedOptions = {} ]
        [#list solution.AdvancedOptions as option]
            [#assign esAdvancedOptions +=
                {
                    option.Id : option.Value
                }
            ]
        [/#list]

        [#assign AccessPolicyStatements = [] ]

        [#if esAuthentication == "SIG4ANDIP" ]

            [#assign AccessPolicyStatements +=
                [
                    getPolicyStatement(
                        "es:ESHttp*",
                        "*",
                        {
                            "AWS" : "*"
                        },
                        {
                            "Null" : { 
                                "aws:principaltype" : true
                            }
                        }, 
                        false
                    )
                ]
             ]
        [/#if]

        [#if ( esAuthentication == "SIG4ANDIP" || esAuthentication == "IP" ) && !esCIDRs?seq_contains("0.0.0.0/0") ]

            [#assign AccessPolicyStatements +=
                [
                    getPolicyStatement(
                        "es:ESHttp*",
                        "*",
                        {
                            "AWS" : "*"
                        },
                        {
                            "NotIpAddress" : { 
                                "aws:SourceIp": esCIDRs
                            }
                        }, 
                        false
                    )
                ]
             ]
        [/#if]

        [#if ( esAuthentication == "IP" || esAuthentication == "SIG4ORIP" )  ]
            [#assign AccessPolicyStatements += 
                [
                    getPolicyStatement(
                        "es:ESHttp*",
                        "*",
                        {
                            "AWS": "*"
                        },
                        attributeIfContent(
                            "IpAddress",
                            esCIDRs,
                            {
                                "aws:SourceIp": esCIDRs
                            })
                    )
                ]
            ]

        [/#if]

        [#list solution.Links?values as link]
            [#if link?is_hash]
                [#assign linkTarget = getLinkTarget(occurrence, link) ]

                [@cfDebug listMode linkTarget false /]

                [#if !linkTarget?has_content]
                    [#continue]
                [/#if]

                [#assign linkTargetCore = linkTarget.Core ]
                [#assign linkTargetConfiguration = linkTarget.Configuration ]
                [#assign linkTargetResources = linkTarget.State.Resources ]
                [#assign linkTargetAttributes = linkTarget.State.Attributes ]
                [#switch linkTargetCore.Type]

                    [#case USERPOOL_COMPONENT_TYPE]
                        [#assign cognitoIntegration = true ]

                        [#assign cognitoCliConfig = 
                            {
                                "CognitoOptions" : {
                                    "Enabled" : true,
                                    "UserPoolId" : linkTargetAttributes.USER_POOL,
                                    "IdentityPoolId" : linkTargetAttributes.IDENTITY_POOL,
                                    "RoleArn" : getExistingReference(esServiceRoleId, ARN_ATTRIBUTE_TYPE)
                                }
                            }]
                        
                            [#assign policyId = formatDependentPolicyId(
                                                    esId,
                                                    link.Name)]

                            
                            [#if deploymentSubsetRequired("es", true)]
                                [#if linkTargetCore.External!false ]
                                    [@cfResource
                                        mode=listMode
                                        id=policyId
                                        type="AWS::IAM::Policy"
                                        properties=
                                            getPolicyDocument(asFlattenedArray(roles.Outbound["consume"]), esName) +
                                            {
                                                "Roles" : [ linkTargetAttributes.USERPOOL_USERROLE_ARN ]
                                            }
                                    /]
                                [#else] 
                                    [@createPolicy
                                        mode=listMode
                                        id=policyId
                                        name=esName
                                        statements=asFlattenedArray(roles.Outbound["consume"])
                                        roles=linkTargetResources["authrole"].Id
                                    /]
                                [/#if]
                            [/#if]
                        [#break]
                [/#switch]
            [/#if]
        [/#list]

        [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(esServiceRoleId)]
            [#if cognitoIntegration ]

                [@createRole
                    mode=listMode
                    id=esServiceRoleId
                    trustedServices=["es.amazonaws.com"]
                    managedArns=["arn:aws:iam::aws:policy/AmazonESCognitoAccess"]
                /]

            [/#if]
        [/#if]

        [#-- In order to permit updates to the security policy, don't name the domain. --]
        [#-- Use tags in the console to find the right one --]
        [#-- "DomainName" : "${productName}-${segmentId}-${tierId}-${componentId}", --]
        [#if deploymentSubsetRequired("es", true)]

            [#list solution.Alerts?values as alert ]

                [#assign monitoredResources = getMonitoredResources(resources, alert.Resource)]
                [#list monitoredResources as name,monitoredResource ]

                    [@cfDebug listMode monitoredResource false /]

                    [#switch alert.Comparison ]
                        [#case "Threshold" ]
                            [@createCountAlarm
                                mode=listMode
                                id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                                severity=alert.Severity
                                resourceName=core.FullName
                                alertName=alert.Name
                                actions=[
                                    getReference(formatSegmentSNSTopicId())
                                ]
                                metric=getMetricName(alert.Metric, monitoredResource.Type, core.ShortFullName)
                                namespace=getResourceMetricNamespace(monitoredResource.Type)
                                description=alert.Description!alert.Name
                                threshold=alert.Threshold
                                statistic=alert.Statistic
                                evaluationPeriods=alert.Periods
                                period=alert.Time
                                operator=alert.Operator
                                reportOK=alert.ReportOk
                                missingData=alert.MissingData
                                dimensions=getResourceMetricDimensions(monitoredResource, resources)
                                dependencies=monitoredResource.Id
                            /]
                        [#break]
                    [/#switch]
                [/#list]
            [/#list]

            [@cfResource
                mode=listMode
                id=esId
                type="AWS::Elasticsearch::Domain"
                properties=
                    {
                        "AccessPolicies" : getPolicyDocumentContent(AccessPolicyStatements),
                        "ElasticsearchVersion" : solution.Version,
                        "ElasticsearchClusterConfig" :
                            {
                                "InstanceType" : processorProfile.Processor,
                                "ZoneAwarenessEnabled" : multiAZ,
                                "InstanceCount" :
                                    multiAZ?then(
                                        processorProfile.CountPerZone * zones?size,
                                        processorProfile.CountPerZone
                                    )
                            } +
                            master?has_content?then(
                                {
                                    "DedicatedMasterEnabled" : true,
                                    "DedicatedMasterCount" : master.Count,
                                    "DedicatedMasterType" : master.Processor
                                },
                                {
                                    "DedicatedMasterEnabled" : false
                                }
                            )
                    } + 
                    attributeIfContent("AdvancedOptions", esAdvancedOptions) +
                    attributeIfContent("SnapshotOptions", solution.Snapshot.Hour, solution.Snapshot.Hour) +
                    attributeIfContent(
                        "EBSOptions",
                        volume,
                        {
                            "EBSEnabled" : true,
                            "VolumeSize" : volume.Size,
                            "VolumeType" :
                                volume.Type?has_content?then(
                                    volume.Type,
                                    "gp2"
                                )
                        } +
                        attributeIfContent("Iops", volume.Iops!"")) +
                    attributeIfTrue(
                        "EncryptionAtRestOptions",
                        solution.Encrypted,
                        {
                            "Enabled" : true,
                            "KmsKeyId" : getReference(formatSegmentCMKId(), ARN_ATTRIBUTE_TYPE)
                        }
                    )
                tags=
                    getCfTemplateCoreTags(
                        "",
                        tier,
                        component)
                outputs=ES_OUTPUT_MAPPINGS
            /]
        [/#if]

        [#if deploymentSubsetRequired("cli", false)]

            [#assign esCliConfig = 
                valueIfContent(
                    cognitoCliConfig,
                    cognitoCliConfig,
                    {
                        "CognitoOptions" : {
                            "Enabled" : false
                        }
                    }       
                )]

            [@cfCli 
                mode=listMode
                id=esId
                command=esUpdateCommand
                content=esCliConfig
            /]

        [/#if]

        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript
                mode=listMode
                content= (getExistingReference(esId)?has_content)?then(
                        [
                            "case $\{STACK_OPERATION} in",
                            "  create|update)",
                            "       # Get cli config file",
                            "       split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?", 
                            "       # Apply CLI level updates to ES Domain",
                            "       info \"Applying cli level configurtion\""
                            "       update_es_domain" +
                            "       \"" + region + "\" " + 
                            "       \"" + getExistingReference(esId) + "\" " + 
                            "       \"$\{tmpdir}/cli-" + 
                            esId + "-" + esUpdateCommand + ".json\" || return $?"
                            "   ;;",
                            "   esac"
                        ],
                        [
                            "warning \"Please run another update to complete the configuration\""
                        ]
                    )
            /]
        [/#if]

        [#list occurrence.Occurrences![] as subOccurrence]

            [#assign subCore = subOccurrence.Core ]
            [#assign subSolution = subOccurrence.Configuration.Solution ]
            [#assign subResources = subOccurrence.State.Resources ]

            [#switch subCore.Type ]
                [#case ES_DATAFEED_COMPONENT_TYPE ]

                    [#assign streamId = subResources["stream"].Id ]
                    [#assign streamName = subResources["stream"].Name ]
                    
                    [#assign streamRoleId = subResources["role"].Id ]

                    [#assign streamSubscriptionRoleId = subResources["subscriptionRole"].Id!"" ]
                    
                    [#assign streamLgId = (subResources["lg"].Id)!"" ]
                    [#assign streamLgName = (subResources["lg"].Name)!"" ]
                    [#assign streamLgStreamId = (subResources["streamlgstream"].Id)!""]
                    [#assign streamLgStreamName = (subResources["streamlgstream"].Name)!""]
                    [#assign streamLgBackupId = (subResources["backuplgstream"].Id)!""]
                    [#assign streamLgBackupName = (subResources["backuplgstream"].Name)!""]

                    [#assign logging = subSolution.Logging ]
                    [#assign encrypted = subSolution.Encrypted]

                    [#assign dataBucketPrefix = getAppDataFilePrefix(subOccurrence) ]

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

                    [#list subSolution.LogWatchers as logWatcherName,logwatcher ]

                        [#assign logFilter = (logFilters[logwatcher.LogFilter].Pattern)!"" ]

                        [#assign logSubscriptionRoleRequired = true ]

                        [#list logwatcher.Links as logWatcherLinkName,logWatcherLink ]
                            [#assign logWatcherLinkTarget = getLinkTarget(subOccurrence, logWatcherLink) ]

                            [#if !logWatcherLinkTarget?has_content]
                                [#continue]
                            [/#if]

                            [#assign roleSource = logWatcherLinkTarget.State.Roles.Inbound["logwatch"]]

                            [#list asArray(roleSource.LogGroupIds) as logGroupId ]

                                [#assign logGroupArn = getExistingReference(logGroupId, ARN_ATTRIBUTE_TYPE)]

                                [#if logGroupArn?has_content ]

                                    [#if deploymentSubsetRequired(ES_COMPONENT_TYPE, true)]
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

                    [#assign links = getLinkTargets(subOccurrence) ]

                    [#if deploymentSubsetRequired("iam", true)]
                            
                        [#if isPartOfCurrentDeploymentUnit(streamRoleId)]

                            [#assign linkPolicies = getLinkTargetsOutboundRoles(links) ]
                        
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
                                            s3AllPermission(dataBucket, dataBucketPrefix) +
                                            esKinesesStreamPermission(esId),
                                            "standard"
                                        )
                                    ] +
                                    arrayIfContent(
                                        [getPolicyDocument(linkPolicies, "links")],
                                        linkPolicies)
                            /]
                        [/#if]

                        [#if subSolution.LogWatchers?has_content &&
                              isPartOfCurrentDeploymentUnit(streamSubscriptionRoleId)]

                            [@createRole
                                mode=listMode
                                id=streamSubscriptionRoleId
                                trustedServices=[ formatDomainName("logs", regionId, "amazonaws.com") ]
                            /]

                            [#assign policyId = formatDependentPolicyId(streamSubscriptionRoleId, "logSubscription")]
                            [@createPolicy
                                mode=listMode
                                id=policyId
                                name="logSubscription"
                                statements=firehoseStreamProducePermission(streamId)  +
                                            iamPassRolePermission(
                                                getReference(streamSubscriptionRoleId, ARN_ATTRIBUTE_TYPE)
                                            )
                                roles=streamSubscriptionRoleId
                            /]
                        [/#if]
                    [/#if]

                    [#if deploymentSubsetRequired(ES_COMPONENT_TYPE, true)]

                        [#assign streamLoggingConfiguration = getFirehoseStreamLoggingConfiguration( 
                                                                logging
                                                                streamLgName
                                                                streamLgStreamName )]
                        [#assign streamBackupLoggingConfiguration = getFirehoseStreamLoggingConfiguration(
                                                                logging,
                                                                streamLgName,
                                                                streamLgBackupName )]

                        [#assign streamS3BackupDestination = getFirehoseStreamS3Destination(
                                                                formatS3DataId(),
                                                                dataBucketPrefix,
                                                                subSolution.Buffering.Interval,
                                                                subSolution.Buffering.Size,
                                                                streamRoleId,
                                                                encrypted,
                                                                streamBackupLoggingConfiguration )]
                        
                        [#assign streamESDestination = getFirehoseStreamESDestination(
                                                                subSolution.Buffering.Interval,
                                                                subSolution.Buffering.Size,
                                                                esId,
                                                                streamRoleId,
                                                                subSolution.IndexPrefix,
                                                                subSolution.IndexRotation,
                                                                subSolution.DocumentType,
                                                                subSolution.Backup.FailureDuration,
                                                                subSolution.Backup.Policy,
                                                                streamS3BackupDestination,
                                                                streamLoggingConfiguration)]

                        [@createFirehoseStream 
                            mode=listMode 
                            id=streamId 
                            name=streamName 
                            destination=streamESDestination 
                        /]
                    [/#if]
                [#break]
            [/#switch]
        [/#list]
    [/#list]
[/#if]