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
            [#assign containerId = fragmentId]
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
        [#assign isEdgeEndpointType     = endpointType == "EDGE" ]

        [#assign securityProfile        = getSecurityProfile(solution.Profiles.Security, "apigateway")]

        [#assign apiPolicyStatements    = _context.Policy ]
        [#assign apiPolicyAuth          = solution.Authentication?upper_case ]

        [#assign apiPolicyCidr          = getGroupCIDRs(solution.IPAddressGroups) ]
        [#if (!(resources["cf"]["wafacl"])??) && (!(apiPolicyCidr?has_content)) ]
            [@cfException
                mode=listMode
                description="No IP Address Groups provided for API Gateway"
                context=occurrence
            /]
            [#continue]
        [/#if]


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
        [#if apiPolicyCidr?has_content ]
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
                            "Key" :
                                formatRelativePath(
                                    getSettingsFilePrefix(occurrence),
                                    "config",
                                    "swagger_" + runId + ".json")
                        },
                        "Name" : apiName
                    } +
                    attributeIfTrue(
                        "EndpointConfiguration",
                        !isEdgeEndpointType,
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

            [#assign cfResources = resources["cf"]!{} ]
            [#assign customDomainResources = resources["customDomains"]!{} ]
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
                    wafAclId=(cfResources["wafacl"].Id)!""
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

                [#if cfResources["wafacl"]?has_content ]
                    [@createWAFAcl
                        mode=listMode
                        id=cfResources["wafacl"].Id
                        name=cfResources["wafacl"].Name
                        metric=cfResources["wafacl"].Name
                        default=getWAFDefault(solution.WAF)
                        rules=getWAFRules(solution.WAF) /]
                [/#if]
            [/#if]

            [#assign customDomains = resources["customDomains"]!{} ]
            [#list customDomains as key,value]
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
                                "CertificateArn":
                                    getArn(value["domain"].CertificateId, true, "us-east-1")
                            },
                            isEdgeEndpointType,
                            {
                                "RegionalCertificateArn":
                                    getArn(value["domain"].CertificateId, true, regionId),
                                "EndpointConfiguration" : {
                                    "Types" : [endpointType]
                                }
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

                    [#switch alert.Comparison ]
                        [#case "Threshold" ]
                            [@createCountAlarm
                                mode=listMode
                                id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                                name=alert.Severity?upper_case + "-" + monitoredResource.Name!core.ShortFullName + "-" + alert.Name
                                actions=[
                                    getReference(formatSegmentSNSTopicId())
                                ]
                                metric=getMetricName(alert.Metric, monitoredResource.Type, occurrence)
                                namespace=getResourceMetricNamespace(monitoredResource)
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

            [#list resources.logMetrics as logMetricName,logMetric ]

                [@createLogMetric
                    mode=listMode
                    id=logMetric.Id
                    name=logMetric.Name
                    logGroup=logMetric.LogGroupName
                    filter=logFilters[logMetric.LogFilter].Pattern
                    namespace=getResourceMetricNamespace(logMetric)
                    value=1
                    dependencies=logMetric.LogGroupId
                /]

            [/#list]
        [/#if]

        [#assign docs = resources["docs"]!{} ]
        [#list docs as key,value]

            [#assign bucketId = value["bucket"].Id]
            [#assign bucketName = value["bucket"].Name]
            [#assign bucketRedirectTo = value["bucket"].RedirectTo]
            [#assign bucketPolicyId = value["policy"].Id ]

            [#assign bucketWebsiteConfiguration =
                getS3WebsiteConfiguration("index.html", "", bucketRedirectTo)]

            [#if deploymentSubsetRequired("prologue", false) && getExistingReference(bucketId)?has_content ]
                [#-- Clear out bucket content if deleting api gateway so buckets will delete --]
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

            [#if deploymentSubsetRequired("s3", true) && isPartOfCurrentDeploymentUnit(bucketId)]
                [#assign bucketWhitelist =
                    getIPCondition(
                        getGroupCIDRs(solution.Publish.IPAddressGroups)) ]

                [@createBucketPolicy
                    mode=listMode
                    id=bucketPolicyId
                    bucket=bucketName
                    statements=
                        s3ReadPermission(
                            bucketName,
                            "",
                            "*",
                            "*",
                            bucketWhitelist
                        )
                    dependencies=bucketId
                /]

                [@createS3Bucket
                    mode=listMode
                    id=bucketId
                    name=bucketName
                    websiteConfiguration=bucketWebsiteConfiguration
                /]
            [/#if]

            [#if deploymentSubsetRequired("epilogue", false) && (bucketRedirectTo == "") ]
                [@cfScript
                    mode=listMode
                    content=
                    [
                        "function get_apidoc_file() {",
                        "  #",
                        "  # Fetch the apidoc file",
                        "  copyFilesFromBucket" + " " +
                            regionId + " " +
                            getRegistryEndPoint("swagger", occurrence) + " " +
                            formatRelativePath(
                                getRegistryPrefix("swagger", occurrence) + productName,
                                getOccurrenceBuildUnit(occurrence),
                                getOccurrenceBuildReference(occurrence)) + " " +
                        "   \"$\{tmpdir}\" || return $?",
                        "  #",
                        "  # Insert host in Doc File ",
                        "  add_host_to_apidoc" + " " +
                        "\"" + attributes.FQDN + "\" " +
                        "\"" +  attributes.SCHEME + "\" " +
                        "\"" +  attributes.BASE_PATH + "\" " +
                        "\"" +  getOccurrenceBuildReference(occurrence) + "\" " +
                        "\"**COT Deployment:** " + core.TypedFullName + "\" " +
                        "\"$\{tmpdir}/apidoc.zip\"  || return $?",
                        "  # Sync to the API Doc bucket",
                        "  copy_apidoc_file" + " " + bucketName + " " +
                        "  \"$\{tmpdir}/apidoc.zip\" || return $?",
                        "}",
                        "#",
                        "case $\{STACK_OPERATION} in",
                        "  create|update)",
                        "    get_apidoc_file",
                        "    ;;",
                        "esac",
                        "#"
                    ]
                /]
            [/#if]
        [/#list]

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
