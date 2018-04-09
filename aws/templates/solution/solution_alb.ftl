[#-- ALB --]

[#if (componentType == ALB_COMPONENT_TYPE) ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#if deploymentSubsetRequired("alb", true) ]

            [#assign configuration = occurrence.Configuration ]
            [#assign resources = occurrence.State.Resources ]

            [#assign albId = resources["lb"].Id ]
            [#assign albName = resources["lb"].Name ]
            [#assign albShortName = resources["lb"].ShortName ]
            [#assign albLogs = configuration.Logs ]
            [#assign albSecurityGroupIds = [] ]

            [#list occurrence.Occurrences![] as subOccurrence]

                [#assign configuration = subOccurrence.Configuration ]
                [#assign resources = subOccurrence.State.Resources ]

                [#assign listenerId = resources["listener"].Id ]

                [#assign securityGroupId = resources["sg"].Id]
                [#assign securityGroupName = resources["sg"].Name]

                [#assign targetGroupId = resources["targetgroups"]["default"].Id]
                [#assign targetGroupName = resources["targetgroups"]["default"].Name]

                [#assign albSecurityGroupIds += [securityGroupId] ]

                [#assign source = (portMappings[configuration.Mapping].Source)!"" ]
                [#assign destination = (portMappings[configuration.Mapping].Destination)!"" ]
                [#assign sourcePort = (ports[source])!{} ]
                [#assign destinationPort = (ports[destination])!{} ]

                [#if !(sourcePort?has_content && destinationPort?has_content)]
                    [#continue ]
                [/#if]

                [#assign cidr=
                        getUsageCIDRs(
                            source,
                            configuration.IPAddressGroups) ]

                [#-- Internal ILBs may not have explicit IP Address Groups --]
                [#assign cidr =
                    cidr?has_content?then(
                        cidr,
                        (tier.Network.RouteTable == "external")?then(
                            [],
                            segmentObject.Network.CIDR.Address + "/" +segmentObject.Network.CIDR.Mask
                        )) ]

                [@createSecurityGroup
                    mode=listMode
                    id=securityGroupId
                    name=securityGroupName
                    tier=tier
                    component=component
                    ingressRules=[{"Port" : sourcePort.Port, "CIDR" : cidr}] /]

                [@createTargetGroup
                    mode=listMode
                    id=targetGroupId
                    name=targetGroupName
                    tier=tier
                    component=component
                    destination=destinationPort /]

                [#assign certificateObject = getCertificateObject(configuration.Certificate, segmentId, segmentName, sourcePort.Id, sourcePort.Name) ]
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

            [@createALB
                mode=listMode
                id=albId
                name=albName
                shortName=albShortName
                tier=tier
                component=component
                securityGroups=albSecurityGroupIds
                logs=albLogs
                bucket=operationsBucket /]
        [/#if]
    [/#list]
[/#if]