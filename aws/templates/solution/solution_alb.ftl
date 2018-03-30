[#-- ALB --]
[#if (componentType == "alb") && deploymentSubsetRequired("alb", true)]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]
        
        [#assign albId = resources["lb"].Id ]
    
        [#assign albSecurityGroupId = formatALBSecurityGroupId(tier, component, occurrence)]
        [@createComponentSecurityGroup
            mode=listMode
            tier=tier
            component=component
            extensions=occurrence
        /]
        [#list solution.PortMappings as mapping]
            [#assign mappingObject =
                {
                    "IPAddressGroups" : solution.IPAddressGroups,
                    "Certificate" : solution.Certificate
                } +
                mapping?is_hash?then(
                    mapping,
                    {
                        "Mapping" : mapping
                    }
                )]
            [#assign source = portMappings[mappingObject.Mapping].Source]
            [#assign sourcePort = ports[source] ]                    
            [#assign destinationPort = ports[portMappings[mappingObject.Mapping].Destination]]
            
            [#assign albTargetGroupId =
                        formatALBTargetGroupId(
                            tier,
                            component,
                            sourcePort,
                            "default",
                            occurrence)]
            [@createTargetGroup
                mode=listMode
                id=albTargetGroupId
                name="default"
                tier=tier
                component=component
                source=sourcePort
                destination=destinationPort
                extensions=occurrence
            /]
                    
            [#assign albListenerSecurityGroupIngressId =
                        formatALBListenerSecurityGroupIngressId(
                            albSecurityGroupId,
                            sourcePort)]

            [#assign cidr=
                    getUsageCIDRs(
                        source,
                        mappingObject.IPAddressGroups) ]
            [#-- Internal ILBs may not have explicit IP Address Groups --]
            [#assign cidr =
                cidr?has_content?then(
                    cidr,
                    (tier.Network.RouteTable == "external")?then(
                        [],
                        segmentObject.Network.CIDR.Address + "/" +segmentObject.Network.CIDR.Mask
                    )) ]
                        
            [@createSecurityGroupIngress
                mode=listMode
                id=albListenerSecurityGroupIngressId
                port=source
                cidr=cidr
                groupId=albSecurityGroupId
            /]
                    
            [#assign albListenerId =
                        formatALBListenerId(
                            tier,
                            component,
                            sourcePort,
                            occurrence)]
                            
            [#assign certificateObject = getCertificateObject(mappingObject.Certificate, segmentId, segmentName, sourcePort.Id, sourcePort.Name) ]
            [#assign hostName = getHostName(certificateObject, tier, component, occurrence) ]
            [#assign certificateId = formatDomainCertificateId(certificateObject, hostName) ]

            [@createALBListener
                mode=listMode
                id=albListenerId
                port=sourcePort
                albId=albId
                defaultTargetGroupId=albTargetGroupId
                certificateId=certificateId
            /]
        [/#list]
    
        [@createALB
            mode=listMode
            id=albId
            name=formatComponentFullName(tier, component, occurrence) 
            shortName=formatComponentShortFullName(tier, component, occurrence)
            tier=tier
            component=component
            securityGroups=albSecurityGroupId
            logs=solution.Logs
            bucket=operationsBucket
        /]
    [/#list]
[/#if]