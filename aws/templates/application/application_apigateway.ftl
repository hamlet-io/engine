[#-- API Gateway --]

[#if componentType == "apigateway"]
    [#assign apigateway = component.APIGateway]
    
    [#assign apigatewayInstances=[] ]    
    [#if apigateway.Versions??]
        [#list apigateway.Versions?values as version]
            [#if deploymentRequired(version, deploymentUnit)]  
                [#if version.Instances??]
                    [#list version.Instances?values as apigatewayInstance]
                        [#if deploymentRequired(apigatewayInstance, deploymentUnit)]
                            [#assign apigatewayInstances += [apigatewayInstance +
                                    {
                                        "Internal" : {
                                            "IdExtensions" : [
                                                version.Id,
                                                (apigatewayInstance.Id == "default")?
                                                    string(
                                                        "",
                                                        apigatewayInstance.Id)],
                                            "NameExtensions" : [
                                                version.Name,
                                                (apigatewayInstance.Id == "default")?
                                                    string(
                                                        "",
                                                        apigatewayInstance.Name)],
                                            "VersionId" : version.Id,
                                            "StageName" : version.Name,
                                            "InstanceIdRef" : apigatewayInstance.Id,
                                            "WAF" : {
                                                "IsConfigured" :
                                                    (apigatewayInstance.WAF?? ||
                                                        version.WAF?? ||
                                                        apigateway.WAF??) &&
                                                    ipAddressGroupsUsage["waf"]?has_content,
                                                "IPAddressGroups" :
                                                    (apigatewayInstance.WAF.IPAddressGroups) !
                                                    (version.WAF.IPAddressGroups) !
                                                    apigateway.WAF.IPAddressGroups !
                                                    [],
                                                "Default" :
                                                    (apigatewayInstance.WAF.Default) !
                                                    (version.WAF.Default) !
                                                    (apigateway.WAF.Default) !
                                                    "",
                                                "RuleDefault" :
                                                    (apigatewayInstance.WAF.RuleDefault) !
                                                    (version.WAF.RuleDefault) !
                                                    (apigateway.WAF.RuleDefault) !
                                                    ""
                                            },
                                            "CloudFront" : {
                                                "IsConfigured" :
                                                    apigatewayInstance.CloudFront?? ||
                                                    version.CloudFront?? ||
                                                    apigateway.CloudFront??,
                                                "AssumeSNI" :
                                                    (apigatewayInstance.CloudFront.AssumeSNI) !
                                                    (version.CloudFront.AssumeSNI) !
                                                    (apigateway.CloudFront.AssumeSNI)!
                                                    true
                                            },
                                            "DNS" : {
                                                "Host" :
                                                    (apigatewayInstance.DNS.Host) !
                                                    (version.DNS.Host) !
                                                    (apigateway.DNS.Host)!
                                                    ""
                                            }
                                        }
                                    }
                                ] 
                            ]
                        [/#if]
                    [/#list]
                [#else]
                    [#assign apigatewayInstances += [version +
                            {
                                "Internal" : {
                                    "IdExtensions" : [version.Id],
                                    "NameExtensions" : [version.Name],
                                    "VersionId" : version.Id,
                                    "StageName" : version.Name,
                                    "InstanceIdRef" : apigatewayInstance.Id,
                                    "WAF" : {
                                        "IsConfigured" :
                                            (version.WAF?? ||
                                                apigateway.WAF??) &&
                                            ipAddressGroupsUsage["waf"]?has_content,
                                        "IPAddressGroups" :
                                            (version.WAF.IPAddressGroups) !
                                            apigateway.WAF.IPAddressGroups !
                                            [],
                                        "Default" :
                                            (version.WAF.Default) !
                                            (apigateway.WAF.Default) !
                                            "",
                                        "RuleDefault" :
                                            (version.WAF.RuleDefault) !
                                            (apigateway.WAF.RuleDefault) !
                                            ""
                                    },
                                    "CloudFront" : {
                                        "IsConfigured" :
                                            version.CloudFront?? ||
                                            apigateway.CloudFront??,
                                        "AssumeSNI" :
                                            (version.CloudFront.AssumeSNI) !
                                            (apigateway.CloudFront.AssumeSNI) !
                                            true
                                    },
                                    "DNS" : {
                                        "Host" :
                                            (version.DNS.Host) !
                                            (apigateway.DNS.Host)!
                                            ""
                                    }
                                }
                            }
                        ] 
                    ]
                [/#if]
            [/#if]
        [/#list]
    [/#if]
    
    [#-- Non-repeating text to ensure deploy happens every time --]
    [#assign noise = random.nextLong()?string.computer?replace("-","X")]
    [#list apigatewayInstances as apigatewayInstance]
        [#assign apiId    = formatAPIGatewayId(
                                tier,
                                component,
                                apigatewayInstance)]
        [#assign deployId = formatAPIGatewayDeployId(
                                tier,
                                component,
                                apigatewayInstance,
                                noise)]
        [#assign stageId  = formatAPIGatewayStageId(
                                tier,
                                component,
                                apigatewayInstance)]
        [#assign cfId  = formatDependentCFDistributionId(
                                apiId)]
        [#assign cfName  = formatComponentCFDistributionName(
                                tier,
                                component,
                                apigatewayInstance)]
        [#assign usagePlanId  = formatDependentAPIGatewayUsagePlanId(cfId)]
        [#assign usagePlanName = formatComponentUsagePlanName(
                                tier,
                                component,
                                apigatewayInstance)]
         [#assign wafAclId  = formatDependentWAFRuleId(
                                apiId)]
        [#assign wafAclName  = formatComponentWAFRuleName(
                                tier,
                                component,
                                apigatewayInstance)]

        [#switch applicationListMode]
            [#case "definition"]
                [@checkIfResourcesCreated /]
                "${apiId}" : {
                    "Type" : "AWS::ApiGateway::RestApi",
                    "Properties" : {
                        "BodyS3Location" : {
                            "Bucket" : "${getRegistryEndPoint("swagger")}",
                            "Key" : "${getRegistryPrefix("swagger")}${productName}/${buildDeploymentUnit}/${buildCommit}/swagger.json"
                        },
                        "Name" : "${formatComponentFullName(
                                        tier,
                                        component,
                                        apigatewayInstance)}"
                    }
                },
                "${deployId}" : {
                    "Type": "AWS::ApiGateway::Deployment",
                    "Properties": {
                        "RestApiId": { "Ref" : "${apiId}" },
                        "StageName": "default"
                    },
                    "DependsOn" : "${apiId}"
                },
                [#assign stageName = apigatewayInstance.Internal.StageName]
                "${stageId}" : {
                    "Type" : "AWS::ApiGateway::Stage",
                    "Properties" : {
                        "DeploymentId" : { "Ref" : "${deployId}" },
                        "RestApiId" : { "Ref" : "${apiId}" },
                        "MethodSettings": [
                            {
                              "HttpMethod": "*",
                              "ResourcePath": "/*",
                              "LoggingLevel": "INFO",
                              "DataTraceEnabled": true
                            }
                        ],
                        "StageName" : "${stageName}"
                        [#if apigatewayInstance.Links??]
                            ,"Variables" : {
                                [#assign linkCount = 0]
                                [#list apigatewayInstance.Links?values as link]
                                    [#if link?is_hash]
                                        [#if getComponent(link.Tier, link.Component)??]
                                            [#assign targetTier = getTier(link.Tier)]
                                            [#assign targetComponent = getComponent(link.Tier, link.Component)]
                                            [#assign targetComponentType = getComponentType(targetComponent)]
                                            [#if (targetComponentType == "alb") || (targetComponentType == "elb")]
                                                [#if linkCount > 0],[/#if]
                                                [#assign stageVariable = link.Name?upper_case + "_DOCKER" ]
                                                [@environmentVariable stageVariable
                                                    getKey(formatALBDNSId(
                                                            targetTier,
                                                            targetComponent))
                                                    "apigateway" /]
                                                [#assign linkCount += 1]
                                            [/#if]
                                            [#if targetComponentType == "lambda"]
                                                [#assign lambdaInstance = targetComponent.Lambda ]
                                                [#assign lambdaFunctions = (lambdaInstance.Functions)!"unknown" ]
                                                [#if targetComponent.Lambda.Versions?? ]
                                                    [#assign lambdaInstance = targetComponent.Lambda.Versions[apigatewayInstance.Internal.VersionId] ]
                                                    [#assign lambdaFunctions = (lambdaInstance.Functions)!lambdaFunctions ]
                                                    [#if targetComponent.Lambda.Versions[apigatewayInstance.Internal.VersionId].Instances??]
                                                        [#assign lambdaInstance = targetComponent.Lambda.Versions[apigatewayInstance.Internal.VersionId].Instances[apigatewayInstance.Internal.InstanceIdRef] ]
                                                        [#assign lambdaFunctions = (lambdaInstance.Functions)!lambdaFunctions ]
                                                    [/#if]
                                                [/#if]

                                                [#if lambdaFunctions?is_hash]
                                                    [#list lambdaFunctions?values as fn]
                                                        [#if fn?is_hash]
                                                            [#if linkCount > 0],[/#if]
                                                            [#assign stageVariable = link.Name?upper_case + "_" + fn.Name?upper_case + "_LAMBDA"]
                                                            [#assign fnName = formatLambdaFunctionName(
                                                                                        targetTier,
                                                                                        targetComponent,
                                                                                        apigatewayInstance,
                                                                                        fn)]
                                                            [@environmentVariable stageVariable fnName "apigateway" /]
                                                            [#assign linkCount += 1]
                                                        [/#if]
                                                    [/#list]
                                                [/#if]
                                            [/#if]
                                        [/#if]
                                    [/#if]
                                [/#list]
                            }
                        [/#if]
                    },
                    "DependsOn" : "${deployId}"
                }
                [#-- Include access to lambda functions if required --]
                [#if apigatewayInstance.Links?? ]
                    [#list apigatewayInstance.Links?values as link]
                        [#if link?is_hash]
                            [#if getComponent(link.Tier, link.Component)??]
                                [#assign targetTier = getTier(link.Tier)]
                                [#assign targetComponent = getComponent(link.Tier, link.Component)]
                                [#assign targetComponentType = getComponentType(targetComponent)]
                                [#if targetComponentType == "lambda"]
                                    [#assign lambdaInstance = targetComponent.Lambda ]
                                    [#assign lambdaFunctions = (lambdaInstance.Functions)!"unknown" ]
                                    [#if targetComponent.Lambda.Versions?? ]
                                        [#assign lambdaInstance = targetComponent.Lambda.Versions[apigatewayInstance.Internal.VersionId] ]
                                        [#assign lambdaFunctions = (lambdaInstance.Functions)!lambdaFunctions ]
                                        [#if targetComponent.Lambda.Versions[apigatewayInstance.Internal.VersionId].Instances??]
                                            [#assign lambdaInstance = targetComponent.Lambda.Versions[apigatewayInstance.Internal.VersionId].Instances[apigatewayInstance.Internal.InstanceIdRef] ]
                                            [#assign lambdaFunctions = (lambdaInstance.Functions)!lambdaFunctions ]
                                        [/#if]
                                    [/#if]

                                    [#if lambdaFunctions?is_hash]
                                        [#list lambdaFunctions?values as fn]
                                            [#if fn?is_hash]
                                                [#assign fnName = formatLambdaFunctionName(
                                                                            targetTier,
                                                                            targetComponent,
                                                                            apigatewayInstance,
                                                                            fn)]
                                                ,"${formatAPIGatewayLambdaPermissionId(
                                                        tier,
                                                        component,
                                                        link,
                                                        fn,
                                                        apigatewayInstance)}" : {
                                                    "Type" : "AWS::Lambda::Permission",
                                                    "Properties" : {
                                                        "Action" : "lambda:InvokeFunction",
                                                        "FunctionName" : "${fnName}",
                                                        "Principal" : "apigateway.amazonaws.com",
                                                        "SourceArn" : {
                                                            "Fn::Join" : [
                                                                "",
                                                                [
                                                                    "arn:aws:execute-api:",
                                                                    "${regionId}", ":",
                                                                    {"Ref" : "AWS::AccountId"}, ":",                    
                                                                    { "Ref" : "${apiId}" },
                                                                    "/${stageName}/*"
                                                                ]
                                                            ]
                                                        }
                                                    }
                                                }
                                            [/#if]
                                        [/#list]
                                    [/#if]
                                [/#if]
                            [/#if]
                        [/#if]
                    [/#list]
                [/#if]
                [@resourcesCreated/]
                [#break]

            [#case "outputs"]
                [@output apiId /]
                [@outputRoot apiId /]
                [#break]

        [/#switch]
        [#if apigatewayInstance.Internal.CloudFront.IsConfigured]
            [#switch applicationListMode]
                [#case "definition"]
                    [@checkIfResourcesCreated /]
                    "${cfId}" : {
                        "Type" : "AWS::CloudFront::Distribution",
                        "Properties" : {
                            "DistributionConfig" : {
                                "Aliases" : [
                                    "${formatName(
                                        apigatewayInstance.Internal.DNS.Host,
                                        segmentDomainQualifier) + "." + segmentDomain}"
                                ],
                                "Comment" : "${cfName}",
                                "DefaultCacheBehavior" : {
                                    "AllowedMethods" : [
                                        "DELETE",
                                        "GET",
                                        "HEAD",
                                        "OPTIONS",
                                        "PATCH",
                                        "POST",
                                        "PUT"
                                    ],
                                    "CachedMethods" : [
                                        "GET",
                                        "HEAD"
                                    ],
                                    "Compress" : false,
                                    "DefaultTTL" : 0,
                                    "ForwardedValues" : {
                                        "Cookies" : {
                                            "Forward" : "all"
                                        },
                                        "Headers" : [
                                            "Accept",
                                            "Accept-Charset",
                                            "Accept-Datetime",
                                            "Accept-Language",
                                            "Authorization",
                                            "Origin",
                                            "Referer"
                                        ],
                                        "QueryString" : true
                                    },
                                    "MaxTTL" : 0,
                                    "MinTTL" : 0,
                                    "SmoothStreaming" : false,
                                    "TargetOriginId" : "apigateway",
                                    "ViewerProtocolPolicy" : "redirect-to-https"
                                },
                                "Enabled" : true,
                                "Logging" : {
                                    "Bucket" : "${operationsBucket + ".s3.amazonaws.com"}",
                                    "IncludeCookies" : false,
                                    "Prefix" : "${"CLOUDFRONTLogs" +
                                                  formatComponentAbsoluteFullPath(
                                                    tier,
                                                    component,
                                                    apigatewayInstance)}"
                                },
                                "Origins" : [
                                    {
                                        "CustomOriginConfig" : {
                                            "OriginProtocolPolicy" : "https-only",
                                            "OriginSSLProtocols" : ["TLSv1.2"]
                                        },
                                        "DomainName" : {
                                            "Fn::Join" : [
                                                    ".",
                                                    [
                                                        [@createReference apiId/],
                                                        "execute-api.${regionId}.amazonaws.com"
                                                    ]
                                            ]
                                        },
                                        "Id" : "apigateway",
                                        "OriginCustomHeaders" : [
                                            {
                                              "HeaderName" : "x-api-key",
                                              "HeaderValue" : "${credentialsObject.APIGateway.API.AccessKey}"
                                            }
                                        ]
                                    }
                                ],
                                [#-- TODO : Pick up Certificate ARN dynamically --]
                                "ViewerCertificate" : {
                                    "AcmCertificateArn" : {
                                        "Fn::Join" : [
                                                ":",
                                                [
                                                    "arn:aws:acm:us-east-1",
                                                    {"Ref" : "AWS::AccountId"},
                                                    [@createReference apiId/],
                                                    "${appSettingsObject.CertificateId}"
                                                ]
                                        ]
                                    },
                                    "MinimumProtocolVersion" : "TLSv1",
                                    "SslSupportMethod" :
                                        "${apigatewayInstance.Internal.CloudFront.AssumeSNI?then(
                                            "sni-only",
                                            "vip")}"
                                }
                                [#if apigatewayInstance.Internal.WAF.IsConfigured]
                                    ,"WebACLId" : [@createReference wafAclId /]
                                [/#if]
                            }
                        }
                    },
                    "${usagePlanId}" : {
                        "Type" : "AWS::ApiGateway::UsagePlan",
                        "Properties" : {
                            "ApiStages" : [
                                {
                                  "ApiId" : [@createReference apiId /],
                                  "Stage" : "${stageName}"
                                }
                            ],
                            "UsagePlanName" : "${usagePlanName}"
                        }
                    }
                    [@resourcesCreated /]
                    [#break]

                [#case "outputs"]
                    [@output cfId /]
                    [@outputCFDns cfId /]
                    [@output usagePlanId /]
                    [#break]

            [/#switch]

            [#if apigatewayInstance.Internal.WAF.IsConfigured]
                [#assign wafGroups = []]
                [#assign wafRuleDefault = 
                            apigatewayInstance.Internal.WAF.RuleDefault?has_content?then(
                                apigatewayInstance.Internal.WAF.RuleDefault,
                                "ALLOW")]
                [#assign wafDefault = 
                            apigatewayInstance.Internal.WAF.Default?has_content?then(
                                apigatewayInstance.Internal.WAF.Default,
                                "BLOCK")]
                [#if apigatewayInstance.Internal.WAF.IPAddressGroups?has_content]
                    [#list apigatewayInstance.Internal.WAF.IPAddressGroups as group]
                        [#assign groupId = group?is_hash?then(
                                        group.Id,
                                        group)]
                        [#if (ipAddressGroupsUsage["waf"][groupId])?has_content]
                            [#assign usageGroup = ipAddressGroupsUsage["waf"][groupId]]
                            [#if usageGroup.IsOpen]
                                [#assign wafRuleDefault = 
                                    apigatewayInstance.Internal.WAF.RuleDefault?has_content?then(
                                        apigatewayInstance.Internal.WAF.RuleDefault,
                                        "COUNT")]
                                [#assign wafDefault = 
                                        apigatewayInstance.Internal.WAF.Default?has_content?then(
                                            apigatewayInstance.Internal.WAF.Default,
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
                                apigatewayInstance.Internal.WAF.RuleDefault?has_content?then(
                                    apigatewayInstance.Internal.WAF.RuleDefault,
                                    "COUNT")]
                            [#assign wafDefault = 
                                    apigatewayInstance.Internal.WAF.Default?has_content?then(
                                        apigatewayInstance.Internal.WAF.Default,
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
                    applicationListMode
                    wafAclId
                    wafAclName
                    wafAclName
                    wafDefault
                    wafRules /]
            [/#if]
        [/#if]
    [/#list]
[/#if]
