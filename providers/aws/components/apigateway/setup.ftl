[#ftl]
[#macro aws_apigateway_cf_application occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets=["pregeneration", "prologue", "template", "epilogue", "config"] /]
        [#return]
    [/#if]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]
    [#local attributes = occurrence.State.Attributes ]
    [#local buildSettings = occurrence.Configuration.Settings.Build ]
    [#local roles = occurrence.State.Roles]

    [#local apiId      = resources["apigateway"].Id]
    [#local apiName    = resources["apigateway"].Name]

    [#-- Use runId to ensure deploy happens every time --]
    [#local deployId   = resources["apideploy"].Id]
    [#local stageId    = resources["apistage"].Id]
    [#local stageName  = resources["apistage"].Name]

    [#-- Determine the stage variables required --]
    [#local stageVariables = {} ]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]

    [#local swaggerFileName ="swagger_" + runId + ".json"  ]
    [#local swaggerFileLocation = formatRelativePath(
                                                getSettingsFilePrefix(occurrence),
                                                "config",
                                                swaggerFileName)]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(solution.Profiles.Baseline, [ "OpsData", "AppData" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]) ]
    [#local dataBucket = getExistingReference(baselineComponentIds["AppData"])]

    [#local contextLinks = getLinkTargets(occurrence) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks, baselineLinks),
            "Environment" : {},
            "Links" : contextLinks,
            "BaselineLinks" : baselineLinks,
            "DefaultCoreVariables" : false,
            "DefaultBaselineVariables" : false,
            "DefaultEnvironmentVariables" : false,
            "DefaultLinkVariables" : false,
            "Policy" : []
        }
    ]

    [#-- Add in fragment specifics including override of defaults --]
    [#if solution.Fragment?has_content ]
        [#local fragmentId = formatFragmentId(_context)]
        [#include fragmentList?ensure_starts_with("/")]
    [/#if]

    [#local stageVariables += getFinalEnvironment(occurrence, _context ).Environment ]

    [#local cognitoPools = {} ]

    [#list solution.Links?values as link]
        [#if link?is_hash]
            [#local linkTarget = getLinkTarget(occurrence, link, false) ]

            [@debug message="Link Target" context=linkTarget enabled=false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]

            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetConfiguration = linkTarget.Configuration ]
            [#local linkTargetResources = linkTarget.State.Resources ]
            [#local linkTargetAttributes = linkTarget.State.Attributes ]

            [#switch linkTargetCore.Type]
                [#case LB_COMPONENT_TYPE ]
                    [#if isLinkTargetActive(linkTarget) ]
                        [#local stageVariables +=
                            {
                                formatSettingName(link.Name, "DOCKER") : linkTargetAttributes.FQDN
                            }
                        ]
                    [/#if]
                    [#break]

                [#case LAMBDA_FUNCTION_COMPONENT_TYPE]
                    [#-- Add function even if it isn't active so APi gateway if fully configured --]
                    [#-- even if lambda have yet to be deployed                                  --]
                    [#local stageVariables +=
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
                        [#local cognitoPools +=
                            {
                                link.Name : {
                                    "Name" : link.Name,
                                    "Header" : linkTargetAttributes["API_AUTHORIZATION_HEADER"],
                                    "UserPoolArn" : linkTargetAttributes["USER_POOL_ARN"],
                                    "Default" : true
                                }
                            } ]
                    [/#if]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]

    [#local endpointType           = solution.EndpointType ]
    [#local isRegionalEndpointType = endpointType == "REGIONAL" ]

    [#local securityProfile        = getSecurityProfile(solution.Profiles.Security, "apigateway")]

    [#local wafAclResources        = resources["wafacl"]!{} ]
    [#local cfResources            = resources["cf"]!{} ]
    [#local customDomainResources  = resources["customDomains"]!{} ]

    [#local apiPolicyStatements    = _context.Policy ]
    [#local apiPolicyAuth          = solution.Authentication?upper_case ]

    [#local apiPolicyCidr          = getGroupCIDRs(solution.IPAddressGroups) ]
    [#if (!(wafAclResources?has_content)) && (!(apiPolicyCidr?has_content)) ]
        [@fatal
            message="No IP Address Groups provided for API Gateway"
            context=occurrence
        /]
        [#return]
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
    [#local apiPolicyStatements +=
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
                [#local apiPolicyStatements +=
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
                [#local apiPolicyStatements +=
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
                [#local apiPolicyStatements +=
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
        [#local apiPolicyStatements +=
            [
                getPolicyStatement(
                    "execute-api:Invoke",
                    "execute-api:/*",
                    "*"
                )
            ] ]
    [/#if]

    [#local accessLgId   = resources["accesslg"].Id]
    [#local accessLgName = resources["accesslg"].Name]
    [#if deploymentSubsetRequired("lg", true) && isPartOfCurrentDeploymentUnit(accessLgId) ]
        [@createLogGroup
            id=accessLgId
            name=accessLgName /]
    [/#if]

    [#if deploymentSubsetRequired("apigateway", true)]
        [#-- Assume extended swagger specification is in the ops bucket --]
        [@cfResource
            id=apiId
            type="AWS::ApiGateway::RestApi"
            properties=
                {
                    "BodyS3Location" : {
                        "Bucket" : operationsBucket,
                        "Key" : swaggerFileLocation
                    },
                    "Name" : apiName,
                    "Parameters" : {
                        "basepath" : solution.BasePathBehaviour
                    }
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
            [#local origin =
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
            [#local defaultCacheBehaviour =
                getCFAPIGatewayCacheBehaviour(
                    origin,
                    solution.CloudFront.CustomHeaders +
                        valueIfTrue(
                            ["Host"],
                            endpointType == "REGIONAL",
                            []
                        ),
                    solution.CloudFront.Compress) ]
            [#local restrictions = {} ]
            [#if solution.CloudFront.CountryGroups?has_content]
                [#list asArray(solution.CloudFront.CountryGroups) as countryGroup]
                    [#local group = (countryGroups[countryGroup])!{}]
                    [#if group.Locations?has_content]
                        [#local restrictions +=
                            getCFGeoRestriction(group.Locations, group.Blacklist!false) ]
                        [#break]
                    [/#if]
                [/#list]
            [/#if]
            [@createCFDistribution
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
                            core.Tier,
                            core.Component,
                            occurrence
                        )
                    ),
                    solution.CloudFront.EnableLogging)
                origins=origin
                restrictions=restrictions
                wafAclId=(wafAclResources.acl.Id)!""
            /]
            [@createAPIUsagePlan
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

            [#local monitoredResources = getMonitoredResources(resources, alert.Resource)]
            [#list monitoredResources as name,monitoredResource ]

                [@debug message="Monitored resource" context=monitoredResource enabled=false /]

                [#switch alert.Comparison ]
                    [#case "Threshold" ]
                        [@createCountAlarm
                            id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                            severity=alert.Severity
                            resourceName=core.FullName
                            alertName=alert.Name
                            actions=getCWAlertActions(occurrence, solution.Profiles.Alert, alert.Severity )
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
    [#local docs = resources["docs"]!{} ]
    [#list docs as key,value]

        [#local bucketName = value["bucket"].Name]
        [#if deploymentSubsetRequired("prologue", false)  ]
            [#-- Clear out bucket content if deleting api gateway so buckets will delete --]
            [#if getExistingReference(bucketId)?has_content ]
                [@addToDefaultBashScriptOutput
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

            [@addToDefaultBashScriptOutput
                content=
                    [
                        "error \" API Docs publishing has been deprecated \"",
                        "error \" Please remove the Publish configuration from your API Gateway\"",
                        "error \" API Publishers are now available to provide documentation publishing\""
                    ]
            /]
        [/#if]
    [/#list]

    [#-- Send API Specification to an external publisher --]
     
    [#if solution.Publishers?has_content ]
        [#if deploymentSubsetRequired("epilogue", false ) ]
            [@addToDefaultBashScriptOutput
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
                    "   ;;",
                    " esac"
                ]
            /]
        [/#if]

        [#list solution.Publishers as id,publisher ]

            [#local publisherLinks = getLinkTargets(occurrence, publisher.Links )]

            [#local publisherPath = getContentPath( occurrence, publisher.Path )]
            [#if publisher.UsePathInName ]
                [#local fileName = formatName( publisherPath, "swagger.json") ]
                [#local publisherPath = "" ]
            [#else]
                [#local fileName = "swagger.json" ]
            [/#if]
            
            [#list publisherLinks as publisherLinkId, publisherLinkTarget ]
                [#local publisherLinkTargetCore = publisherLinkTarget.Core ]
                [#local publisherLinkTargetAttributes = publisherLinkTarget.State.Attributes ]

                [#switch publisherLinkTargetCore.Type ]
                    [#case CONTENTHUB_HUB_COMPONENT_TYPE ]
                        [#if deploymentSubsetRequired("epilogue", false ) ]
                            [@addToDefaultBashScriptOutput
                                content=
                                [
                                    "case $\{STACK_OPERATION} in",
                                    "  create|update)",
                                    "info \"Sending API Specification to " + id + "-" + publisherLinkTargetCore.FullName + "\"",
                                    " cp \"$\{tmpdir}/" + swaggerFileName + "\" \"$\{tmpdir}/" + fileName + "\" ",
                                    "  copy_contentnode_file \"$\{tmpdir}/" + fileName + "\" " +
                                    "\"" +    publisherLinkTargetAttributes.ENGINE + "\" " +
                                    "\"" +    publisherLinkTargetAttributes.REPOSITORY + "\" " +
                                    "\"" +    publisherLinkTargetAttributes.PREFIX + "\" " +
                                    "\"" +    publisherPath + "\" " +
                                    "\"" +    publisherLinkTargetAttributes.BRANCH + "\" " +
                                    "\"update\" || return $? ",
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

    [#local legacyId = formatS3Id(core.Id, APIGATEWAY_COMPONENT_DOCS_EXTENSION) ]
    [#if getExistingReference(legacyId)?has_content && deploymentSubsetRequired("prologue", false) ]
        [#-- Remove legacy docs bucket id - it will likely be recreated with new id format --]
        [#-- which uses bucket name --]
        [@addToDefaultBashScriptOutput
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
        [@addToDefaultBashScriptOutput
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
        [#local swaggerDefinition = definitionsObject[core.Id] ]
        [#if swaggerDefinition["x-amazon-apigateway-request-validator"]?? ]
            [#-- Pass definition through - it is legacy and has already has been processed --]
            [#local extendedSwaggerDefinition = swaggerDefinition ]
        [#else]
            [#local swaggerIntegrations = getOccurrenceSettingValue(occurrence, [["apigw"], ["Integrations"]], true) ]
            [#if !swaggerIntegrations?has_content]
                [@fatal
                    message="API Gateway integration definitions not found"
                    context=occurrence
                /]
                [#local swaggerIntegrations = {} ]
            [/#if]
            [#if swaggerIntegrations?is_hash]
                [#local swaggerContext =
                    {
                        "Account" : accountObject.AWSId,
                        "Region" : region,
                        "CognitoPools" : cognitoPools,
                        "FQDN" : attributes["FQDN"],
                        "Scheme" : attributes["SCHEME"],
                        "BasePath" : attributes["BASE_PATH"],
                        "BuildReference" : (buildSettings["APP_REFERENCE"].Value)!buildSettings["BUILD_REFERENCE"].Value,
                        "Name" : apiName
                    } ]

                [#-- Determine if there are any roles required by specific methods --]
                [#local extendedSwaggerRoles = getSwaggerDefinitionRoles(swaggerDefinition, swaggerIntegrations) ]
                [#list extendedSwaggerRoles as path,policies]
                    [#local swaggerRoleId = formatDependentRoleId(stageId, formatId(path))]
                    [#-- Roles must be defined in a separate unit so the ARNs are available here --]
                    [#if deploymentSubsetRequired("iam", false)  &&
                        isPartOfCurrentDeploymentUnit(swaggerRoleId)]
                        [@createRole
                            id=swaggerRoleId
                            trustedServices="apigateway.amazonaws.com"
                            policies=policies
                        /]
                    [/#if]
                    [#local swaggerContext +=
                        {
                            formatAbsolutePath(path,"rolearn") : getArn(swaggerRoleId, true)
                        } ]
                [/#list]

                [#-- Generate the extended swagger specification --]
                [#local extendedSwaggerDefinition =
                    extendSwaggerDefinition(
                        swaggerDefinition,
                        swaggerIntegrations,
                        swaggerContext,
                        true) ]

            [#else]
                [#local extendedSwaggerDefinition = {} ]
                [@fatal
                    message="API Gateway integration definitions should be a hash"
                    context={ "Integrations" : swaggerIntegrations}
                /]
            [/#if]
        [/#if]

        [#if extendedSwaggerDefinition?has_content]
            [#if deploymentSubsetRequired("config", false)]
                [@addToDefaultJsonOutput content=extendedSwaggerDefinition /]
            [/#if]
        [/#if]
    [/#if]

    [#if deploymentSubsetRequired("prologue", false)]
        [#-- Copy the final swagger definition to the ops bucket --]
        [@addToDefaultBashScriptOutput
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
[/#macro]
