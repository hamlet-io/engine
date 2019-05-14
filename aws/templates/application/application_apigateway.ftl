[#-- API Gateway --]

[#if (componentType == APIGATEWAY_COMPONENT_TYPE)]
    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]
        [#assign attributes = occurrence.State.Attributes ]
        [#assign roles = occurrence.State.Roles]

        [#assign apiId      = resources["apigateway"].Id]
        [#assign apiName    = resources["apigateway"].Name]

        [#-- Use runId to ensure deploy happens every time --]
        [#assign deployId   = resources["apideploy"].Id]
        [#assign stageId    = resources["apistage"].Id]
        [#assign stageName  = resources["apistage"].Name]

        [#-- Determine the stage variables required --]
        [#assign stageVariables = {} ]

        [#assign fragment =
            contentIfContent(solution.Fragment, getComponentId(component)) ]

        [#assign swaggerFileName ="swagger_" + runId + ".json"  ]
        [#assign swaggerFileLocation = formatRelativePath(
                                                    getSettingsFilePrefix(occurrence),
                                                    "config",
                                                    swaggerFileName)]

        [#assign contextLinks = getLinkTargets(occurrence) ]
        [#assign _context =
            {
                "Id" : fragment,
                "Name" : fragment,
                "Instance" : core.Instance.Id,
                "Version" : core.Version.Id,
                "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks),
                "Environment" : {},
                "Links" : contextLinks,
                "DefaultCoreVariables" : false,
                "DefaultEnvironmentVariables" : false,
                "DefaultLinkVariables" : false,
                "Policy" : []
            }
        ]

        [#-- Add in fragment specifics including override of defaults --]
        [#if solution.Fragment?has_content ]
            [#assign fragmentListMode = "model"]
            [#assign fragmentId = formatFragmentId(_context)]
             [#include fragmentList?ensure_starts_with("/")]
        [/#if]

        [#assign stageVariables += getFinalEnvironment(occurrence, _context).Environment ]

        [#assign cognitoPools = {} ]

        [#list solution.Links?values as link]
            [#if link?is_hash]
                [#assign linkTarget = getLinkTarget(occurrence, link, false) ]

                [@cfDebug listMode linkTarget false /]

                [#if !linkTarget?has_content]
                    [#continue]
                [/#if]

                [#assign linkTargetCore = linkTarget.Core ]
                [#assign linkTargetConfiguration = linkTarget.Configuration ]
                [#assign linkTargetResources = linkTarget.State.Resources ]
                [#assign linkTargetAttributes = linkTarget.State.Attributes ]

                [#switch linkTargetCore.Type]
                    [#case LB_COMPONENT_TYPE ]
                        [#if isLinkTargetActive(linkTarget) ]
                            [#assign stageVariables +=
                                {
                                    formatSettingName(link.Name, "DOCKER") : linkTargetAttributes.FQDN
                                }
                            ]
                        [/#if]
                        [#break]

                    [#case LAMBDA_FUNCTION_COMPONENT_TYPE]
                        [#-- Add function even if it isn't active so APi gateway if fully configured --]
                        [#-- even if lambda have yet to be deployed                                  --]
                        [#assign stageVariables +=
                            {
                                formatSettingName(
                                    link.Name,
                                    linkTargetCore.SubComponent.Name,
                                    "LAMBDA") : linkTargetResources["function"].Name
                            }
                        ]
                        [#break]

                    [#case USERPOOL_COMPONENT_TYPE]
                        [#if isLinkTargetActive(linkTarget) ]
                            [#assign cognitoPools +=
                                {
                                    link.Name : {
                                        "Name" : link.Name,
                                        "Header" : linkTargetAttributes["AUTHORIZATION_HEADER"]!"Authorization",
                                        "UserPoolArn" : linkTargetAttributes["USER_POOL"],
                                        "Default" : true
                                    }
                                } ]

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
                        [/#if]
                        [#break]
                [/#switch]
            [/#if]
        [/#list]

        [#assign endpointType           = solution.EndpointType ]
        [#assign isRegionalEndpointType = endpointType == "REGIONAL" ]

        [#assign securityProfile        = getSecurityProfile(solution.Profiles.Security, "apigateway")]

        [#assign wafAclResources        = resources["wafacl"]!{} ]
        [#assign cfResources            = resources["cf"]!{} ]
        [#assign customDomainResources  = resources["customDomains"]!{} ]

        [#assign apiPolicyStatements    = _context.Policy ]
        [#assign apiPolicyAuth          = solution.Authentication?upper_case ]

        [#assign apiPolicyCidr          = getGroupCIDRs(solution.IPAddressGroups) ]
        [#if (!(wafAclResources?has_content)) && (!(apiPolicyCidr?has_content)) ]
            [@cfException
                mode=listMode
                description="No IP Address Groups provided for API Gateway"
                context=occurrence
            /]
            [#continue]
        [/#if]

        [#-- Determine the resource policy                                                --]
        [#--                                                                              --]
        [#-- For SIG4 variants, AWS_IAM must be enabled in the swagger specification      --]
        [#-- If AWS_IAM is enabled, it's IAM policy is evaluated in the usual fashion     --]
        [#-- with the resource policy. However if NOT defined, there is no explicit ALLOW --]
        [#-- (at present) so the resource policy must provide one.                        --]
        [#-- If an "AWS_ALLOW" were introduced in the swagger spec to provide the ALLOW,  --]
        [#-- then the switch below could be simplified.                                   --]
        [#--                                                                              --]
        [#-- NOTE: the format of the resource arn is non-standard and undocumented at the --]
        [#-- time of writing. It seems like a workaround to the fact that cloud formation --]
        [#-- reports a circular reference if the policy references the apiId via the arn. --]
        [#-- (see case 5398420851)                                                        --]
        [#--                                                                              --]

        [#-- Ensure the stage(s) used for deployments can't be accessed externally --]
        [#assign apiPolicyStatements +=
            [
                getPolicyStatement(
                    "execute-api:Invoke",
                    "execute-api:/default/*",
                    "*",
                    {},
                    false
                )
            ] ]
        [#if apiPolicyCidr?has_content ]
            [#-- Ensure the stage(s) used for deployments can't be accessed externally --]
            [#switch apiPolicyAuth ]
                [#case "IP" ]
                    [#-- No explicit ALLOW so provide one in the resource policy --]
                    [#assign apiPolicyStatements +=
                        [
                            getPolicyStatement(
                                "execute-api:Invoke",
                                "execute-api:/*",
                                "*"
                            ),
                            getPolicyStatement(
                                "execute-api:Invoke",
                                "execute-api:/*",
                                "*",
                                getIPCondition(apiPolicyCidr, false),
                                false
                            )
                        ] ]
                    [#break]

                [#case "SIG4ORIP" ]
                    [#-- Resource policy provides ALLOW on IP --]
                    [#-- AWS_IAM provides ALLOW on SIG4       --]
                    [#assign apiPolicyStatements +=
                        [
                            getPolicyStatement(
                                "execute-api:Invoke",
                                "execute-api:/*",
                                "*",
                                getIPCondition(apiPolicyCidr)
                            )
                        ] ]
                    [#break]

                [#case "SIG4ANDIP" ]
                    [#-- Rely on AWS_IAM to provide the explicit ALLOW to avoid the implicit DENY --]
                    [#assign apiPolicyStatements +=
                        [
                            getPolicyStatement(
                                "execute-api:Invoke",
                                "execute-api:/*",
                                "*",
                                getIPCondition(apiPolicyCidr, false),
                                false
                            )
                        ] ]
                    [#break]
            [/#switch]
        [#else]
            [#-- No IP filtering required so add explicit ALLOW in the resource policy --]
            [#assign apiPolicyStatements +=
                [
                    getPolicyStatement(
                        "execute-api:Invoke",
                        "execute-api:/*",
                        "*"
                    )
                ] ]
        [/#if]

        [#assign accessLgId   = resources["accesslg"].Id]
        [#assign accessLgName = resources["accesslg"].Name]
        [#if deploymentSubsetRequired("lg", true) && isPartOfCurrentDeploymentUnit(accessLgId) ]
            [@createLogGroup
                mode=listMode
                id=accessLgId
                name=accessLgName /]
        [/#if]

        [#if deploymentSubsetRequired("apigateway", true)]
            [#-- Assume extended swagger specification is in the ops bucket --]
            [@cfResource
                mode=listMode
                id=apiId
                type="AWS::ApiGateway::RestApi"
                properties=
                    {
                        "BodyS3Location" : {
                            "Bucket" : operationsBucket,
                            "Key" : swaggerFileLocation
                        },
                        "Name" : apiName
                    } +
                    attributeIfTrue(
                        "EndpointConfiguration",
                        isRegionalEndpointType,
                        {
                            "Types" : [endpointType]
                        }
                    ) +
                    attributeIfContent(
                        "Policy",
                        apiPolicyStatements,
                        getPolicyDocumentContent(apiPolicyStatements)
                    )
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
                        "StageName" : stageName,
                        "AccessLogSetting" : {
                            "DestinationArn" : getArn(accessLgId),
                            "Format" : "$context.identity.sourceIp $context.identity.caller $context.identity.user $context.identity.userArn [$context.requestTime] $context.apiId $context.httpMethod $context.resourcePath $context.protocol $context.status $context.responseLength $context.requestId"
                        }
                    } +
                    attributeIfContent("Variables", stageVariables)
                outputs={}
                dependencies=deployId
            /]

            [#-- Create a WAF ACL if required --]
            [#if wafAclResources?has_content ]
                [@createWAFAclFromSecurityProfile
                    mode=listMode
                    id=wafAclResources.acl.Id
                    name=wafAclResources.acl.Name
                    metric=wafAclResources.acl.Name
                    wafSolution=solution.WAF
                    securityProfile=securityProfile
                    occurrence=occurrence
                    regional=isRegionalEndpointType && (!cfResources?has_content) /]

                [#if !cfResources?has_content]
                    [#-- Attach to API Gateway if no CloudFront distribution --]
                    [@createWAFAclAssociation
                        mode=listMode
                        id=wafAclResources.association.Id
                        wafaclId=wafAclResources.acl.Id
                        endpointId=
                            formatRegionalArn(
                                "apigateway",
                                {
                                    "Fn::Join": [
                                        "/",
                                        [
                                            "/restapis",
                                            getReference(apiId),
                                            "stages",
                                            stageName
                                        ]
                                    ]
                                }
                            ) /]
                [/#if]
            [/#if]

            [#-- Create a CloudFront distribution if required --]
            [#if cfResources?has_content]
                [#assign origin =
                    getCFHTTPOrigin(
                        cfResources["origin"].Id,
                        valueIfTrue(
                            cfResources["origin"].Fqdn,
                            customDomainResources?has_content,
                            {
                                "Fn::Join" : [
                                    ".",
                                    [
                                        getReference(apiId),
                                        "execute-api." + regionId + ".amazonaws.com"
                                    ]
                                ]
                            }
                        ),
                        getCFHTTPHeader(
                            "x-api-key",
                            getOccurrenceSettingValue(
                                occurrence,
                                ["APIGateway","API","AccessKey"]))) ]
                [#assign defaultCacheBehaviour =
                    getCFAPIGatewayCacheBehaviour(
                        origin,
                        solution.CloudFront.CustomHeaders +
                            valueIfTrue(
                                ["Host"],
                                endpointType == "REGIONAL",
                                []
                            ),
                        solution.CloudFront.Compress) ]
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
                    id=cfResources["distribution"].Id
                    dependencies=stageId
                    aliases=cfResources["distribution"].Fqdns![]
                    certificate=valueIfContent(
                        getCFCertificate(
                            cfResources["distribution"].CertificateId,
                            securityProfile.HTTPSProfile,
                            solution.CloudFront.AssumeSNI),
                        cfResources["distribution"].CertificateId!"")
                    comment=cfResources["distribution"].Name
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
                    restrictions=restrictions
                    wafAclId=(wafAclResources.acl.Id)!""
                /]
                [@createAPIUsagePlan
                    mode=listMode
                    id=cfResources["usageplan"].Id
                    name=cfResources["usageplan"].Name
                    stages=[
                        {
                          "ApiId" : getReference(apiId),
                          "Stage" : stageName
                        }
                    ]
                    dependencies=stageId
                /]
            [/#if]

            [#list customDomainResources as key,value]
                [@cfResource
                    mode=listMode
                    id=value["domain"].Id
                    type="AWS::ApiGateway::DomainName"
                    properties=
                        {
                            "DomainName" : value["domain"].Name
                        } +
                        valueIfTrue(
                            {
                                "RegionalCertificateArn":
                                    getArn(value["domain"].CertificateId, true, regionId),
                                "EndpointConfiguration" : {
                                    "Types" : [endpointType]
                                }
                            },
                            isRegionalEndpointType,
                            {
                                "CertificateArn":
                                    getArn(value["domain"].CertificateId, true, "us-east-1")
                            }
                        )
                    outputs={}
                    dependencies=apiId
                /]
                [@cfResource
                    mode=listMode
                    id=value["basepathmapping"].Id
                    type="AWS::ApiGateway::BasePathMapping"
                    properties=
                        {
                            "DomainName" : value["domain"].Name,
                            "RestApiId" : getReference(apiId)
                        } +
                        attributeIfContent("Stage", value["basepathmapping"].Stage)
                    outputs={}
                    dependencies=value["domain"].Id
                /]
            [/#list]

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

            [#list resources.logMetrics!{} as logMetricName,logMetric ]

                [@createLogMetric
                    mode=listMode
                    id=logMetric.Id
                    name=logMetric.Name
                    logGroup=logMetric.LogGroupName
                    filter=logFilters[logMetric.LogFilter].Pattern
                    namespace=getResourceMetricNamespace(logMetric.Type)
                    value=1
                    dependencies=logMetric.LogGroupId
                /]

            [/#list]
        [/#if]

        [#-- API Docs have been deprecated - keeping the S3 clear makes sure we can delete the buckets --]
        [#assign docs = resources["docs"]!{} ]
        [#list docs as key,value]

            [#assign bucketName = value["bucket"].Name]
            [#if deploymentSubsetRequired("prologue", false)  ]
                [#-- Clear out bucket content if deleting api gateway so buckets will delete --]
                [#if getExistingReference(bucketId)?has_content ]
                    [@cfScript
                        mode=listMode
                        content=
                            [
                                "clear_bucket_files=()"
                            ] +
                            syncFilesToBucketScript(
                                "clear_bucket_files",
                                regionId,
                                bucketName,
                                ""
                            ) 
                    /]
                [/#if]

                [@cfScript
                    mode=listMode
                    content=
                        [
                            "error \" API Docs publishing hs been depreated \"",
                            "error \" Please remove the Publish configuration from your API Gateway\"",
                            "error \" API Publishers are now available to provide documentation publishing\""
                        ]
                /]
            [/#if]
        [/#list]

        [#-- Send API Specification to an external publisher --]
        [#if solution.Publishers?has_content ]
            [#if deploymentSubsetRequired("epilogue", false ) ]
                [@cfScript
                    mode=listMode
                    content=
                    [
                        "case $\{STACK_OPERATION} in",
                        "  create|update)",
                        "   # Fetch the apidoc file",
                        "   info \"Building API Specification Document\"",
                        "   copyFilesFromBucket" + " " +
                            regionId + " " +
                            operationsBucket + " " +
                            swaggerFileLocation + " " +
                        "   \"$\{tmpdir}\" || return $?"
                        "   # Insert host in Doc File ",
                        "   add_host_to_apidoc" + " " +
                        "   \"" + attributes.FQDN + "\" " +
                        "   \"" +  attributes.SCHEME + "\" " +
                        "   \"" +  attributes.BASE_PATH + "\" " +
                        "   \"" +  getOccurrenceBuildReference(occurrence) + "\" " +
                        "   \"**COT Deployment:** " + core.TypedFullName + "\" " +
                        "   \"$\{tmpdir}/" + swaggerFileName + "\"  || return $?",
                        "   mkdir \"$\{tmpdir}/dist\" && mv \"$\{tmpdir}/" + swaggerFileName + "\" \"$\{tmpdir}/dist/swagger.json\" || return $?",
                        "   ;;",
                        " esac"
                    ]
                /]
            [/#if]

            [#list solution.Publishers as id,publisher ]
 
                [#assign publisherPath = getContentPath( occurrence, publisher.Path )]
                [#assign publisherLinks = getLinkTargets(occurrence, publisher.Links )]
                
                [#list publisherLinks as publisherLinkId, publisherLinkTarget ]
                    [#assign publisherLinkTargetCore = publisherLinkTarget.Core ]
                    [#assign publisherLinkTargetAttributes = publisherLinkTarget.State.Attributes ]

                    [#switch publisherLinkTargetCore.Type ]
                        [#case CONTENTHUB_HUB_COMPONENT_TYPE ]
                        [#case "external"]
                            [#if deploymentSubsetRequired("epilogue", false ) ]
                                [@cfScript
                                    mode=listMode
                                    content= 
                                    [
                                        "case $\{STACK_OPERATION} in",
                                        "  create|update)",
                                        "info \"Sending API Specification to " + id + "-" + publisherLinkId + "\"",
                                        "  copy_contentnode_file \"$\{tmpdir}/dist/swagger.json\" " + 
                                        "\"" +    publisherLinkTargetAttributes.ENGINE + "\" " +
                                        "\"" +    publisherLinkTargetAttributes.REPOSITORY + "\" " + 
                                        "\"" +    publisherLinkTargetAttributes.PREFIX + "\" " +
                                        "\"" +    publisherPath + "\" " +
                                        "\"" +    publisherLinkTargetAttributes.BRANCH + "\" || return $? ",
                                        "       ;;",
                                        " esac"
                                    ]
                                /]
                            [/#if]
                            [#break]
                    [/#switch]
                [/#list]
            [/#list]
        [/#if]

        [#assign legacyId = formatS3Id(core.Id, APIGATEWAY_COMPONENT_DOCS_EXTENSION) ]
        [#if getExistingReference(legacyId)?has_content && deploymentSubsetRequired("prologue", false) ]
            [#-- Remove legacy docs bucket id - it will likely be recreated with new id format --]
            [#-- which uses bucket name --]
            [@cfScript
                mode=listMode
                content=
                    [
                        "clear_bucket_files=()"
                    ] +
                    syncFilesToBucketScript(
                        "clear_bucket_files",
                        regionId,
                        getExistingReference(legacyId, NAME_ATTRIBUTE_TYPE),
                        ""
                    ) +
                    [
                        "deleteBucket" + " " +
                            regionId + " " +
                            getExistingReference(legacyId, NAME_ATTRIBUTE_TYPE) + " " +
                            "|| return $?"
                    ]
            /]
        [/#if]

        [#if deploymentSubsetRequired("pregeneration", false)]
            [@cfScript
                mode=listMode
                content=
                    getBuildScript(
                        "swaggerFiles",
                        regionId,
                        "swagger",
                        productName,
                        occurrence,
                        "swagger.zip"
                    ) +
                    [
                        "get_swagger_definition_file" + " " +
                             "\"$\{swaggerFiles[0]}\"" + " " +
                             "\"" + core.Id + "\"" + " " +
                             "\"" + core.Name + "\"" + " " +
                             "\"" + accountId + "\"" + " " +
                             "\"" + accountObject.AWSId + "\"" + " " +
                             "\"" + region + "\"" + " || return $?",
                        "#"

                    ]
            /]
        [/#if]

        [#if definitionsObject[core.Id]?? ]
            [#assign swaggerDefinition = definitionsObject[core.Id] ]
            [#if swaggerDefinition["x-amazon-apigateway-request-validator"]?? ]
                [#-- Pass definition through - it is legacy and has already has been processed --]
                [#assign extendedSwaggerDefinition = swaggerDefinition ]
            [#else]
                [#assign swaggerIntegrations = getOccurrenceSettingValue(occurrence, [["apigw"], ["Integrations"]], true) ]
                [#if !swaggerIntegrations?has_content]
                    [@cfException
                        mode=listMode
                        description="API Gateway integration definitions not found"
                        context=occurrence
                    /]
                    [#assign swaggerIntegrations = {} ]
                [/#if]
                [#if swaggerIntegrations?is_hash]
                    [#assign swaggerContext =
                        {
                            "Account" : accountObject.AWSId,
                            "Region" : region,
                            "CognitoPools" : cognitoPools
                        } ]

                    [#-- Determine if there are any roles required by specific methods --]
                    [#assign extendedSwaggerRoles = getSwaggerDefinitionRoles(swaggerDefinition, swaggerIntegrations) ]
                    [#list extendedSwaggerRoles as path,policies]
                        [#assign swaggerRoleId = formatDependentRoleId(stageId, formatId(path))]
                        [#-- Roles must be defined in a separate unit so the ARNs are available here --]
                        [#if deploymentSubsetRequired("iam", false)  &&
                            isPartOfCurrentDeploymentUnit(swaggerRoleId)]
                            [@createRole
                                mode=listMode
                                id=swaggerRoleId
                                trustedServices="apigateway.amazonaws.com"
                                policies=policies
                            /]
                        [/#if]
                        [#assign swaggerContext +=
                            {
                                formatAbsolutePath(path,"rolearn") : getArn(swaggerRoleId, true)
                            } ]
                    [/#list]

                    [#-- Generate the extended swagger specification --]
                    [#assign extendedSwaggerDefinition =
                        extendSwaggerDefinition(
                            swaggerDefinition,
                            swaggerIntegrations,
                            swaggerContext,
                            true) ]

                [#else]
                    [#assign extendedSwaggerDefinition = {} ]
                    [@cfException
                        mode=listMode
                        description="API Gateway integration definitions should be a hash"
                        context={ "Integrations" : swaggerIntegrations}
                    /]
                [/#if]
            [/#if]

            [#if extendedSwaggerDefinition?has_content]
                [#if deploymentSubsetRequired("config", false)]
                    [@cfConfig
                        mode=listMode
                        content=extendedSwaggerDefinition
                    /]
                [/#if]
            [/#if]
        [/#if]

        [#if deploymentSubsetRequired("prologue", false)]
            [#-- Copy the final swagger definition to the ops bucket --]
            [@cfScript
                mode=listMode
                content=
                    getLocalFileScript(
                        "configFiles",
                        "$\{CONFIG}",
                        "swagger_" + runId + ".json"
                    ) +
                    syncFilesToBucketScript(
                        "configFiles",
                        regionId,
                        operationsBucket,
                        formatRelativePath(
                            getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX"),
                            "config"))
            /]
        [/#if]
    [/#list]
[/#if]
