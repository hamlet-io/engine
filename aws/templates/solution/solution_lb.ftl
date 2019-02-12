[#-- LB --]
[#if (componentType == LB_COMPONENT_TYPE) ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#assign lbId = resources["lb"].Id ]
        [#assign lbName = resources["lb"].Name ]
        [#assign lbShortName = resources["lb"].ShortName ]
        [#assign lbLogs = solution.Logs ]
        [#assign lbSecurityGroupIds = [] ]

        [#assign engine = solution.Engine]
        [#assign idleTimeout = solution.IdleTimeout]

        [#assign securityProfile = getSecurityProfile(solution.Profiles.Security, LB_COMPONENT_TYPE, engine)]

        [#assign healthCheckPort = "" ]
        [#if engine == "classic" ]
            [#if solution.HealthCheckPort?has_content ]
                [#assign healthCheckPort = ports[solution.HealthCheckPort]]
            [#else]
                [@cfPreconditionFailed listMode "solution_lb" {} "No health check port provided" /]
            [/#if]
        [/#if]

        [#assign portProtocols = [] ]
        [#assign classicListeners = []]
        [#assign ingressRules = [] ]
        [#assign listenerPortsSeen = [] ]

        [#assign classicPolicies = []]
        [#assign classicStickinessPolicies = []]
        [#assign classicConnectionDrainingTimeouts = []]

        [#assign ruleCleanupScript = []]

        [#assign classicHTTPSPolicyName = "ELBSecurityPolicy"]
        [#if engine == "classic" ]
            [#assign classicPolicies += [
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
        [/#if]

        [#list occurrence.Occurrences![] as subOccurrence]

            [#assign core = subOccurrence.Core ]
            [#assign solution = subOccurrence.Configuration.Solution ]
            [#assign resources = subOccurrence.State.Resources ]

            [#-- Determine if this is the first mapping for the source port --]
            [#-- The assumption is that all mappings for a given port share --]
            [#-- the same listenerId, so the same port number shouldn't be  --]
            [#-- defined with different names --]
            [#assign listenerId = resources["listener"].Id ]
            [#assign defaultTargetGroupId = resources["defaulttg"].Id]
            [#assign defaultTargetGroupName = resources["defaulttg"].Name]

            [#assign cliCleanUpRequired = getExistingReference(listenerId, "cleanup")?has_content ]

            [#assign firstMappingForPort = !listenerPortsSeen?seq_contains(listenerId) ]
            [#switch engine ]
                [#case "application"]
                    [#if solution.Path != "default" ]
                        [#-- Only create the listener for default mappings      --]
                        [#-- The ordering of ports changes with their naming    --]
                        [#-- so it isn't sufficient to use the first occurrence --]
                        [#-- of a listener                                      --]
                        [#assign firstMappingForPort = false ]
                    [/#if]
                    [#break]
            [/#switch]
            [#if firstMappingForPort]
                [#assign listenerPortsSeen += [listenerId] ]
            [/#if]

            [#-- Determine the IP whitelisting required --]
            [#assign portIpAddressGroups = solution.IPAddressGroups ]
            [#if !solution.IPAddressGroups?seq_contains("_localnet") && tier.Network.RouteTable != "external" ]
                [#assign portIpAddressGroups += [ "_localnet"] ]
            [/#if]
            [#assign cidrs = getGroupCIDRs(portIpAddressGroups)]
            [#assign securityGroupId = resources["sg"].Id]
            [#assign securityGroupName = resources["sg"].Name]

            [#-- Check source and destination ports --]
            [#assign mapping = solution.Mapping!core.SubComponent.Name ]
            [#assign source = (portMappings[mapping].Source)!"" ]
            [#assign destination = (portMappings[mapping].Destination)!"" ]
            [#assign sourcePort = (ports[source])!{} ]
            [#assign destinationPort = (ports[destination])!{} ]

            [#if !(sourcePort?has_content && destinationPort?has_content)]
                [#continue ]
            [/#if]
            [#assign portProtocols += [ sourcePort.Protocol ] ]
            [#assign portProtocols += [ destinationPort.Protocol] ]

            [#-- forwarding attributes --]
            [#assign tgAttributes = {}]
            [#assign classicConnectionDrainingTimeouts += [ solution.Forward.DeregistrationTimeout ]]

            [#-- Rule setup --]
            [#assign targetGroupId = resources["targetgroup"].Id]
            [#assign targetGroupName = resources["targetgroup"].Name]
            [#assign targetGroupRequired = true ]

            [#assign listenerRuleId = resources["listenerRule"].Id ]
            [#assign listenerRulePriority = resources["listenerRule"].Priority ]

            [#assign listenerForwardRule = true]

            [#assign listenerRuleActions = [] ]

            [#-- Path processing --]
            [#switch engine ]
                [#case "application"]
                    [#if solution.Path == "default" ]
                        [#assign path = "*"]
                    [#else]
                        [#if solution.Path?ends_with("/")]
                            [#assign path = solution.Path?ensure_ends_with("*")]
                        [#else]
                            [#assign path = solution.Path ]
                        [/#if]
                    [/#if]
                    [#break]

                [#default]
                    [#assign path = "" ]
                    [#break]
            [/#switch]
            [#assign listenerRuleConditions = getListenerRulePathCondition(path) ]

            [#-- Certificate details if required --]
            [#assign certificateObject = getCertificateObject(solution.Certificate, segmentQualifiers, sourcePort.Id, sourcePort.Name) ]
            [#assign hostName = getHostName(certificateObject, subOccurrence) ]
            [#assign primaryDomainObject = getCertificatePrimaryDomain(certificateObject) ]
            [#assign certificateId = formatDomainCertificateId(certificateObject, hostName) ]

            [#if engine == "application" ]
                [#-- FQDN processing --]
                [#if solution.HostFilter ]
                    [#assign fqdn = formatDomainName(hostName, primaryDomainObject)]

                    [#list resources["domainRedirectRules"]!{} as key, rule]

                        [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                            [@createListenerRule
                                mode=listMode
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

                    [#assign listenerRuleConditions += getListenerRuleHostCondition(fqdn) ]
                [/#if]

                [#-- Redirect rule processing --]
                [#if isPresent(solution.Redirect) ]
                    [#assign targetGroupRequired = false ]
                    [#assign listenerForwardRule = false ]

                    [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                        [@createListenerRule
                            mode=listMode
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
                    [#assign targetGroupRequired = false ]
                    [#assign listenerForwardRule = false ]
                    [#assign fixedMessage = getOccurrenceSettingValue(subOccurrence, ["Fixed", "Message"], true) ]
                    [#assign fixedContentType = getOccurrenceSettingValue(subOccurrence, ["Fixed", "ContentType"], true) ]
                    [#assign fixedStatusCode = getOccurrenceSettingValue(subOccurrence, ["Fixed", "StatusCode"], true) ]
                        [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                            [@createListenerRule
                                mode=listMode
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
            [#assign linkCount = 0 ]
            [#list solution.Links?values as link]
                [#if link?is_hash]
                    [#assign linkCount += 1 ]
                    [#if linkCount > 1 ]
                        [@cfException
                            mode=listMode
                            description="A port mapping can only have a maximum of one link"
                            context=subOccurrence
                        /]
                        [#continue]
                    [/#if]

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
                        [#case "external" ]
                            [#assign cognitoIntegration = true ]
                            [#assign listenerForwardRule = false ]

                            [#if linkTargetCore.Type == "external" ]
                                [#-- Workaround for userpools in other segments --]
                                [#assign userPoolDomain = linkTargetAttributes["USERPOOL_HOSTNAME"] ]
                                [#assign userPoolArn = linkTargetAttributes["USERPOOL_ARN"] ]
                                [#assign userPoolClientId = linkTargetAttributes["USERPOOL_CLIENTID"] ]
                                [#assign userPoolSessionCookieName = linkTargetAttributes["USERPOOL_SESSION_COOKIENAME"] ]
                                [#assign userPoolSessionTimeout = linkTargetAttributes["USERPOOL_SESSION_TIMEOUT"]?number ]
                                [#assign userPoolOauthScope = linkTargetAttributes["USERPOOL_OAUTH_SCOPE"] ]
                            [#else]
                                [#assign userPoolId = linkTargetResources["userpool"].Id ]
                                [#assign userPoolClientId = linkTargetResources["client"].Id ]
                                [#assign userPoolDomain = linkTargetResources["domain"].Name ]
                                [#assign userPoolArn = getExistingReference(userPoolId, ARN_ATTRIBUTE_TYPE) ]
                                [#assign userPoolClientId = getExistingReference(userPoolClientId) ]
                                [#assign userPoolSessionCookieName = solution.Authentication.SessionCookieName ]
                                [#assign userPoolSessionTimeout = solution.Authentication.SessionTimeout ]
                                [#assign userPoolOauthScope =  linkTargetConfiguration.Solution.OAuth.Scopes?join(", ") ]
                            [/#if]

                            [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) && engine == "application" ]
                                [@createListenerRule
                                    mode=listMode
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
                            [#assign targetGroupRequired = false ]
                            [#assign listenerForwardRule = false ]
                            [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) && engine == "application"  ]
                                [@createListenerRule
                                    mode=listMode
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
                            mode=listMode
                            id=securityGroupId
                            name=securityGroupName
                            tier=tier
                            component=component
                            ingressRules=[ {"Port" : sourcePort.Port, "CIDR" : cidrs} ]/]

                    [/#if]
                    [#break]
            [/#switch]

            [#-- Process the mapping --]
            [#switch engine ]
                [#case "application"]
                    [#assign tgAttributes +=
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
                        [#if getExistingReference(listenerId)?has_content ]
                            [#assign ruleCleanupScript += [
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
                                    mode=listMode
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
                    [#assign tgAttributes +=
                        {
                            "deregistration_delay.timeout_seconds" : solution.Forward.DeregistrationTimeout
                        }]

                    [#if firstMappingForPort ]

                        [#assign lbSecurityGroupIds += [securityGroupId] ]
                        [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                            [@createALBListener
                                mode=listMode
                                id=listenerId
                                port=sourcePort
                                albId=lbId
                                defaultTargetGroupId=defaultTargetGroupId
                                certificateId=certificateId
                                sslPolicy=securityProfile.HTTPSProfile
                            /]

                            [@createTargetGroup
                                mode=listMode
                                id=defaultTargetGroupId
                                name=defaultTargetGroupName
                                tier=tier
                                component=component
                                destination=destinationPort
                                attributes=tgAttributes
                                targetType=solution.Forward.TargetType
                            /]
                        [/#if]
                    [/#if]

                    [#if ( targetGroupRequired ) &&
                        ( engine == "application" ) &&
                        deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]

                        [@createTargetGroup
                            mode=listMode
                            id=targetGroupId
                            name=targetGroupName
                            tier=tier
                            component=component
                            destination=destinationPort
                            attributes=tgAttributes
                            targetType=solution.Forward.TargetType
                             /]
                    [/#if]

                    [#break]

                [#case "classic"]
                    [#if firstMappingForPort ]
                        [#assign lbSecurityGroupIds += [securityGroupId] ]
                        [#assign classicListenerPolicyNames = []]
                        [#assign classicSSLRequired = sourcePort.Certificate!false ]

                        [#if classicSSLRequired ]
                            [#assign classicListenerPolicyNames += [
                                classicHTTPSPolicyName
                            ]]
                        [/#if]

                        [#if solution.Forward.StickinessTime > 0 ]
                            [#assign stickinessPolicyName = formatName(core.Name, "sticky") ]
                            [#assign classicListenerPolicyNames += [ stickinessPolicyName ]]
                            [#assign classicStickinessPolicies += [
                                {
                                    "PolicyName" : stickinessPolicyName,
                                    "CookieExpirationPeriod" : solution.Forward.StickinessTime
                                }
                            ]]
                        [/#if]

                        [#assign classicListeners +=
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

            [@cfScript
                mode=listMode
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
        [#assign InvalidProtocol = false]
        [#switch engine ]
            [#case "network" ]
                [#if portProtocols?seq_contains("HTTP") || portProtocols?seq_contains("HTTPS") ]
                    [#assign InvalidProtocol = true]
                [/#if]
                [#break]
            [#case "application" ]
                [#if portProtocols?seq_contains("TCP") ]
                    [#assign InvalidProtocol = true]
                [/#if]
                [#break]
        [/#switch]

        [#if InvalidProtocol ]
                [@cfException
                    mode=listMode
                    description="Invalid protocol found for engine type"
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
                        mode=listMode
                        id=lbId
                        name=lbName
                        shortName=lbShortName
                        tier=tier
                        component=component
                        securityGroups=lbSecurityGroupIds
                        logs=lbLogs
                        type=engine
                        bucket=operationsBucket
                        idleTimeout=idleTimeout /]
                [/#if]
                [#break]

            [#case "classic"]

                [#assign healthCheck = {
                    "Target" : healthCheckPort.HealthCheck.Protocol!healthCheckPort.Protocol + ":"
                                + (healthCheckPort.HealthCheck.Port!healthCheckPort.Port)?c + healthCheckPort.HealthCheck.Path!"",
                    "HealthyThreshold" : healthCheckPort.HealthCheck.HealthyThreshold,
                    "UnhealthyThreshold" : healthCheckPort.HealthCheck.UnhealthyThreshold,
                    "Interval" : healthCheckPort.HealthCheck.Interval,
                    "Timeout" : healthCheckPort.HealthCheck.Timeout
                }]

                [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                    [@createClassicLB
                        mode=listMode
                        id=lbId
                        name=lbName
                        shortName=lbShortName
                        tier=tier
                        component=component
                        listeners=classicListeners
                        healthCheck=healthCheck
                        securityGroups=lbSecurityGroupIds
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
    [/#list]
[/#if]