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
                                            [#if deploymentSubsetRequired("apigateway", true)]
                                              [@cfResource
                                                  mode=listMode
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
        [#assign dns = "" ]
        [#-- assign dns = formatDomainName(
                            formatName(
                                occurrence.DNS.Host,
                                occurrence.InstanceName,
                                segmentDomainQualifier),
                            segmentDomain) --]

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
                    
            [#if occurrence.CloudFrontIsConfigured && occurrence.CloudFront.Enabled]
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
                    mode=listMode
                    id=cfId
                    dependencies=stageId     
                    aliases=
                        (occurrence.DNSIsConfigured && occurrence.DNS.Enabled)?then(
                            [dns],
                            []
                        )
                    certificate=valueIfTrue(
                        getCFCertificate(
                            appSettingsObject.CertificateId!"",
                            occurrence.CloudFront.AssumeSNI),
                        occurrence.DNSIsConfigured  && occurrence.DNS.Enabled)
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
                            occurrence.WAF.Enabled &&
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

                [#if occurrence.WAFIsConfigured &&
                        occurrence.WAF.Enabled &&
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
                        mode=listMode
                        id=wafAclId
                        name=wafAclName
                        metric=wafAclName
                        default=wafDefault
                        rules=wafRules /]
                [/#if]
            [#else]
                [#if occurrence.DNSIsConfigured && occurrence.DNS.Enabled]
                    [#assign certificateArn =
                        formatRegionalArn(
                            "acm",
                            formatTypedArnResource(
                                "certificate",
                                appSettingsObject.CertificateId,
                                "/"
                            ),
                            "us-east-1"
                        )]
                    [@cfResource
                        mode=listMode
                        id=domainId
                        type="AWS::ApiGateway::DomainName"
                        properties= 
                            {
                                "CertificateArn": certificateArn,
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
        

        [#if deploymentSubsetRequired("s3", true)]
            [#if occurrence.PublishIsConfigured && occurrence.Publish.Enabled ]
                [#assign docsS3BucketId = formatComponentS3Id(
                                            tier,
                                            component,
                                            occurrence,
                                            "docs")]
                
                [#assign docsS3BucketPolicyId = formatBucketPolicyId(
                                            tier,
                                            component,
                                            occurrence,
                                            "docs")]

                [#assign docsS3WebsiteConfiguration = getS3WebsiteConfiguration("apidoc.html", "")]

                [#assign docsS3BucketName = (occurrence.DNSIsConfigured && occurrence.DNS.Enabled)?then(
                                                formatDomainName(
                                                    occurrence.Publish.DnsNamePrefix,
                                                    dns
                                                ),
                                                formatName(
                                                    occurrence.Publish.DnsNamePrefix,
                                                    tier,
                                                    component,
                                                    occurrence
                                                )
                                                )]    
                
                [#assign docsWAFCIDRList = [] ]

                [#if occurrence.WAFIsConfigured &&
                        occurrence.WAF.Enabled &&
                        ipAddressGroupsUsage["waf"]?has_content ]
                    
                    [#list occurrence.WAF.IPAddressGroups as group]
                            
                            [#assign groupId = group?is_hash?then(
                                            group.Id,
                                            group)]
                            
                            [#if (ipAddressGroupsUsage["waf"][groupId])?has_content]
                                
                                [#assign docsWAFCIDRList +=  (ipAddressGroupsUsage["waf"][groupId]).CIDR  ]
                                
                            [/#if]
                            
                    [/#list]
                    
                [/#if]
                
                [#assign docsS3IPWhitelist = (docsWAFCIDRList?has_content)?then(
                                                s3IPAccessCondition(docsWAFCIDRList),
                                                "*")]                  

                [@createBucketPolicy
                    mode=applicationListMode
                    id=docsS3BucketPolicyId
                    bucket=docsS3BucketId
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
                    mode=applicationListMode
                    id=docsS3BucketId
                    name=docsS3BucketName
                    websiteConfiguration=docsS3WebsiteConfiguration
                    outputId=docsS3BucketId
                /]
            [/#if]  
        [/#if]

<<<<<<< HEAD
        [#switch listMode]
=======
        [#if deploymentSubsetRequired("epilogue", false)]
            [#if occurrence.PublishIsConfigured && occurrence.Publish.Enabled ]
                [@cfScript
                    mode=applicationListMode
                    content=
                    [
                        "function get_apidoc_file() {",
                        "  #",
                        "  # Temporary dir for the apidoc file",
                        "  mkdir -p ./temp_apidoc",
                        "  #",
                        "  # Fetch the apidoc file",
                        "  copyFilesFromBucket" + " " +
                            regionId + " " + 
                            getRegistryEndPoint("swagger") + " " +
                            formatRelativePath(
                                        productName,
                                        buildDeploymentUnit,
                                        buildCommit,
                                        "apidoc.html") + " " +
                        "   ./temp_apidoc || return $?",
                        "  #",
                        "  # Sync to the API Doc bucket",
                        "  copy_apidoc_file" + " " +  
                            formatComponentS3Id(
                                        tier,
                                        component,
                                        occurrence,
                                        "docs") + " " +
                        " ./temp_spa/apidoc.html",
                        "}",
                        "#",
                        "get_apidoc_file"
                    ]
                /]
            [/#if]
        [/#if]

        [#switch applicationListMode]
>>>>>>> 00a39cb... Added Doc Deployment Script
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
