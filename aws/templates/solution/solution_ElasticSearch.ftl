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

        [#assign processorProfile = getProcessor(occurrence, "ElasticSearch")]
        [#assign master = processorProfile.Master!{}]

        [#assign esUpdateCommand = "updateESDomain" ]

        [#assign esAuthentication = solution.Authentication]

        [#assign cognitoIntegration = false ]
        [#assign cognitoCliConfig = {} ]

        [#assign esPolicyStatements = [] ]

        [#assign storageProfile = getStorage(occurrence, "ElasticSearch")]
        [#assign volume = (storageProfile.Volumes["codeontap"])!{}]
        [#assign esCIDRs = getGroupCIDRs(solution.IPAddressGroups) ]

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

        [#assign esAdvancedOptions = {} ]
        [#list solution.AdvancedOptions as option]
            [#assign esAdvancedOptions +=
                {
                    option.Id : option.Value
                }
            ]
        [/#list]

        [#assign AccessPolicyStatements = [] ]

        [#assign esAccounts = getAWSAccountIds( solution.Accounts )]
        [#assign esAccountPrincipals = []]
        [#assign esGlobalAccountAccess = false ]

        [#if esAccounts?seq_contains("*") ]
            [#assign esGlobalAccountAccess = true ]
            [#assign esAccountPrincipals = [ "*" ]]
        [#else]
            [#list esAccounts as esAccount ]
                [#assign esAccountPrincipals += [ formatAccountPrincipalArn( esAccount ) ]]
            [/#list]
        [/#if]


        [#if esAuthentication == "SIG4ANDIP" ]

            [#assign AccessPolicyStatements += [
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

        [#if esAuthentication == "SIG4ORIP" && esCIDRs?has_content ]
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

        [#if (esAuthentication == "SIG4ANDIP" || esAuthentication == "SIG4ORIP" ) && ! esGlobalAccountAccess]
            [#assign AccessPolicyStatements += [
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
                            "KmsKeyId" : getReference(getBaselineKeyId("cmk"), ARN_ATTRIBUTE_TYPE)
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
    [/#list]
[/#if]