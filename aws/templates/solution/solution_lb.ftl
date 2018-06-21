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

        [#list occurrence.Occurrences![] as subOccurrence]

            [#assign core = subOccurrence.Core ]
            [#assign solution = subOccurrence.Configuration.Solution ]
            [#assign resources = subOccurrence.State.Resources ]

            [#assign engine = solution.Engine]
            [#assign idleTimeout = solution.IdleTimeout]
            [#assign listenerId = resources["listener"].Id ]
    
            [#assign securityGroupId = resources["sg"].Id]
            [#assign securityGroupName = resources["sg"].Name]

            [#assign targetGroupId = resources["targetgroup"].Id]
            [#assign targetGroupName = resources["targetgroup"].Name]

            [#assign lbSecurityGroupIds += [securityGroupId] ]

            [#assign mapping = solution.Mapping!core.SubComponent.Name ]
            [#assign source = (portMappings[mapping].Source)!"" ]
            [#assign destination = (portMappings[mapping].Destination)!"" ]
            [#assign sourcePort = (ports[source])!{} ]
            [#assign destinationPort = (ports[destination])!{} ]

            [#assign path = (solution.Path == "default")?then("", solution.Path)]

            [#assign listenerRuleId = resources["listenerRule"].Id ]
            [#assign listenerRuleConditions = getListenerRulePathCondition(path)]
            [#assign listenerRuleConfig = {}]
            [#assign listenerRuleCommand = "createListenerRule" ]

            [#if !(sourcePort?has_content && destinationPort?has_content)]
                [#continue ]
            [/#if]

            [#assign portProtocols += [ sourcePort.Protocol ] ]
            [#assign portProtocols += [ destinationPort.Protocol] ]

            [#assign cidr= getGroupCIDRs(solution.IPAddressGroups) ]

            [#-- Internal ILBs may not have explicit IP Address Groups --]
            [#assign cidr =
                cidr?has_content?then(
                    cidr,
                    (tier.Network.RouteTable == "external")?then(
                        [],
                        segmentObject.Network.CIDR.Address + "/" + segmentObject.Network.CIDR.Mask
                    )) ]


            [#assign certificateObject = getCertificateObject(solution.Certificate, segmentQualifiers, sourcePort.Id, sourcePort.Name) ]
            [#assign hostName = getHostName(certificateObject, subOccurrence) ]
            [#assign certificateId = formatDomainCertificateId(certificateObject, hostName) ]

            [#assign targetType = solution.TargetType ]

            [#if !(sourcePort?has_content && destinationPort?has_content)]
                [#continue ]
            [/#if]

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

                        [#case USERPOOL_COMPONENT_TYPE] 
                            [#assign cognitoIntegration = true ]
                            [#assign userPoolId = linkTargetResources["userpool"].Id ]
                            [#assign userPoolClientId = linkTargetResources["client"].Id ]
                            [#assign userPoolDomain = linkTargetResources["userpool"].HostName ]
                            [#assign listenerRuleConfig = 
                                {
                                    "Conditions" : listenerRuleConditions,
                                    "Priority" : solution.Priority,
                                    "Actions" : [
                                        {
                                            "Type" : "authenticate-cognito",
                                            "AuthenticateCognitoConfig" : {
                                                "UserPoolArn" : getExistingReference(userPoolId, ARN_ATTRIBUTE_TYPE),
                                                "UserPoolClientId" : getExistingReference(userPoolClientId),
                                                "UserPoolDomain" : userPoolDomain,
                                                "SessionCookieName" : solution.Authentication.SessionCookieName,
                                                "SessionTimeout" : solution.Authentication.SessionTimeout,
                                                "Scope" : linkTargetConfiguration.OAuthScope,
                                                "OnUnauthenticatedRequest" : "authenticate"
                                            },
                                            "Order" : 1
                                        },
                                        {
                                            "Type": "forward",
                                            "TargetGroupArn" : getReference(targetGroupId, ARN_ATTRIBUTE_TYPE),
                                            "Order" : 2
                                        }
                                    ]
                                }]  
                            [#break]
                    [/#switch]
                [/#if]
            [/#list]

            [#if engine == "application" || engine == "classic" ]
                [@createSecurityGroup
                    mode=listMode
                    id=securityGroupId
                    name=securityGroupName
                    tier=tier
                    component=component
                    ingressRules=[ {"Port" : sourcePort.Port, "CIDR" : cidr} ]/]
            [/#if]

            [#switch engine ]
                [#case "application"]
                [#case "network"]

                    [#if path == "default" ]
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

                    [#if listenerRuleConfig?has_content ]

                        [#if deploymentSubsetRequired("cli", false)]

                            [@cfCli 
                                mode=listMode
                                id=listenterRuleId
                                command=listenerRuleCommand
                                content=listenerRuleConfig
                            /]

                        [/#if]

                        [#if deploymentSubsetRequired("epilogue", false) && cliConfigRequired ]
                            [@cfScript
                                mode=listMode
                                content= (getExistingReference(listenterId)?has_content)?then(
                                        [
                                            "case $\{STACK_OPERATION} in",
                                            "  create|update)",
                                            "       # Get cli config file",
                                            "       split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?", 
                                            "       # Apply CLI level updates to ELB listener",
                                            "       info \"Applying cli level configurtion\""
                                            "       listener_rule_arn=$( create_elbv2_rule" +
                                            "       \"" + region + "\" " + 
                                            "       \"" + getExistingReference(listenterId) + "\" " + 
                                            "       \"$\{tmpdir}/cli-" + 
                                                    listenterRuleId + "-" + listenerRuleCommand + ".json\")"
                                            "       create_pseudo_stack" + " " +
                                            "       \"LB Listener Rule\"" + " " +
                                            "       \"$\{url_pseudo_stack_file}\"" + " " +
                                            "       \"" + listenterRuleId + "Xarn\" \"$\{listener_rule_arn}\" || return $?",
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
                                priority=solution.Priority
                                dependencies=targetId /]
                        [/#if]

                    [/#if]
                    
                    [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]

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
                [#break]
                å
            [#case "classic"]
            
                    [#if deploymentSubsetRequired(LB_COMPONENT_TYPE, true) ]
                        [#assign healthCheck = {
                            "Target" : healthCheckPort.HealthCheck.Protocol!healthCheckPort.Protocol + ":" 
                                        + (healthCheckPort.HealthCheck.Port!healthCheckPort.Port)?c + healthCheckPort.HealthCheck.Path!"",
                            "HealthyThreshold" : healthCheckPort.HealthCheck.HealthyThreshold,
                            "UnhealthyThreshold" : healthCheckPort.HealthCheck.UnhealthyThreshold,
                            "Interval" : healthCheckPort.HealthCheck.Interval,
                            "Timeout" : healthCheckPort.HealthCheck.Timeout
                        }]

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
                        /]
                    [/#if]
            [#break]
        [/#switch ]
    [/#list]
[/#if]