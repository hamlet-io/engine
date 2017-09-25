[#-- ALB --]
[#if componentType == "alb"]

    [#list getOccurrences(component, deploymentUnit) as occurrence]

        [#assign albId = formatALBId(tier, component, occurrence)]
    
        [#assign albSecurityGroupId = formatALBSecurityGroupId(tier, component, occurrence)]
        [@createComponentSecurityGroup
            mode=solutionListMode
            tier=tier
            component=component
            extensions=occurrence
        /]
        [#list occurrence.PortMappings as mapping]
            [#assign sourceMapping =
                        mapping?is_hash?then(
                            mapping.Mapping,
                            mapping)]
            [#assign source = portMappings[sourceMapping].Source]
            [#assign sourcePort = ports[source] ]                    
            [#assign destinationPort = ports[portMappings[mapping].Destination]]
            
            [#assign albTargetGroupId =
                        formatALBTargetGroupId(
                            tier,
                            component,
                            sourcePort,
                            "default",
                            occurrence)]
            [@createTargetGroup
                mode=solutionListMode
                id=albTargetGroupId
                name="default"
                tier=tier
                component=component
                source=sourcePort
                destination=destinationPort
                extensions=occurrence
            /]
                    
            [#assign sourceIPAddressGroups =
                        mapping?is_hash?then(
                            mapping.IPAddressGroups!occurrence.IPAddressGroups,
                            occurrence.IPAddressGroups)]
                            
            [#assign albListenerSecurityGroupIngressId =
                        formatALBListenerSecurityGroupIngressId(
                            albSecurityGroupId,
                            sourcePort)]

            [#assign cidr=
                    getUsageCIDRs(
                        source,
                        sourceIPAddressGroups) ]
            [#-- Internal ILBs may not have explicit IP Address Groups --]
            [#assign cidr =
                cidr?has_content?then(
                    cidr,
                    (tier.RouteTable == "external")?then(
                        [],
                        segmentObject.CIDR.Address + "/" +segmentObject.CIDR.Mask
                    )) ]
                        
            [@createSecurityGroupIngress
                mode=solutionListMode
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
                            
            [@createALBListener
                mode=solutionListMode
                id=albListenerId
                port=sourcePort
                albId=albId
                defaultTargetGroupId=albTargetGroupId
                certificateLink=(occurrence.DNS[sourceMapping])!{}
            /]
        [/#list]
    
        [@createALB
            mode=solutionListMode
            id=albId
            name=formatComponentFullName(tier, component, occurrence) 
            shortName=formatComponentShortFullName(tier, component, occurrence)
            tier=tier
            component=component
            securityGroups=[getReference(albSecurityGroupId)]
            logs=occurrence.Logs
            bucket=operationsBucket
        /]
    [/#list]
[/#if]