[#ftl]
[#macro aws_es_cf_solution occurrence ]
    [@cfDebug listMode occurrence false /]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]
    [#local resources = occurrence.State.Resources]
    [#local roles = occurrence.State.Roles]

    [#local esId = resources["es"].Id]
    [#local esName = resources["es"].Name]
    [#local esServiceRoleId = resources["servicerole"].Id]

    [#local processorProfile = getProcessor(occurrence, "ElasticSearch")]
    [#local master = processorProfile.Master!{}]

    [#local esUpdateCommand = "updateESDomain" ]

    [#local esAuthentication = solution.Authentication]

    [#local cognitoIntegration = false ]
    [#local cognitoCliConfig = {} ]

    [#local esPolicyStatements = [] ]

    [#local storageProfile = getStorage(occurrence, "ElasticSearch")]
    [#local volume = (storageProfile.Volumes["codeontap"])!{}]
    [#local esCIDRs = getGroupCIDRs(solution.IPAddressGroups) ]

    [#if !esCIDRs?has_content && !(esAuthentication == "SIG4ORIP") ]
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

    [#local esAdvancedOptions = {} ]
    [#list solution.AdvancedOptions as option]
        [#local esAdvancedOptions +=
            {
                option.Id : option.Value
            }
        ]
    [/#list]

    [#local AccessPolicyStatements = [] ]

    [#local esAccounts = getAWSAccountIds( solution.Accounts )]
    [#local esAccountPrincipals = []]
    [#local esGlobalAccountAccess = false ]

    [#if esAccounts?seq_contains("*") ]
        [#local esGlobalAccountAccess = true ]
        [#local esAccountPrincipals = [ "*" ]]
    [#else]
        [#list esAccounts as esAccount ]
            [#local esAccountPrincipals += [ formatAccountPrincipalArn( esAccount ) ]]
        [/#list]
    [/#if]


    [#if esAuthentication == "SIG4ANDIP" ]

        [#local AccessPolicyStatements += [
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

        [#local AccessPolicyStatements +=
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

    [#if esAuthentication == "SIG4ORIP" && esCIDRs?has_content ]
        [#local AccessPolicyStatements +=
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

    [#if (esAuthentication == "SIG4ANDIP" || esAuthentication == "SIG4ORIP" ) && ! esGlobalAccountAccess]
        [#local AccessPolicyStatements += [
                getPolicyStatement(
                    "es:ESHttp*",
                    "*",
                    {
                        "AWS" : "*"
                    },
                    {},
                    false,
                    {}
                    {
                        "AWS" : esAccountPrincipals
                    }
                )
            ]
        ]
    [/#if]

    [#if esAuthentication == "IP" ]
        [#local AccessPolicyStatements +=
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
            [#local linkTarget = getLinkTarget(occurrence, link) ]

            [@cfDebug listMode linkTarget false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]

            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetConfiguration = linkTarget.Configuration ]
            [#local linkTargetResources = linkTarget.State.Resources ]
            [#local linkTargetAttributes = linkTarget.State.Attributes ]
            [#switch linkTargetCore.Type]

                [#case USERPOOL_COMPONENT_TYPE]
                    [#local cognitoIntegration = true ]

                    [#local cognitoCliConfig =
                        {
                            "CognitoOptions" : {
                                "Enabled" : true,
                                "UserPoolId" : linkTargetAttributes["USER_POOL"],
                                "IdentityPoolId" : linkTargetAttributes["IDENTITY_POOL"],
                                "RoleArn" : getExistingReference(esServiceRoleId, ARN_ATTRIBUTE_TYPE)
                            }
                        }]

                        [#local policyId = formatDependentPolicyId(
                                                esId,
                                                link.Name)]


                        [#if deploymentSubsetRequired("es", true)]
                            [#local role = linkTargetResources["authrole"].Id!linkTargetAttributes["AUTH_USERROLE_ARN"] ]
                            [#local roleArn = getArn(role) ]

                            [#local localRoleAccount = role?contains( ":" + accountObject.AWSId + ":" ) ]

                            [#if localRoleAccount ]
                                [#local roleName = (role?split("/"))[1] ]
                                [@cfResource
                                    mode=listMode
                                    id=policyId
                                    type="AWS::IAM::Policy"
                                    properties=
                                        getPolicyDocument(asFlattenedArray(roles.Outbound["consume"]), esName) +
                                        {
                                            "Roles" : [ roleName ]
                                        }
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

            [#local monitoredResources = getMonitoredResources(resources, alert.Resource)]
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
                ) +
                attributeIfContent(
                    "AccessPolicies",
                    AccessPolicyStatements,
                    getPolicyDocumentContent(AccessPolicyStatements)
                )
            tags=getOccurrenceCoreTags(occurrence, "")
            outputs=ES_OUTPUT_MAPPINGS
        /]
    [/#if]

    [#if deploymentSubsetRequired("cli", false)]

        [#local esCliConfig =
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
[/#macro]