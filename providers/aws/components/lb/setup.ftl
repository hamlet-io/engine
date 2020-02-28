[#ftl]
[#macro aws_lb_cf_generationcontract_solution occurrence ]
    [@addDefaultGenerationContract subsets=["prologue", "template"] /]
[/#macro]

[#macro aws_lb_cf_setup_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]

    [#local lbId = resources["lb"].Id ]
    [#local lbName = resources["lb"].Name ]
    [#local lbShortName = resources["lb"].ShortName ]
    [#local lbLogs = solution.Logs ]
    [#local lbSecurityGroupIds = [] ]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "OpsData" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]) ]

    [#local occurrenceNetwork = getOccurrenceNetwork(occurrence) ]
    [#local networkLink = occurrenceNetwork.Link!{} ]

    [#local networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

    [#if ! networkLinkTarget?has_content ]
        [@fatal message="Network could not be found" context=networkLink /]
        [#return]
    [/#if]

    [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
    [#local networkResources = networkLinkTarget.State.Resources ]

    [#local vpcId = networkResources["vpc"].Id ]

    [#local routeTableLinkTarget = getLinkTarget(occurrence, networkLink + { "RouteTable" : occurrenceNetwork.RouteTable })]
    [#local routeTableConfiguration = routeTableLinkTarget.Configuration.Solution ]
    [#local publicRouteTable = routeTableConfiguration.Public ]

    [#local engine = solution.Engine]
    [#local idleTimeout = solution.IdleTimeout]

    [#local securityProfile = getSecurityProfile(solution.Profiles.Security, LB_COMPONENT_TYPE, engine)]

    [#local healthCheckPort = "" ]
    [#if engine == "classic" ]
        [#if solution.HealthCheckPort?has_content ]
            [#local healthCheckPort = ports[solution.HealthCheckPort]]
        [#else]
            [@precondition
                function="solution_lb"
                detail="No health check port provided"
            /]
        [/#if]
    [/#if]

    [#local portProtocols = [] ]
    [#local classicListeners = []]
    [#local ingressRules = [] ]
    [#local listenerPortsSeen = [] ]

    [#local classicPolicies = []]
    [#local classicStickinessPolicies = []]
    [#local classicConnectionDrainingTimeouts = []]

    [#local ruleCleanupScript = []]

    [#local classicHTTPSPolicyName = "ELBSecurityPolicy"]
    [#if engine == "classic" ]
        [#local classicPolicies += [
            {
                "PolicyName" : classicHTTPSPolicyName,
                "PolicyType" : "SSLNegotiationPolicyType",
                "Attributes" : [{
                    "Name"  : "Reference-Security-Policy",
                    "Value" : securityProfile.HTTPSProfile
                }]
            }
        ]]
    [/#if]

    [#-- LB level Alerts --]
    [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
        [#list solution.Alerts?values as alert ]

            [#local monitoredResources = getMonitoredResources(core.Id, resources, alert.Resource)]
            [#list monitoredResources as name,monitoredResource ]

                [@debug message="Monitored resource" context=monitoredResource enabled=false /]

                [#switch alert.Comparison ]
                    [#case "Threshold" ]
                        [@createAlarm
                            id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                            severity=alert.Severity
                            resourceName=core.FullName
                            alertName=alert.Name
                            actions=getCWAlertActions(occurrence, solution.Profiles.Alert, alert.Severity )
                            metric=getMetricName(alert.Metric, monitoredResource.Type, core.ShortFullName)
                            namespace=getResourceMetricNamespace(monitoredResource.Type, alert.Namespace)
                            description=alert.Description!alert.Name
                            threshold=alert.Threshold
                            statistic=alert.Statistic
                            evaluationPeriods=alert.Periods
                            period=alert.Time
                            operator=alert.Operator
                            reportOK=alert.ReportOk
                            unit=alert.Unit
                            missingData=alert.MissingData
                            dimensions=getResourceMetricDimensions(monitoredResource, resources)
                        /]
                    [#break]
                [/#switch]
            [/#list]
        [/#list]
    [/#if]


    [#list solution.Links?values as link]
        [#if link?is_hash]

            [#local linkTarget = getLinkTarget(occurrence, link) ]
            [@debug message="Link Target" context=linkTarget enabled=false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]

            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetConfiguration = linkTarget.Configuration ]
            [#local linkTargetResources = linkTarget.State.Resources ]
            [#local linkTargetAttributes = linkTarget.State.Attributes ]

            [#switch linkTargetCore.Type]
                [#case SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE ]
                    [#local registryServiceId = linkTargetResources["service"].Id ]
                    [#local instanceAttributes = getCloudMapInstanceAttribute(
                                                    "alias",
                                                    getExistingReference(lbId, DNS_ATTRIBUTE_TYPE) )]

                    [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                        [#local cloudMapInstanceId = formatDependentResourceId(
                                                            AWS_CLOUDMAP_INSTANCE_RESOURCE_TYPE, lbId, registryServiceId)]
                        [@createCloudMapInstance
                            id=cloudMapInstanceId
                            serviceId=registryServiceId
                            instanceId=core.ShortName
                            instanceAttributes=instanceAttributes
                        /]
                    [/#if]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]

    [#list occurrence.Occurrences![] as subOccurrence]

        [#local core = subOccurrence.Core ]
        [#local solution = subOccurrence.Configuration.Solution ]
        [#local resources = subOccurrence.State.Resources ]

        [#-- Determine if this is the first mapping for the source port --]
        [#-- The assumption is that all mappings for a given port share --]
        [#-- the same listenerId, so the same port number shouldn't be  --]
        [#-- defined with different names --]
        [#local listenerId = resources["listener"].Id ]
        [#local defaultTargetGroupId = resources["defaulttg"].Id]
        [#local defaultTargetGroupName = resources["defaulttg"].Name]

        [#local cliCleanUpRequired = getExistingReference(listenerId, "cleanup")?has_content ]

        [#local firstMappingForPort = !listenerPortsSeen?seq_contains(listenerId) ]
        [#switch engine ]
            [#case "application"]
                [#if solution.Path != "default" ]
                    [#-- Only create the listener for default mappings      --]
                    [#-- The ordering of ports changes with their naming    --]
                    [#-- so it isn't sufficient to use the first occurrence --]
                    [#-- of a listener                                      --]
                    [#local firstMappingForPort = false ]
                [/#if]
                [#break]
        [/#switch]
        [#if firstMappingForPort]
            [#local listenerPortsSeen += [listenerId] ]
        [/#if]

        [#-- Determine the IP whitelisting required --]
        [#local portIpAddressGroups = solution.IPAddressGroups ]
        [#if !solution.IPAddressGroups?seq_contains("_localnet") && !publicRouteTable ]
            [#local portIpAddressGroups += [ "_localnet"] ]
        [/#if]
        [#local cidrs = getGroupCIDRs(portIpAddressGroups, true, subOccurrence)]
        [#local securityGroupId = resources["sg"].Id]
        [#local securityGroupName = resources["sg"].Name]

        [#-- Check source and destination ports --]
        [#local mapping = solution.Mapping!core.SubComponent.Name ]
        [#local source = (portMappings[mapping].Source)!"" ]
        [#local destination = (portMappings[mapping].Destination)!"" ]
        [#local sourcePort = (ports[source])!{} ]
        [#local destinationPort = (ports[destination])!{} ]

        [#local sourcePortId = sourcePort.Id!source ]
        [#local sourcePortName = sourcePort.Name!source ]

        [#if !(sourcePort?has_content && destinationPort?has_content)]
            [#continue ]
        [/#if]
        [#local portProtocols += [ sourcePort.Protocol ] ]
        [#local portProtocols += [ destinationPort.Protocol] ]

        [#-- forwarding attributes --]
        [#local tgAttributes = {}]
        [#local classicConnectionDrainingTimeouts += [ solution.Forward.DeregistrationTimeout ]]

        [#-- Rule setup --]
        [#local targetGroupId = resources["targetgroup"].Id]
        [#local targetGroupName = resources["targetgroup"].Name]
        [#local targetGroupRequired = true ]

        [#local listenerRuleId = resources["listenerRule"].Id ]
        [#local listenerRulePriority = resources["listenerRule"].Priority ]

        [#local listenerForwardRule = true]

        [#local listenerRuleActions = [] ]

        [#-- Path processing --]
        [#switch engine ]
            [#case "application"]
                [#if solution.Path == "default" ]
                    [#local path = "*"]
                [#else]
                    [#if solution.Path?ends_with("/") && solution.Path != "/" ]
                        [#local path = solution.Path?ensure_ends_with("*")]
                    [#else]
                        [#local path = solution.Path ]
                    [/#if]
                [/#if]
                [#break]

            [#default]
                [#local path = "" ]
                [#break]
        [/#switch]
        [#local listenerRuleConditions = getListenerRulePathCondition(path) ]

        [#-- Certificate details if required --]
        [#local certificateObject = getCertificateObject(solution.Certificate, segmentQualifiers, sourcePortId, sourcePortName) ]
        [#local hostName = getHostName(certificateObject, subOccurrence) ]
        [#local primaryDomainObject = getCertificatePrimaryDomain(certificateObject) ]
        [#local certificateId = formatDomainCertificateId(certificateObject, hostName) ]

        [#if engine == "application" ]
            [#-- FQDN processing --]
            [#if solution.HostFilter ]
                [#local fqdn = formatDomainName(hostName, primaryDomainObject)]

                [#list resources["domainRedirectRules"]!{} as key, rule]

                    [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                        [@createListenerRule
                            id=rule.Id
                            listenerId=listenerId
                            actions=getListenerRuleRedirectAction(
                                    "#\{protocol}",
                                    "#\{port}",
                                    fqdn,
                                    "#\{path}",
                                    "#\{query}")
                            conditions=getListenerRuleHostCondition(rule.RedirectFrom)
                            priority=rule.Priority
                            dependencies=listenerId
                        /]
                    [/#if]

                [/#list]

                [#local listenerRuleConditions += getListenerRuleHostCondition(fqdn) ]
            [/#if]

            [#-- Redirect rule processing --]
            [#if isPresent(solution.Redirect) ]
                [#local targetGroupRequired = false ]
                [#local listenerForwardRule = false ]

                [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                    [@createListenerRule
                        id=listenerRuleId
                        listenerId=listenerId
                        actions=getListenerRuleRedirectAction(
                                        solution.Redirect.Protocol,
                                        solution.Redirect.Port,
                                        solution.Redirect.Host,
                                        solution.Redirect.Path,
                                        solution.Redirect.Query,
                                        solution.Redirect.Permanent)
                        conditions=listenerRuleConditions
                        priority=listenerRulePriority
                        dependencies=listenerId
                    /]
                [/#if]
            [/#if]

            [#-- Fixed rule processing --]
            [#if isPresent(solution.Fixed) ]
                [#local targetGroupRequired = false ]
                [#local listenerForwardRule = false ]
                [#local fixedMessage = getOccurrenceSettingValue(subOccurrence, ["Fixed", "Message"], true) ]
                [#local fixedContentType = getOccurrenceSettingValue(subOccurrence, ["Fixed", "ContentType"], true) ]
                [#local fixedStatusCode = getOccurrenceSettingValue(subOccurrence, ["Fixed", "StatusCode"], true) ]
                    [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                        [@createListenerRule
                            id=listenerRuleId
                            listenerId=listenerId
                            actions=getListenerRuleFixedAction(
                                    contentIfContent(
                                        fixedMessage,
                                        solution.Fixed.Message),
                                    contentIfContent(
                                        fixedContentType,
                                        solution.Fixed.ContentType),
                                    contentIfContent(
                                        fixedStatusCode,
                                        solution.Fixed.StatusCode))
                            conditions=listenerRuleConditions
                            priority=listenerRulePriority
                            dependencies=listenerId
                        /]
                [/#if]
            [/#if]
        [/#if]

        [#-- Use presence of links to determine rule required --]
        [#-- More than one link is an error --]
        [#local linkCount = 0 ]
        [#list solution.Links?values as link]
            [#if link?is_hash]
                [#local linkCount += 1 ]
                [#if linkCount > 1 ]
                    [@fatal
                        message="A port mapping can only have a maximum of one link"
                        context=subOccurrence
                    /]
                    [#continue]
                [/#if]

                [#local linkTarget = getLinkTarget(occurrence, link) ]

                [@debug message="Link Target" context=linkTarget enabled=false /]

                [#if !linkTarget?has_content]
                    [#continue]
                [/#if]

                [#local linkTargetCore = linkTarget.Core ]
                [#local linkTargetConfiguration = linkTarget.Configuration ]
                [#local linkTargetResources = linkTarget.State.Resources ]
                [#local linkTargetAttributes = linkTarget.State.Attributes ]

                [#switch linkTargetCore.Type]

                    [#case USERPOOL_COMPONENT_TYPE]
                    [#case USERPOOL_CLIENT_COMPONENT_TYPE]
                    [#case "external" ]
                        [#local cognitoIntegration = true ]
                        [#local listenerForwardRule = false ]

                        [#local userPoolSessionCookieName = solution.Authentication.SessionCookieName ]
                        [#local userPoolSessionTimeout = solution.Authentication.SessionTimeout ]

                        [#local userPoolDomain = linkTargetAttributes["UI_FQDN"]!"COTFatal: Userpool FQDN not found" ]
                        [#local userPoolArn = linkTargetAttributes["USER_POOL_ARN"]!"COTFatal: Userpool ARN not found" ]
                        [#local userPoolClientId = linkTargetAttributes["CLIENT"]!"COTFatal: Userpool client id not found"  ]
                        [#local userPoolOauthScope = linkTargetAttributes["LB_OAUTH_SCOPE"]!"COTFatal: Userpool OAuth scope not found"  ]

                        [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) && engine == "application" ]
                            [@createListenerRule
                                id=listenerRuleId
                                listenerId=listenerId
                                actions=getListenerRuleAuthCognitoAction(
                                                    userPoolArn,
                                                    userPoolClientId,
                                                    userPoolDomain,
                                                    userPoolSessionCookieName,
                                                    userPoolSessionTimeout,
                                                    userPoolOauthScope,
                                                    1
                                            ) +
                                        getListenerRuleForwardAction(targetGroupId, 2)
                                conditions=listenerRuleConditions
                                priority=listenerRulePriority
                                dependencies=listenerId
                            /]
                        [/#if]
                        [#break]

                    [#case SPA_COMPONENT_TYPE]
                        [#local targetGroupRequired = false ]
                        [#local listenerForwardRule = false ]
                        [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) && engine == "application"  ]
                            [@createListenerRule
                                id=listenerRuleId
                                listenerId=listenerId
                                actions=getListenerRuleRedirectAction(
                                            "HTTPS",
                                            "443",
                                            linkTargetAttributes.FQDN,
                                            "",
                                            "",
                                            false)
                                conditions=listenerRuleConditions
                                priority=listenerRulePriority
                                dependencies=listenerId
                            /]
                        [/#if]
                        [#break]
                [/#switch]
            [/#if]
        [/#list]

        [#-- Create the security group for the listener --]
        [#switch engine ]
            [#case "application"]
            [#case "classic"]
                [#if firstMappingForPort &&
                    deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                    [@createSecurityGroup
                        id=securityGroupId
                        name=securityGroupName
                        occurrence=occurrence
                        ingressRules=[ {"Port" : sourcePort.Port, "CIDR" : cidrs} ]
                        egressRules=[ { "Port" : "any",  "CIDR" : "0.0.0.0/0" }]
                        vpcId=vpcId
                    /]

                [/#if]
                [#break]
        [/#switch]

        [#-- Process the mapping --]
        [#switch engine ]
            [#case "application"]
                [#local tgAttributes +=
                    (solution.Forward.StickinessTime > 0)?then(
                        {
                            "stickiness.enabled" : true,
                            "stickiness.type" : "lb_cookie",
                            "stickiness.lb_cookie.duration_seconds" : solution.Forward.StickinessTime
                        },
                        {}
                    ) +
                    (solution.Forward.SlowStartTime > 0)?then(
                        {
                            "slow_start.duration_seconds" : solution.Forward.SlowStartTime
                        },
                        {}
                    )]

                [#if firstMappingForPort ]
                    [#if getExistingReference(listenerId)?has_content && ! getExistingReference(listenerRuleId)?has_content ]
                        [#local ruleCleanupScript += [
                                "cleanup_elbv2_rules" +
                                "       \"" + region + "\" " +
                                "       \"" + getExistingReference(listenerId, ARN_ATTRIBUTE_TYPE) + "\" "
                            ]]
                    [/#if]
                [/#if]

                [#-- Basic Forwarding --]
                [#if listenerForwardRule ]
                    [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                            [@createListenerRule
                                id=listenerRuleId
                                listenerId=listenerId
                                actions=getListenerRuleForwardAction(targetGroupId)
                                conditions=listenerRuleConditions
                                priority=listenerRulePriority
                                dependencies=listenerId
                            /]
                    [/#if]
                [/#if]

            [#case "network"]
                [#local tgAttributes +=
                    {
                        "deregistration_delay.timeout_seconds" : solution.Forward.DeregistrationTimeout
                    }]

                [#if firstMappingForPort ]

                    [#local lbSecurityGroupIds += [securityGroupId] ]
                    [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                        [@createALBListener
                            id=listenerId
                            port=sourcePort
                            albId=lbId
                            defaultTargetGroupId=defaultTargetGroupId
                            certificateId=certificateId
                            sslPolicy=securityProfile.HTTPSProfile
                        /]

                        [@createTargetGroup
                            id=defaultTargetGroupId
                            name=defaultTargetGroupName
                            tier=core.Tier
                            component=core.Component
                            destination=destinationPort
                            attributes=tgAttributes
                            targetType=solution.Forward.TargetType
                            vpcId=vpcId
                        /]
                    [/#if]
                [/#if]

                [#if ( targetGroupRequired ) &&
                    ( engine == "application" ) &&
                    deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]

                    [@createTargetGroup
                        id=targetGroupId
                        name=targetGroupName
                        tier=core.Tier
                        component=core.Component
                        destination=destinationPort
                        attributes=tgAttributes
                        targetType=solution.Forward.TargetType
                        vpcId=vpcId
                            /]
                [/#if]

                [#break]

            [#case "classic"]
                [#if firstMappingForPort ]
                    [#local lbSecurityGroupIds += [securityGroupId] ]
                    [#local classicListenerPolicyNames = []]
                    [#local classicSSLRequired = sourcePort.Certificate!false ]

                    [#if classicSSLRequired ]
                        [#local classicListenerPolicyNames += [
                            classicHTTPSPolicyName
                        ]]
                    [/#if]

                    [#if solution.Forward.StickinessTime > 0 ]
                        [#local stickinessPolicyName = formatName(core.Name, "sticky") ]
                        [#local classicListenerPolicyNames += [ stickinessPolicyName ]]
                        [#local classicStickinessPolicies += [
                            {
                                "PolicyName" : stickinessPolicyName,
                                "CookieExpirationPeriod" : solution.Forward.StickinessTime
                            }
                        ]]
                    [/#if]

                    [#local classicListeners +=
                        [
                            {
                                "LoadBalancerPort" : sourcePort.Port,
                                "Protocol" : sourcePort.Protocol,
                                "InstancePort" : destinationPort.Port,
                                "InstanceProtocol" : destinationPort.Protocol
                            }  +
                            attributeIfTrue(
                                "SSLCertificateId",
                                classicSSLRequired,
                                getReference(certificateId, ARN_ATTRIBUTE_TYPE, regionId)
                            ) +
                            attributeIfContent(
                                "PolicyNames",
                                classicListenerPolicyNames
                            )
                        ]
                    ]
                [/#if]
                [#break]
        [/#switch]
    [/#list]

    [#if deploymentSubsetRequired("prologue", false) && !cliCleanUpRequired ]

        [@addToDefaultBashScriptOutput
            content=
                [
                    "case $\{STACK_OPERATION} in",
                    "  create|update)",
                    "    # Apply CLI level updates to ELB listener",
                    "    info \"Removing rules created by cli rules\""
                ] +
                ruleCleanupScript +
                pseudoStackOutputScript(
                    "CLI Rule Cleanup",
                    {
                        formatId(listenerId, "cleanup") : true?c
                    }
                ) +
                [
                    "    ;;",
                    "esac"
                ]
        /]
    [/#if]

    [#-- Port Protocol Validation --]
    [#local InvalidProtocol = false]
    [#switch engine ]
        [#case "network" ]
            [#if portProtocols?seq_contains("HTTP") || portProtocols?seq_contains("HTTPS") ]
                [#local InvalidProtocol = true]
            [/#if]
            [#break]
        [#case "application" ]
            [#if portProtocols?seq_contains("TCP") ]
                [#local InvalidProtocol = true]
            [/#if]
            [#break]
    [/#switch]

    [#if InvalidProtocol ]
            [@fatal
                message="Invalid protocol found for engine type"
                context=
                    {
                        "LB" : lbName,
                        "Engine" : engine,
                        "Protocols" : portProtocols
                    }
            /]
    [/#if]

    [#switch engine ]
        [#case "network"]
        [#case "application"]

            [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                [@createALB
                    id=lbId
                    name=lbName
                    shortName=lbShortName
                    tier=core.Tier
                    component=core.Component
                    securityGroups=lbSecurityGroupIds
                    networkResources=networkResources
                    publicEndpoint=publicRouteTable
                    logs=lbLogs
                    type=engine
                    bucket=operationsBucket
                    idleTimeout=idleTimeout /]
            [/#if]
            [#break]

        [#case "classic"]

            [#local healthCheck = {
                "Target" : healthCheckPort.HealthCheck.Protocol!healthCheckPort.Protocol + ":"
                            + (healthCheckPort.HealthCheck.Port!healthCheckPort.Port)?c + healthCheckPort.HealthCheck.Path!"",
                "HealthyThreshold" : healthCheckPort.HealthCheck.HealthyThreshold,
                "UnhealthyThreshold" : healthCheckPort.HealthCheck.UnhealthyThreshold,
                "Interval" : healthCheckPort.HealthCheck.Interval,
                "Timeout" : healthCheckPort.HealthCheck.Timeout
            }]

            [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                [@createClassicLB
                    id=lbId
                    name=lbName
                    shortName=lbShortName
                    tier=core.Tier
                    component=core.Component
                    listeners=classicListeners
                    healthCheck=healthCheck
                    securityGroups=lbSecurityGroupIds
                    networkResources=networkResources
                    publicEndpoint=publicRouteTable
                    logs=lbLogs
                    bucket=operationsBucket
                    idleTimeout=idleTimeout
                    deregistrationTimeout=(classicConnectionDrainingTimeouts?reverse)[0]
                    stickinessPolicies=classicStickinessPolicies
                    policies=classicPolicies
                    /]
            [/#if]
            [#break]
    [/#switch ]
[/#macro]
