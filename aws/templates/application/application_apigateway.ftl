[#-- API Gateway --]

[#if (componentType == "apigateway")]
    [#assign apigateway = component.APIGateway]
                                     
    [#-- Non-repeating text to ensure deploy happens every time --]
    [#assign noise = random.nextLong()?string.computer?replace("-","X")]

    [#list getOccurrences(component, deploymentUnit) as occurrence]

        [#assign apiId    = formatAPIGatewayId(
                                tier,
                                component,
                                occurrence)]
        [#assign apiName  = formatComponentFullName(
                                tier,
                                component,
                                occurrence)]
        [#assign deployId = formatAPIGatewayDeployId(
                                tier,
                                component,
                                occurrence,
                                noise)]
        [#assign stageId  = formatAPIGatewayStageId(
                                tier,
                                component,
                                occurrence)]
        [#assign stageName = occurrence.VersionName]
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
        [#list occurrence.Links?values as link]
            [#if link?is_hash]
                [#assign targetComponent = getComponent(link.Tier, link.Component)]
                [#if targetComponent?has_content]
                    [#list getOccurrences(targetComponent) as targetOccurrence]
                        [#if (targetOccurrence.InstanceId == occurrence.InstanceId) &&
                                (targetOccurrence.VersionId == occurrence.VersionId)]
                            [#switch getComponentType(targetComponent)]
                                [#case "alb"]
                                    [#assign stageVariables +=
                                        {
                                            link.Name?upper_case + "_DOCKER" :
                                            getExistingReference(
                                                formatALBId(
                                                    link.Tier,
                                                    link.Component,
                                                    targetOccurrence),
                                                DNS_ATTRIBUTE_TYPE)
                                        }
                                    ]
                                    [#break]

                                [#case "lambda"]
                                    [#list targetOccurrence.Functions?values as fn]
                                        [#if fn?is_hash]
                                            [#assign fnName =
                                                formatLambdaFunctionName(
                                                    getTier(link.Tier),
                                                    targetComponent,
                                                    targetOccurrence,
                                                    fn)]
                                            [#assign stageVariables +=
                                                {
                                                    link.Name?upper_case + "_" + fn.Name?upper_case + "_LAMBDA" : fnName
                                                }
                                            ]
                                            [@cfResource
                                                mode=applicationListMode
                                                id=
                                                    formatAPIGatewayLambdaPermissionId(
                                                        tier,
                                                        component,
                                                        link,
                                                        fn,
                                                        occurrence)
                                                type="AWS::Lambda::Permission"
                                                properties=
                                                    {
                                                        "Action" : "lambda:InvokeFunction",
                                                        "FunctionName" : fnName,
                                                        "Principal" : "apigateway.amazonaws.com",
                                                        "SourceArn" : formatInvokeApiGatewayArn(apiId, stageName)
                                                    }
                                                outputs={}
                                                dependencies=stageId
                                            /]
                                        [/#if]
                                    [/#list]
                                    [#break]
                            [/#switch]
                            [#break] 
                        [/#if]
                    [/#list]
                [/#if]
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
        [#assign dns = formatDomainName(
                            formatName(
                                occurrence.DNS.Host,
                                occurrence.InstanceName,
                                segmentDomainQualifier),
                            segmentDomain) ]

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

        [#if deploymentSubsetRequired("apigateway", true)]
            [@cfResource
                mode=applicationListMode
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
                mode=applicationListMode
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
                mode=applicationListMode
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
                    applicationListMode,
                    invalidLogMetricId,
                    invalidLogMetricName,
                    logGroup,
                    "Invalid",
                    [stageId]
            /]
            [@createCountAlarm
                mode=applicationListMode
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
                    
            [#if occurrence.CloudFrontIsConfigured]
                [#assign origin =
                    getCFAPIGatewayOrigin(
                        cfOriginId,
                        apiId,
                        getCFHTTPHeader("x-api-key",credentialsObject.APIGateway.API.AccessKey)
                    )
                ]
                [#assign defaultCacheBehaviour = getCFAPIGatewayCacheBehaviour(origin) ]
                [#assign restrictions = {} ]
                [#if occurrence.CloudFront.CountryGroups?has_content]
                    [#list asArray(occurrence.CloudFront.CountryGroups) as countryGroup]
                        [#assign group = (countryGroups[countryGroup])!{}]
                        [#if group.Locations?has_content]
                            [#assign restrictions +=
                                getCFGeoRestriction(group.Locations, group.Blacklist!false) ]
                            [#break]
                        [/#if]
                    [/#list]
                [/#if]
                [@createCFDistribution
                    mode=applicationListMode
                    id=cfId
                    dependencies=stageId     
                    aliases=
                        occurrence.DNSIsConfigured?then(
                            [dns],
                            []
                        )
                    certificate=valueIfTrue(
                        getCFCertificate(
                            appSettingsObject.CertificateId,
                            occurrence.CloudFront.AssumeSNI),
                        occurrence.DNSIsConfigured)
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
                        occurrence.CloudFront.EnableLogging)
                    origins=origin
                    restrictions=valueIfContent(
                        restrictions,
                        restrictions)
                    wafAclId=valueIfTrue(
                        wafAclId,
                        (occurrence.WAFIsConfigured &&
                            ipAddressGroupsUsage["waf"]?has_content))
                /]
                [@cfResource
                    mode=applicationListMode
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

                [#if occurrence.WAFIsConfigured &&
                        ipAddressGroupsUsage["waf"]?has_content ]
                    [#assign wafGroups = [] ]
                    [#assign wafRuleDefault = 
                                occurrence.WAF.RuleDefault?has_content?then(
                                    occurrence.WAF.RuleDefault,
                                    "ALLOW")]
                    [#assign wafDefault = 
                                occurrence.WAF.Default?has_content?then(
                                    occurrence.WAF.Default,
                                    "BLOCK")]
                    [#if occurrence.WAF.IPAddressGroups?has_content]
                        [#list occurrence.WAF.IPAddressGroups as group]
                            [#assign groupId = group?is_hash?then(
                                            group.Id,
                                            group)]
                            [#if (ipAddressGroupsUsage["waf"][groupId])?has_content]
                                [#assign usageGroup = ipAddressGroupsUsage["waf"][groupId]]
                                [#if usageGroup.IsOpen]
                                    [#assign wafRuleDefault = 
                                        occurrence.WAF.RuleDefault?has_content?then(
                                            occurrence.WAF.RuleDefault,
                                            "COUNT")]
                                    [#assign wafDefault = 
                                            occurrence.WAF.Default?has_content?then(
                                                occurrence.WAF.Default,
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
                                    occurrence.WAF.RuleDefault?has_content?then(
                                        occurrence.WAF.RuleDefault,
                                        "COUNT")]
                                [#assign wafDefault = 
                                        occurrence.WAF.Default?has_content?then(
                                            occurrence.WAF.Default,
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
                        mode=applicationListMode
                        id=wafAclId
                        name=wafAclName
                        metric=wafAclName
                        default=wafDefault
                        rules=wafRules /]
                [/#if]
            [#else]
                [#if occurrence.DNSIsConfigured]
                    [#-- TODO: fix fetching of certificate Arn --]
                    [@cfResource
                        mode=applicationListMode
                        id=domainId
                        type="AWS::ApiGateway::DomainName"
                        properties= 
                            {
                                "CertificateArn": "",
                                "DomainName" : dns
                            }
                        outputs={}
                    /]
                    [@cfResource
                        mode=applicationListMode
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
        [#switch applicationListMode]
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
