[#-- ALB --]

[#if (componentType == ALB_COMPONENT_TYPE) ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#if deploymentSubsetRequired("alb", true) ]

            [#assign solution = occurrence.Configuration.Solution ]
            [#assign resources = occurrence.State.Resources ]

            [#assign albId = resources["lb"].Id ]
            [#assign albName = resources["lb"].Name ]
            [#assign albShortName = resources["lb"].ShortName ]
            [#assign albLogs = solution.Logs ]
            [#assign albSecurityGroupIds = [] ]

            [#assign portProtocols = [] ]

            [#list occurrence.Occurrences![] as subOccurrence]

                [#assign solution = subOccurrence.Configuration.Solution ]
                [#assign resources = subOccurrence.State.Resources ]

                [#assign listenerId = resources["listener"].Id ]

                [#assign securityGroupId = resources["sg"].Id]
                [#assign securityGroupName = resources["sg"].Name]

                [#assign targetGroupId = resources["targetgroups"]["default"].Id]
                [#assign targetGroupName = resources["targetgroups"]["default"].Name]

                [#assign albSecurityGroupIds += [securityGroupId] ]

                [#assign source = (portMappings[solution.Mapping].Source)!"" ]
                [#assign destination = (portMappings[solution.Mapping].Destination)!"" ]
                [#assign sourcePort = (ports[source])!{} ]
                [#assign destinationPort = (ports[destination])!{} ]

                [#assign portProtocols += [ sourcePort.Protocol ] ]
                [#assign portProtocols += [ destinationPort.Protocol] ]

                [#if !(sourcePort?has_content && destinationPort?has_content)]
                    [#continue ]
                [/#if]

                [#assign cidr=
                        getUsageCIDRs(
                            source,
                            solution.IPAddressGroups) ]

                [#-- Internal ILBs may not have explicit IP Address Groups --]
                [#assign cidr =
                    cidr?has_content?then(
                        cidr,
                        (tier.Network.RouteTable == "external")?then(
                            [],
                            segmentObject.Network.CIDR.Address + "/" +segmentObject.Network.CIDR.Mask
                        )) ]

                [#if sourcePort.Protocol != "TCP" &&  destinationPort.Protocol != "TCP" ]
                    [@createSecurityGroup
                        mode=listMode
                        id=securityGroupId
                        name=securityGroupName
                        tier=tier
                        component=component
                        ingressRules=[{"Port" : sourcePort.Port, "CIDR" : cidr}] /]
                [/#if]

                [@createTargetGroup
                    mode=listMode
                    id=targetGroupId
                    name=targetGroupName
                    tier=tier
                    component=component
                    destination=destinationPort /]

                [#assign certificateObject = getCertificateObject(solution.Certificate, segmentId, segmentName, sourcePort.Id, sourcePort.Name) ]
                [#assign hostName = getHostName(certificateObject, subOccurrence) ]
                [#assign certificateId = formatDomainCertificateId(certificateObject, hostName) ]

                [@createALBListener
                    mode=listMode
                    id=listenerId
                    port=sourcePort
                    albId=albId
                    defaultTargetGroupId=targetGroupId
                    certificateId=certificateId /]
            [/#list]

            [#if ( portProtocols?seq_contains("HTTP") || portProtocols?seq_contains("HTTPS") ) && !(portProtocols?seq_contains("TCP"))  ]
                
                [#assign lbType = "application" ]

            [#elseif portProtocols?seq_contains("TCP") && !(portProtocols?seq_contains("HTTP") && portProtocols?seq_contains("HTTPS") )]
                [#assign lbType = "network" ]
            
            [#else]
                [@cfException
                    mode=listMode
                    description="Mixed LB Protocols"
                    context=
                        {
                            "ALB" : albName,
                            "Protocols" : portProtocols
                        }
                    detail="You can either use TCP or HTTP/HTTPS for load balancers, they can't be mixed" 
                /]
            [/#if]

            [@createALB
                mode=listMode
                id=albId
                name=albName
                shortName=albShortName
                tier=tier
                component=component
                securityGroups=albSecurityGroupIds
                logs=albLogs
                type=lbType
                bucket=operationsBucket /]
        [/#if]
    [/#list]
[/#if]