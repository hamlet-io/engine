[#-- LB --]
[#if (componentType == LB_COMPONENT_TYPE) ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#assign lbId = resources["lb"].Id ]
        [#assign lbName = resources["lb"].Name ]
        [#assign lbShortName = resources["lb"].ShortName ]
        [#assign lbLogs = solution.Logs ]
        [#assign lbSecurityGroupIds = [] ]

        [#assign engine = solution.Engine]
        [#assign idleTimeout = solution.IdleTimeout]

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

        [#list occurrence.Occurrences![] as subOccurrence]

            [#assign core = subOccurrence.Core ]
            [#assign solution = subOccurrence.Configuration.Solution ]
            [#assign resources = subOccurrence.State.Resources ]

            [#-- Determine if this is the first mapping for the source port --]
            [#-- The assumption is that all mappings for a given port share --]
            [#-- the same listenerId, so the same port number shouldn't be  --]
            [#-- defined with different names --]
            [#assign listenerId = resources["listener"].Id ]
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

            [#-- Rule setup --]
            [#assign priority = solution.Priority + subOccurrence?index ]

            [#assign targetGroupId = resources["targetgroup"].Id]
            [#assign targetGroupName = resources["targetgroup"].Name]
            [#assign targetGroupRequired = false ]

            [#assign listenerRuleId = resources["listenerRule"].Id ]
            [#assign listenerRuleRequired = false ]
            [#assign listenerRuleConfig = {}]
            [#assign listenerRuleCommand = "createListenerRule" ]

            [#-- Path processing --]
            [#switch engine ]
                [#case "application"]
                    [#if solution.Path == "default" ]
                        [#assign path = "*"]
                    [#else]
                        [#assign path = solution.Path ]
                        [#assign listenerRuleRequired = true ]
                        [#assign targetGroupRequired = true ]
                    [/#if]
                    [#break]

                [#default]
                    [#assign path = "" ]
                    [#break]
            [/#switch]
            [#assign listenerRuleConditions = asArray(getListenerRulePathCondition(path)) ]

            [#-- Redirect rule processing --]
            [#if solution.Redirect.Configured]
                [#assign listenerRuleRequired = true ]
                [#assign listenerRuleConfig =
                    {
                        "Conditions" : listenerRuleConditions,
                        "Priority" : priority,
                        "Actions" : asArray(
                                        getListenerRuleRedirectAction(
                                            solution.Redirect.Protocol,
                                            solution.Redirect.Port,
                                            solution.Redirect.Host,
                                            solution.Redirect.Path,
                                            solution.Redirect.Query,
                                            solution.Redirect.Permanent))
                    } ]
            [/#if]

            [#-- Fixed rule processing --]
            [#if solution.Fixed.Configured]
                [#assign listenerRuleRequired = true ]
                [#assign fixedMessage = getOccurrenceSettingValue(subOccurrence, ["Fixed", "Message"], true) ]
                [#assign fixedContentType = getOccurrenceSettingValue(subOccurrence, ["Fixed", "ContentType"], true) ]
                [#assign fixedStatusCode = getOccurrenceSettingValue(subOccurrence, ["Fixed", "StatusCode"], true) ]
                [#assign listenerRuleConfig =
                    {
                        "Conditions" : listenerRuleConditions,
                        "Priority" : priority,
                        "Actions" :
                            asArray(
                                getListenerRuleFixedAction(
                                    contentIfContent(
                                        fixedMessage,
                                        solution.Fixed.Message),
                                    contentIfContent(
                                        fixedContentType,
                                        solution.Fixed.ContentType),
                                    contentIfContent(
                                        fixedStatusCode,
                                        solution.Fixed.StatusCode)
                                )
                            )
                    } ]
            [/#if]

            [#-- Certificate details if required --]
            [#assign certificateObject = getCertificateObject(solution.Certificate, segmentQualifiers, sourcePort.Id, sourcePort.Name) ]
            [#assign hostName = getHostName(certificateObject, subOccurrence) ]
            [#assign certificateId = formatDomainCertificateId(certificateObject, hostName) ]

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

                            [#if linkTargetCore.Type == "external" ]
                                [#-- Workaround for userpools in other segments --]
                                [#assign userPoolDomain = linkTargetAttributes["USERPOOL_HOSTNAME"] ]
                                [#assign userPoolArn = linkTargetAttributes["USERPOOL_ARN"] ]
                                [#assign userPoolClientId = linkTargetAttributes["USERPOOL_CLIENTID"] ]
                                [#assign userPoolSessionCookieName = linkTargetAttributes["USERPOOL_SESSION_COOKIENAME"] ]
                                [#assign userPoolSessionTimeout = linkTargetAttributes["USERPOOL_SESSION_TIMEOUT"] ]
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

                            [#assign listenerRuleRequired = true ]
                            [#assign listenerRuleConfig =
                                {
                                    "Conditions" : listenerRuleConditions,
                                    "Priority" : priority,
                                    "Actions" : [
                                        {
                                            "Type" : "authenticate-cognito",
                                            "AuthenticateCognitoConfig" : {
                                                "UserPoolArn" : userPoolArn,
                                                "UserPoolClientId" : userPoolClientId,
                                                "UserPoolDomain" : userPoolDomain,
                                                "SessionCookieName" : userPoolSessionCookieName,
                                                "SessionTimeout" : userPoolSessionTimeout,
                                                "Scope" : userPoolOauthScope,
                                                "OnUnauthenticatedRequest" : "authenticate"
                                            },
                                            "Order" : 1
                                        },
                                        getListenerRuleForwardAction(targetGroupId, 2)
                                    ]
                                }]
                            [#break]

                        [#case SPA_COMPONENT_TYPE]
                            [#assign listenerRuleRequired = true ]
                            [#assign listenerRuleConfig =
                                {
                                    "Conditions" : listenerRuleConditions,
                                    "Priority" : priority,
                                    "Actions" : asArray(
                                                    getListenerRuleRedirectAction(
                                                        "https",
                                                        "443",
                                                        linkTargetAttributes.FQDN,
                                                        "",
                                                        "",
                                                        false))
                                } ]
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
                [#case "network"]

                    [#if firstMappingForPort ]
                        [#assign lbSecurityGroupIds += [securityGroupId] ]
                        [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                            [@createALBListener
                                mode=listMode
                                id=listenerId
                                port=sourcePort
                                albId=lbId
                                defaultTargetGroupId=targetGroupId
                                certificateId=certificateId /]
                        [/#if]
                    [/#if]

                    [#if listenerRuleRequired ]
                        [#if listenerRuleConfig?has_content ]

                            [#if deploymentSubsetRequired("cli", false)]

                                [@cfCli
                                    mode=listMode
                                    id=listenerRuleId
                                    command=listenerRuleCommand
                                    content=listenerRuleConfig
                                /]

                            [/#if]

                            [#if deploymentSubsetRequired("prologue", false) ]
                                [@cfScript
                                    mode=listMode
                                    content=(getExistingReference(listenerRuleId)?has_content)?then(
                                        [
                                            "case $\{STACK_OPERATION} in",
                                            "  delete)",
                                            "       delete_elbv2_rule" +
                                            "       \"" + region + "\" " +
                                            "       \"" + getExistingReference(listenerRuleId) + "\" "
                                            "   ;;",
                                            "   esac"
                                        ],
                                        []
                                    )
                                /]
                            [/#if]
                            [#if deploymentSubsetRequired("epilogue", false) ]
                                [@cfScript
                                    mode=listMode
                                    content= (getExistingReference(listenerId)?has_content)?then(
                                                [
                                                    "case $\{STACK_OPERATION} in",
                                                    "  create|update)",
                                                    "       # Get cli config file",
                                                    "       split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?",
                                                    "       # Apply CLI level updates to ELB listener",
                                                    "       info \"Applying cli level configurtion\""
                                                ] +
                                                (getExistingReference(listenerRuleId)?has_content)?then(
                                                    [
                                                        "       update_elbv2_rule" +
                                                        "       \"" + region + "\" " +
                                                        "       \"" + getExistingReference(listenerRuleId) + "\" " +
                                                        "       \"$\{tmpdir}/cli-" +
                                                                listenerRuleId + "-" + listenerRuleCommand + ".json\""
                                                    ],
                                                    [
                                                        "       listener_rule_arn=$( create_elbv2_rule" +
                                                        "       \"" + region + "\" " +
                                                        "       \"" + getExistingReference(listenerId) + "\" " +
                                                        "       \"$\{tmpdir}/cli-" +
                                                                listenerRuleId + "-" + listenerRuleCommand + ".json\")",
                                                        "       pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-pseudo-stack.json\" ",
                                                        "       create_pseudo_stack" + " " +
                                                        "       \"LB Listener Rule\"" + " " +
                                                        "       \"$\{pseudo_stack_file}\"" + " " +
                                                        "       \"" + listenerRuleId + "Xarn\" \"$\{listener_rule_arn}\" || return $?"
                                                    ]
                                                ) +
                                                [
                                                    "   ;;",
                                                    "   esac"
                                                ],
                                            [
                                                "warning \"Please run another update to complete the configuration\""
                                            ]
                                        )
                                /]
                            [/#if]

                        [#else]
                            [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                                [@createListenerRule
                                    mode=listMode
                                    id=listenerRuleId
                                    listenerId=listenerId
                                    actions=getListenerRuleForwardAction(targetGroupId)
                                    conditions=listenerRuleConditions
                                    priority=priority
                                    dependencies=targetId /]
                            [/#if]
                        [/#if]

                    [/#if]

                    [#if (targetGroupRequired || firstMappingForPort) &&
                        deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]

                        [@createTargetGroup
                            mode=listMode
                            id=targetGroupId
                            name=targetGroupName
                            tier=tier
                            component=component
                            destination=destinationPort /]
                    [/#if]
                    [#break]

                [#case "classic"]
                    [#assign lbSecurityGroupIds += [securityGroupId] ]
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
                                sourcePort.Certificate!false,
                                getReference(certificateId, ARN_ATTRIBUTE_TYPE, regionId)
                            )
                        ]
                    ]

                    [#break]
            [/#switch]
        [/#list]

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
                        /]
                [/#if]
                [#break]
        [/#switch ]
    [/#list]
[/#if]