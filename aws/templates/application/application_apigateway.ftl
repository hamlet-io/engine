[#-- API Gateway --]

[#if (componentType == "apigateway")]
    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]
        [#assign attributes = occurrence.State.Attributes ]
        [#assign roles = occurrence.State.Roles]

        [#if ! (buildCommit?has_content)]
            [@cfPreconditionFailed listMode "application_gateway" occurrence "No build commit provided" /]
            [#break]
        [/#if]

        [#assign apiId      = resources["apigateway"].Id]
        [#assign apiName    = resources["apigateway"].Name]

        [#-- Use runId to ensure deploy happens every time --]
        [#assign deployId   = resources["apideploy"].Id]
        [#assign stageId    = resources["apistage"].Id]
        [#assign stageName  = resources["apistage"].Name]
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

                    [#case USERPOOL_COMPONENT_TYPE]
                        [#if deploymentSubsetRequired("apigateway", true)]

                            [#assign policyId = formatDependentPolicyId(
                                                    apiId,
                                                    link.Name)]

                            [@createPolicy
                                mode=listMode
                                id=policyId
                                name=apiName
                                statements=asFlattenedArray(roles.Outbound["invoke"])
                                roles=linkTargetResources["authrole"].Id
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

        [#assign certificatePresent     = configuration.Certificate.Configured && configuration.Certificate.Enabled ]

        [#assign mappingPresent         = configuration.Mapping.Configured && configuration.Mapping.Enabled ]
        [#assign domainId               = resources["apidomain"].Id]
        [#assign domainFqdn             = resources["apidomain"].Fqdn]
        [#assign domainCertificateId    = resources["apidomain"].CertificateId]
        [#assign basePathMappingId      = resources["apibasepathmapping"].Id]
        [#assign basePathMappingStage   = resources["apibasepathmapping"].Stage]

        [#assign invalidLogMetricId     = resources["invalidlogmetric"].Id]
        [#assign invalidLogMetricName   = resources["invalidlogmetric"].Name]
        [#assign invalidAlarmId         = resources["invalidalarm"].Id]
        [#assign invalidAlarmName       = resources["invalidalarm"].Name]

        [#assign cfPresent              = configuration.CloudFront.Configured && configuration.CloudFront.Enabled ]
        [#assign mappingPresent         = mappingPresent && (!cfPresent || configuration.CloudFront.Mapping) ]
        [#assign cfId                   = resources["cf"].Id]
        [#assign cfName                 = resources["cf"].Name]
        [#assign cfCertificateId        = resources["cf"].CertificateId]
        [#assign cfFqdn                 = resources["cf"].Fqdn]
        [#assign cfOriginId             = resources["cforigin"].Id]
        [#assign cfOriginFqdn           = resources["cforigin"].Fqdn]

        [#assign wafPresent             = configuration.WAF.Configured && configuration.WAF.Enabled ]
        [#assign wafAclId               = resources["wafacl"].Id]
        [#assign wafAclName             = resources["wafacl"].Name]

        [#assign usagePlanId            = resources["apiusageplan"].Id]
        [#assign usagePlanName          = resources["apiusageplan"].Name]

        [#assign publishPresent         = configuration.Publish.Configured && configuration.Publish.Enabled ]
        [#assign docsS3BucketId         = resources["docs"].Id]
        [#assign docsS3BucketName       = resources["docs"].Name]
        [#assign docsS3BucketPolicyId   = resources["docspolicy"].Id ]

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

            [#if cfPresent]
                [#assign origin =
                    getCFHTTPOrigin(
                        cfOriginId,
                        cfOriginFqdn,
                        getCFHTTPHeader("x-api-key",credentialsObject.APIGateway.API.AccessKey)
                    )
                ]
                [#assign defaultCacheBehaviour = getCFAPIGatewayCacheBehaviour(origin) ]
                [#assign restrictions = {} ]
                [#if solution.CloudFront.CountryGroups?has_content]
                    [#list asArray(solution.CloudFront.CountryGroups) as countryGroup]
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
                    aliases=valueIfTrue([cfFqdn], certificatePresent, [])
                    certificate=valueIfTrue(
                        getCFCertificate(
                            cfCertificateId,
                            configuration.CloudFront.AssumeSNI),
                        certificatePresent)
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
                        solution.CloudFront.EnableLogging)
                    origins=origin
                    restrictions=valueIfContent(
                        restrictions,
                        restrictions)
                    wafAclId=valueIfTrue(
                        wafAclId,
                        (solution.WAF.Configured &&
                            solution.WAF.Enabled &&
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

                [#if wafPresent && ipAddressGroupsUsage["waf"]?has_content ]
                    [#assign wafGroups = [] ]
                    [#assign wafRuleDefault = 
                                solution.WAF.RuleDefault?has_content?then(
                                    solution.WAF.RuleDefault,
                                    "ALLOW")]
                    [#assign wafDefault = 
                                solution.WAF.Default?has_content?then(
                                    solution.WAF.Default,
                                    "BLOCK")]
                    [#if solution.WAF.IPAddressGroups?has_content]
                        [#list solution.WAF.IPAddressGroups as group]
                            [#assign groupId = group?is_hash?then(
                                            group.Id,
                                            group)]
                            [#if (ipAddressGroupsUsage["waf"][groupId])?has_content]
                                [#assign usageGroup = ipAddressGroupsUsage["waf"][groupId]]
                                [#if usageGroup.IsOpen]
                                    [#assign wafRuleDefault = 
                                        solution.WAF.RuleDefault?has_content?then(
                                            solution.WAF.RuleDefault,
                                            "COUNT")]
                                    [#assign wafDefault = 
                                            solution.WAF.Default?has_content?then(
                                                solution.WAF.Default,
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
                                    solution.WAF.RuleDefault?has_content?then(
                                        solution.WAF.RuleDefault,
                                        "COUNT")]
                                [#assign wafDefault = 
                                        solution.WAF.Default?has_content?then(
                                            solution.WAF.Default,
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
            [/#if]

            [#if certificatePresent && mappingPresent]
                [@cfResource
                    mode=listMode
                    id=domainId
                    type="AWS::ApiGateway::DomainName"
                    properties=
                        {
                            "CertificateArn": getExistingReference(domainCertificateId, ARN_ATTRIBUTE_TYPE, "us-east-1"),
                            "DomainName" : domainFqdn
                        }
                    outputs={}
                /]
                [@cfResource
                    mode=listMode
                    id=basePathMappingId
                    type="AWS::ApiGateway::BasePathMapping"
                    properties=
                        {
                            "DomainName" : domainFqdn,
                            "RestApiId" : getReference(apiId)
                        } +
                        attributeIfContent("Stage", basePathMappingStage)
                    outputs={}
                    dependencies=domainId
                /]
            [/#if]
        [/#if]

        [#if solution.Publish.Configured && solution.Publish.Enabled ]
            [#assign docsS3BucketId = resources["docs"].Id]
            [#assign docsS3BucketPolicyId = resources["docspolicy"].Id ]

        [#if publishPresent ]
            [#assign docsS3WebsiteConfiguration = getS3WebsiteConfiguration("index.html", "")]

            [#if deploymentSubsetRequired("s3", true) && isPartOfCurrentDeploymentUnit(docsS3BucketId)]
                [#assign docsS3IPWhitelist =
                    s3IPAccessCondition(
                        getUsageCIDRs(
                            "publish",
                            configuration.Publish.IPAddressGroups)) ]

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
                            attributes.FQDN + " " +
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
