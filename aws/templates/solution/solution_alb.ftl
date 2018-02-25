[#-- ALB --]
[#if (componentType == "alb") && deploymentSubsetRequired("alb", true)]

    [#list getOccurrences(component, tier, component, deploymentUnit) as occurrence]

        [#assign albId = formatALBId(tier, component, occurrence)]
    
        [#assign albSecurityGroupId = formatALBSecurityGroupId(tier, component, occurrence)]
        [@createComponentSecurityGroup
            mode=listMode
            tier=tier
            component=component
            extensions=occurrence
        /]
        [#list occurrence.PortMappings as mapping]
            [#assign mappingObject =
                {
                    "IPAddressGroups" : occurrence.IPAddressGroups,
                    "Certificate" : occurrence.Certificate
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
                    (tier.RouteTable == "external")?then(
                        [],
                        segmentObject.CIDR.Address + "/" +segmentObject.CIDR.Mask
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
            logs=occurrence.Logs
            bucket=operationsBucket
        /]
    [/#list]
[/#if]