[#-- ElasticSearch --]

[#if (componentType == ES_COMPONENT_TYPE || componentType == "elasticsearch" || componentType == "es") ]

    [#list requiredOccurrences(
        getOccurrences(tier, component),
        deploymentUnit) as occurrence]
        
        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign solution = occurrence.Configuration.Solution]
        [#assign resources = occurrence.State.Resources]

        [#assign esId = resources["es"].Id]
        [#assign esServiceRoleId = resources["servicerole"].Id]

        [#assign processorProfile = getProcessor(tier, component, "ElasticSearch")]
        [#assign master = processorProfile.Master!{}]

        [#assign cognitoIntegration = false ]
        [#assign cognitoIntegrationCommand = "setCognitoAuth" ]

        [#assign esPolicyStatements = [] ]

        [#assign storageProfile = getStorage(tier, component, "ElasticSearch")]
        [#assign volume = (storageProfile.Volumes["codeontap"])!{}]
        [#assign esCIDRs = getGroupCIDRs(solution.IPAddressGroups) ]
        [#list zones as zone]
            [#assign zoneIP =
                getExistingReference(
                    formatComponentEIPId("mgmt", "nat", zone),
                    IP_ADDRESS_ATTRIBUTE_TYPE
                )
            ]
            [#if zoneIP?has_content]
                [#assign esCIDRs += [zoneIP] ]
            [/#if]
        [/#list]
        [#list 1..20 as i]
            [#assign externalIP =
                getExistingReference(
                    formatComponentEIPId("mgmt", "nat", "external" + i)
                )
            ]
            [#if externalIP?has_content]
                [#assign esCIDRs += [externalIP] ]
            [/#if]
        [/#list]

        [#assign esAdvancedOptions = {} ]
        [#list solution.AdvancedOptions as option]
            [#assign esAdvancedOptions +=
                {
                    option.Id : option.Value
                }
            ]
        [/#list]

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
                        [#assign authRoleArn = getExistingReference( linkTargetResources["authrole"].Id, ARN_ATTRIBUTE_TYPE )]

                        [#if deploymentSubsetRequired("es", true)]

                            [#assign esPolicyStatements += [
                                getPolicyStatement(
                                    "es:ESHttp*",
                                    getReference(esId, ARN_ATTRIBUTE_TYPE),
                                    {
                                        "AWS": formatRelativePath(
                                                authRoleArn,
                                                "CognitoIdentityCredentials"
                                            )
                                    },
                                    attributeIfContent(
                                        "IpAddress",
                                        esCIDRs,
                                        {
                                            "aws:SourceIp": esCIDRs
                                        })
                                )] ]
                            
                        [/#if]

                        [#if deploymentSubsetRequired("cli", false)]

                            [#assign esCognitoConfig = 
                                {
                                    "CognitoOptions" : {
                                        "Enabled" : true,
                                        "UserPoolId" : linkTargetAttributes.USER_POOL,
                                        "IdentityPoolId" : linkTargetAttributes.IDENTITY_POOL,
                                        "RoleArn" : getExistingReference(esServiceRoleId)
                                    }
                                }]

                            [@cfCli 
                                mode=listMode
                                id=esId
                                command=cognitoIntegrationCommand
                                content=esCognitoConfig
                            /]
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
                    managedArns=["arn:aws:iam::aws:policy/service-role/AmazonESCognitoAccess"]
                /]

            [/#if]
        [/#if]

        [#-- In order to permit updates to the security policy, don't name the domain. --]
        [#-- Use tags in the console to find the right one --]
        [#-- "DomainName" : "${productName}-${segmentId}-${tierId}-${componentId}", --]
        [#if deploymentSubsetRequired("es", true)]

            [@cfResource
                mode=listMode
                id=esId
                type="AWS::Elasticsearch::Domain"
                properties=
                    {
                        "AccessPolicies" : valueIfContent(
                            esPolicyStatements,
                            esPolicyStatements,
                            getPolicyDocumentContent(
                                getPolicyStatement(
                                    "es:*",
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
                            )
                        ),
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
                        attributeIfContent("Iops", volume.Iops!""))
                tags=
                    getCfTemplateCoreTags(
                        "",
                        tier,
                        component)
                outputs=ES_OUTPUT_MAPPINGS
            /]
        [/#if]

        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript
                mode=listMode
                content=
                [#-- Some Userpool Lambda triggers are not available via Cloudformation but are available via CLI --]
                (cognitoIntegration)?then(
                    [
                        "# Enable Cognito Integation for Kibana",
                        "info \"Enabling Cognito Integation for Kibana\""
                        "# Get cli config file",
                        "split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?", 
                        "enable_cognito_kibana" +
                        " \"" + region + "\" " + 
                        " \"" + getExistingReference(esId) + "\" " + 
                        " \"$\{tmpdir}/cli-" + 
                        esId + "-" + cognitoIntegrationCommand + ".json\" || return $?"
                    ],
                    [
                        "# Disable Cognito Integration for Kibana",
                        "info \"Making sure Cognito Integration is disabled\"",
                        "disable_cognito_kibana" +
                        " \"" + region + "\" " + 
                        " \"" + getExistingReference(esId) + "\" || return $?"
                    ]
                ) 
            /]
        [/#if]

    [/#list]
[/#if]