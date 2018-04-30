[#-- LB --]
[#if (componentType == LB_COMPONENT_TYPE) ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#if deploymentSubsetRequired("alb", true) ]

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

            [#list occurrence.Occurrences![] as subOccurrence]

                [#assign solution = subOccurrence.Configuration.Solution ]
                [#assign resources = subOccurrence.State.Resources ]

                [#assign listenerId = resources["listener"].Id ]

                [#assign securityGroupId = resources["sg"].Id]
                [#assign securityGroupName = resources["sg"].Name]

                [#assign targetGroupId = resources["targetgroups"]["default"].Id]
                [#assign targetGroupName = resources["targetgroups"]["default"].Name]

                [#assign lbSecurityGroupIds += [securityGroupId] ]

                [#assign source = (portMappings[solution.Mapping].Source)!"" ]
                [#assign destination = (portMappings[solution.Mapping].Destination)!"" ]
                [#assign sourcePort = (ports[source])!{} ]
                [#assign destinationPort = (ports[destination])!{} ]

                [#assign portProtocols += [ sourcePort.Protocol ] ]
                [#assign portProtocols += [ destinationPort.Protocol] ]

                [#if !(sourcePort?has_content && destinationPort?has_content)]
                    [#continue ]
                [/#if]

                [#assign cidr= getGroupCIDRs(solution.IPAddressGroups) ]

                [#-- Internal ILBs may not have explicit IP Address Groups --]
                [#assign cidr =
                    cidr?has_content?then(
                        cidr,
                        (tier.Network.RouteTable == "external")?then(
                            [],
                            segmentObject.Network.CIDR.Address + "/" +segmentObject.Network.CIDR.Mask
                        )) ]

                [#assign certificateObject = getCertificateObject(solution.Certificate, segmentId, segmentName, sourcePort.Id, sourcePort.Name) ]
                [#assign hostName = getHostName(certificateObject, subOccurrence) ]
                [#assign certificateId = formatDomainCertificateId(certificateObject, hostName) ]

                [#if engine == "application" || engine == "classic" ]
                    [@createSecurityGroup
                        mode=listMode
                        id=securityGroupId
                        name=securityGroupName
                        tier=tier
                        component=component
                        ingressRules=[{"Port" : sourcePort.Port, "CIDR" : cidr}] /]
                [/#if]

                [#switch engine ]
                    [#case "application"]
                    [#case "network"]

                        [@createTargetGroup
                            mode=listMode
                            id=targetGroupId
                            name=targetGroupName
                            tier=tier
                            component=component
                            destination=destinationPort /]

                        [@createALBListener
                            mode=listMode
                            id=listenerId
                            port=sourcePort
                            albId=lbId
                            defaultTargetGroupId=targetGroupId
                            certificateId=certificateId /]
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
                        bucket=operationsBucket /]
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
                     /]
                [#break]
            [/#switch ]
        [/#if]
    [/#list]
[/#if]