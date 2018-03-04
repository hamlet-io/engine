[#-- API Gateway --]

[#if (componentType == "apigateway")]
    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]
        [#assign resources = occurrence.State.Resources ]
        [#assign roles = occurrence.State.Roles]

        [#if ! (buildCommit?has_content)]
            [@cfPreconditionFailed listMode "application_gateway" occurrence "No build commit provided" /]
            [#break]
        [/#if]

        [#assign apiId    = resources["gateway"].Id]
        [#assign apiName  = resources["gateway"].Name]

        [#-- Use runId to ensure deploy happens every time --]
        [#assign deployId = formatAPIGatewayDeployId(
                                tier,
                                component,
                                occurrence,
                                runId)]
        [#assign stageId  = formatAPIGatewayStageId(
                                tier,
                                component,
                                occurrence)]
        [#assign stageName = core.Version.Name]
        [#assign stageDimensions =
            [
                {
                    "Name" : "ApiName",
                    "Value" : apiName
                },
                {
                    "Name" : "Stage",
                    "Value" : stageName
                }
            ]
        ]
        [#assign stageVariables = {} ]
        [#assign userPoolArns = [] ]

        [#list configuration.Links?values as link]
            [#if link?is_hash]
                [#assign linkTarget = getLinkTarget(occurrence, link) ]
                [@cfDebug listMode linkTarget false /]

                [#assign linkTargetCore = linkTarget.Core ]
                [#assign linkTargetConfiguration = linkTarget.Configuration ]
                [#assign linkTargetResources = linkTarget.State.Resources ]
                [#assign linkTargetAttributes = linkTarget.State.Attributes ]

                [#switch linkTargetCore.Type!""]
                    [#case "alb"]
                        [#assign stageVariables +=
                            {
                                formatVariableName(link.Name, "DOCKER") : linkTargetAttributes.FQDN
                            }
                        ]
                        [#break]

                    [#case LAMBDA_FUNCTION_COMPONENT_TYPE]
                        [#assign stageVariables +=
                            {
                                formatVariableName(
                                    link.Name,
                                    linkTargetCore.SubComponent.Name,
                                    "LAMBDA") : linkTargetResources["function"].Name
                            }
                        ]
                        [#break]

                    [#case "userpool"] 
                        [#if deploymentSubsetRequired("apigateway", true)]
        
                            [#assign policyId = formatDependentPolicyId(
                                                    apiId, 
                                                    link.Name)]

                            [@createPolicy 
                                mode=listMode
                                id=policyId
                                name=apiName
                                statements=asFlattenedArray(roles.Outbound["invoke"])
                                roles=formatDependentIdentityPoolAuthRoleId(
                                        formatIdentityPoolId(linkTargetCore.Tier, linkTargetCore.Component))
                            /]
                        [/#if]
                        [#break]
                [/#switch]
            [/#if]
        [/#list]

        [#assign logGroup =
            {
                "Fn::Join" : [
                    "",
                    [
                        "API-Gateway-Execution-Logs_",
                        getReference(apiId),
                        "/",
                        stageName
                    ]                       
                ]
            }
        ]
        [#assign invalidLogMetricId = formatDependentLogMetricId(stageId, "invalid")]
        [#assign invalidLogMetricName = "Invalid"]
        [#assign invalidAlarmId = formatDependentAlarmId(stageId, "invalid")]
        [#assign invalidAlarmName = formatComponentAlarmName(
                                        tier,
                                        component,
                                        occurrence,
                                        "invalid")]
        [#assign domainId  = formatDependentAPIGatewayDomainId(apiId)]
        [#assign basePathMappingId  = formatDependentAPIGatewayBasePathMappingId(stageId)]

        [#assign cfId  = formatDependentCFDistributionId(
                                apiId)]
        [#assign cfName  = formatComponentCFDistributionName(
                                tier,
                                component,
                                occurrence)]
        [#assign cfOriginId = "apigateway" ]
        [#assign wafAclId  = formatDependentWAFAclId(
                                apiId)]
        [#assign wafAclName  = formatComponentWAFAclName(
                                tier,
                                component,
                                occurrence)]
        [#assign usagePlanId  = formatDependentAPIGatewayUsagePlanId(cfId)]
        [#assign usagePlanName = formatComponentUsagePlanName(
                                tier,
                                component,
                                occurrence)]
                        
        [#assign certificateObject = getCertificateObject(configuration.Certificate, segmentId, segmentName) ]
        [#assign hostName = getHostName(certificateObject, tier, component, occurrence) ]
        [#assign dns = formatDomainName(hostName, certificateObject.Domain.Name) ]
        [#assign certificateId = formatDomainCertificateId(certificateObject, hostName) ]

        [#if deploymentSubsetRequired("apigateway", true)]
            [@cfResource
                mode=listMode
                id=apiId
                type="AWS::ApiGateway::RestApi"
                properties= 
                    {
                        "BodyS3Location" : {
                            "Bucket" : getRegistryEndPoint("swagger"),
                            "Key" : formatRelativePath(
                                        getRegistryPrefix("swagger"),
                                        productName,
                                        buildDeploymentUnit,
                                        buildCommit,
                                        "swagger-" +
                                            region +
                                            "-" +
                                            accountObject.AWSId +
                                            ".json")
                        },
                        "Name" : apiName
                    }
                outputs=APIGATEWAY_OUTPUT_MAPPINGS
            /]
            [@cfResource
                mode=listMode
                id=deployId
                type="AWS::ApiGateway::Deployment"
                properties= 
                    {
                        "RestApiId": getReference(apiId),
                        "StageName": "default"
                    }
                outputs={}
                dependencies=apiId                       
            /]
            [@cfResource
                mode=listMode
                id=stageId
                type="AWS::ApiGateway::Stage"
                properties= 
                    {
                        "DeploymentId" : getReference(deployId),
                        "RestApiId" : getReference(apiId),
                        "MethodSettings": [
                            {
                              "HttpMethod": "*",
                              "ResourcePath": "/*",
                              "LoggingLevel": "INFO",
                              "DataTraceEnabled": true
                            }
                        ],
                        "StageName" : stageName                         
                    } +
                    attributeIfContent("Variables", stageVariables)
                outputs={}
                dependencies=deployId                       
            /]
            [@createSegmentCountLogMetric
                    listMode,
                    invalidLogMetricId,
                    invalidLogMetricName,
                    logGroup,
                    "Invalid",
                    [stageId]
            /]
            [@createCountAlarm
                mode=listMode
                id=invalidAlarmId
                name=invalidAlarmName
                actions=[
                    getReference(formatSegmentSNSTopicId())
                ]
                metric=invalidLogMetricName
                namespace=formatSegmentNamespace()
                dimensions=stageDimensions
                dependencies=[invalidLogMetricId]
            /]

    
            [#if configuration.CloudFront.Configured && configuration.CloudFront.Enabled]
                [#assign origin =
                    getCFAPIGatewayOrigin(
                        cfOriginId,
                        apiId,
                        getCFHTTPHeader("x-api-key",credentialsObject.APIGateway.API.AccessKey)
                    )
                ]
                [#assign defaultCacheBehaviour = getCFAPIGatewayCacheBehaviour(origin) ]
                [#assign restrictions = {} ]
                [#if configuration.CloudFront.CountryGroups?has_content]
                    [#list asArray(configuration.CloudFront.CountryGroups) as countryGroup]
                        [#assign group = (countryGroups[countryGroup])!{}]
                        [#if group.Locations?has_content]
                            [#assign restrictions +=
                                getCFGeoRestriction(group.Locations, group.Blacklist!false) ]
                            [#break]
                        [/#if]
                    [/#list]
                [/#if]
                [@createCFDistribution
                    mode=listMode
                    id=cfId
                    dependencies=stageId     
                    aliases=
                        (configuration.Certificate.Configured && configuration.Certificate.Enabled)?then(
                            [dns],
                            []
                        )
                    certificate=valueIfTrue(
                        getCFCertificate(
                            certificateId,
                            configuration.CloudFront.AssumeSNI),
                        configuration.Certificate.Configured && configuration.Certificate.Enabled)
                    comment=cfName
                    defaultCacheBehaviour=defaultCacheBehaviour
                    logging=valueIfTrue(
                        getCFLogging(
                            operationsBucket,
                            formatComponentAbsoluteFullPath(
                                tier,
                                component,
                                occurrence
                            )
                        ),
                        configuration.CloudFront.EnableLogging)
                    origins=origin
                    restrictions=valueIfContent(
                        restrictions,
                        restrictions)
                    wafAclId=valueIfTrue(
                        wafAclId,
                        (configuration.WAF.Configured &&
                            configuration.WAF.Enabled &&
                            ipAddressGroupsUsage["waf"]?has_content))
                /]
                [@cfResource
                    mode=listMode
                    id=usagePlanId
                    type="AWS::ApiGateway::UsagePlan"
                    properties= 
                        {
                            "ApiStages" : [
                                {
                                  "ApiId" : getReference(apiId),
                                  "Stage" : stageName
                                }
                            ],
                            "UsagePlanName" : usagePlanName
                        }
                    outputs={}
                    dependencies=stageId                       
                /]

                [#if configuration.WAF.Configured &&
                        configuration.WAF.Enabled &&
                        ipAddressGroupsUsage["waf"]?has_content ]
                    [#assign wafGroups = [] ]
                    [#assign wafRuleDefault = 
                                configuration.WAF.RuleDefault?has_content?then(
                                    configuration.WAF.RuleDefault,
                                    "ALLOW")]
                    [#assign wafDefault = 
                                configuration.WAF.Default?has_content?then(
                                    configuration.WAF.Default,
                                    "BLOCK")]
                    [#if configuration.WAF.IPAddressGroups?has_content]
                        [#list configuration.WAF.IPAddressGroups as group]
                            [#assign groupId = group?is_hash?then(
                                            group.Id,
                                            group)]
                            [#if (ipAddressGroupsUsage["waf"][groupId])?has_content]
                                [#assign usageGroup = ipAddressGroupsUsage["waf"][groupId]]
                                [#if usageGroup.IsOpen]
                                    [#assign wafRuleDefault = 
                                        configuration.WAF.RuleDefault?has_content?then(
                                            configuration.WAF.RuleDefault,
                                            "COUNT")]
                                    [#assign wafDefault = 
                                            configuration.WAF.Default?has_content?then(
                                                configuration.WAF.Default,
                                                "ALLOW")]
                                [/#if]
                                [#if usageGroup.CIDR?has_content]
                                    [#assign wafGroups += 
                                                group?is_hash?then(
                                                    [group],
                                                    [{"Id" : groupId}]
                                                )]
                                [/#if]
                            [/#if]
                        [/#list]
                    [#else]
                        [#list ipAddressGroupsUsage["waf"]?values as usageGroup]
                            [#if usageGroup.IsOpen]
                                [#assign wafRuleDefault = 
                                    configuration.WAF.RuleDefault?has_content?then(
                                        configuration.WAF.RuleDefault,
                                        "COUNT")]
                                [#assign wafDefault = 
                                        configuration.WAF.Default?has_content?then(
                                            configuration.WAF.Default,
                                            "ALLOW")]
                            [/#if]
                            [#if usageGroup.CIDR?has_content]
                                [#assign wafGroups += [{"Id" : usageGroup.Id}]]
                            [/#if]
                        [/#list]
                    [/#if]
        
                    [#assign wafRules = []]
                    [#list wafGroups as group]
                        [#assign wafRules += [
                                {
                                    "Id" : "${formatWAFIPSetRuleId(group)}",
                                    "Action" : "${(group.Action?upper_case)!wafRuleDefault}"
                                }
                            ]
                        ]
                    [/#list]
                    [@createWAFAcl 
                        mode=listMode
                        id=wafAclId
                        name=wafAclName
                        metric=wafAclName
                        default=wafDefault
                        rules=wafRules /]
                [/#if]
            [#else]
                [#if configuration.Certificate.Configured && configuration.Certificate.Enabled]
                    [@cfResource
                        mode=listMode
                        id=domainId
                        type="AWS::ApiGateway::DomainName"
                        properties= 
                            {
                                "CertificateArn": getExistingReference(certificateId, ARN_ATTRIBUTE_TYPE, "us-east-1"),
                                "DomainName" : dns
                            }
                        outputs={}
                    /]
                    [@cfResource
                        mode=listMode
                        id=basePathMappingId
                        type="AWS::ApiGateway::BasePathMapping"
                        properties= 
                            {
                                "DomainName" : dns,
                                "RestApiId" : getReference(apiId),
                                "Stage" : stageName
                            }
                        outputs={}
                        dependencies=domainId
                    /]
                [/#if]
            [/#if]
        [/#if]
        
        [#if configuration.Publish.Configured && configuration.Publish.Enabled ]
            [#assign docsS3BucketId = formatS3Id(core.Id, "docs")]
            
            [#assign docsS3BucketPolicyId = formatBucketPolicyId(core.Id, "docs") ]

            [#assign docsS3WebsiteConfiguration = getS3WebsiteConfiguration("index.html", "")]
            [#assign docsS3BucketName = (configuration.Certificate.Configured && configuration.Certificate.Enabled)?then(
                                            formatDomainName(
                                                configuration.Publish.DnsNamePrefix,
                                                dns),
                                            formatName(
                                                configuration.Publish.DnsNamePrefix,
                                                formatOccurrenceBucketName(occurrence))
                                            )]    
            
            [#if deploymentSubsetRequired("s3", true) && isPartOfCurrentDeploymentUnit(docsS3BucketId)]
                [#assign docsCIDRList = [] ]

                [#if ipAddressGroupsUsage["publish"]?has_content ]
                    [#list configuration.Publish.IPAddressGroups as group]
                        [#assign groupId = group?is_hash?then(
                                        group.Id,
                                        group)]
                        
                        [#if (ipAddressGroupsUsage["publish"][groupId])?has_content]
                            [#assign docsCIDRList +=  (ipAddressGroupsUsage["publish"][groupId]).CIDR ]
                        [/#if]
                    [/#list]
                [/#if]
                
                [#assign docsS3IPWhitelist = s3IPAccessCondition(docsCIDRList)]                  

                [@createBucketPolicy
                    mode=listMode
                    id=docsS3BucketPolicyId
                    bucket=docsS3BucketName
                    statements=
                        s3ReadPermission(
                            docsS3BucketName,
                            "",
                            "*",
                            "*",
                            docsS3IPWhitelist
                        )
                    dependencies=docsS3BucketId
                /]

                [@createS3Bucket
                    mode=listMode
                    id=docsS3BucketId
                    name=docsS3BucketName
                    websiteConfiguration=docsS3WebsiteConfiguration
                /]
            [/#if]  

            [#if deploymentSubsetRequired("epilogue", false)]
                [@cfScript
                    mode=listMode
                    content=
                    [
                        "function get_apidoc_file() {",
                        "  #",
                        "  # Fetch the apidoc file",
                        "  copyFilesFromBucket" + " " +
                            regionId + " " + 
                            getRegistryEndPoint("swagger") + " " +
                            formatRelativePath(
                                getRegistryPrefix("swagger") + productName,
                                buildDeploymentUnit,
                                buildCommit) + " " +
                        "   \"$\{tmpdir}\" || return $?",
                        "  #",
                        "  # Insert host in Doc File ",
                        "  add_host_to_apidoc" + " " + 
                            dns + " " +
                        "  \"$\{tmpdir}/apidoc.zip\"  || return $?",
                        "  # Sync to the API Doc bucket",
                        "  copy_apidoc_file" + " " + docsS3BucketName + " " +
                        "  \"$\{tmpdir}/apidoc.zip\" || return $?",
                        "}",
                        "#",
                        "get_apidoc_file"
                    ]
                /]
            [/#if]
        [/#if]
        
        [#switch listMode]
            [#case "dashboard"]
                [#if getExistingReference(apiId)?has_content]
                    [#assign widgets =
                        [
                            {
                                "Type" : "metric",
                                "Metrics" : [
                                    {
                                        "Namespace" : "AWS/ApiGateway",
                                        "Metric" : "Latency",
                                        "Dimensions" : stageDimensions,
                                        "Statistic" : "Maximum"
                                    }
                                ],
                                "Width" : 6,
                                "asGraph" : true
                            },
                            {
                                "Type" : "metric",
                                "Metrics" : [
                                    {
                                        "Namespace" : "AWS/ApiGateway",
                                        "Metric" : "Count",
                                        "Dimensions" : stageDimensions
                                    }
                                ]
                            }
                        ]
                    ]
                    [#if getExistingReference(invalidLogMetricId)?has_content]
                        [#assign widgets +=
                            [
                                {
                                    "Type" : "metric",
                                    "Metrics" : [
                                        {
                                            "Namespace" : formatSegmentNamespace(),
                                            "Metric" : invalidLogMetricName,
                                            "Dimensions" : stageDimensions
                                        }
                                    ]
                                }
                            ]
                        ]
                    [/#if]
                    [#assign dashboardRows +=
                        [
                            {
                                "Title" : formatName(occurrence),
                                "Widgets" : widgets
                            }
                        ]
                    ]
                [/#if]
                [#break]
        [/#switch]
    [/#list]
[/#if]
