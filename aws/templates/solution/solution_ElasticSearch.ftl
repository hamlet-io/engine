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

        [#assign AccessPolicy = 
            getPolicyDocumentContent(
                [
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
                            }) + 
                        attributeIfTrue(
                            "Null",
                            esAuthentication == "SIG4",
                            {
                                "aws:principaltype" : false
                            }
                        )
                    ),
                    getPolicyStatement(
                        "es:*",
                        "*",
                        {
                            "AWS" : "*"
                        },
                        attributeIfContent(
                            "NotIpAddress",
                            esCIDRs,
                            {
                                "aws:SourceIp": esCIDRs
                            }), 
                        false
                    )
                ]
            )]

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
                                [@createPolicy
                                    mode=listMode
                                    id=policyId
                                    name=esName
                                    statements=asFlattenedArray(roles.Outbound["consume"])
                                    roles=linkTargetResources["authrole"].Id
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
                    managedArns=["arn:aws:iam::aws:policy/AmazonESCognitoAccess"]
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
                        "AccessPolicies" : AccessPolicy,
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
                content=
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
                    ]  
            /]
        [/#if]

    [/#list]
[/#if]