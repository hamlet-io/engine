[#ftl]

[#function getSecurityGroupRules port cidr groupId=""]
    [#local rules = [] ]
    [#list asArray(cidr) as cidrBlock]
        [#local rule =
            port?is_number?then(
                (port == 0)?then(
                    {
                        "IpProtocol": "tcp",
                        "FromPort": 32768,
                        "ToPort" : 65535
                    },
                    {
                        "IpProtocol": "tcp",
                        "FromPort": port,
                        "ToPort" : port
                    }
                ),
                {
                    "IpProtocol": ports[port]?has_content?then(
                                        (ports[port].IPProtocol == "all")?then(
                                            "-1",
                                            ports[port].IPProtocol
                                        ),
                                        -1),

                    "FromPort": ports[port]?has_content?then(
                                        ports[port].PortRange.Configured?then(
                                                ports[port].PortRange.From,
                                                ports[port].Port
                                        ),
                                        1),

                    "ToPort": ports[port]?has_content?then(
                                        ports[port].PortRange.Configured?then(
                                            ports[port].PortRange.To,
                                            ports[port].Port
                                        ),
                                        65535)
                }
            )
        ]

        [#if groupId?has_content]
            [#local rule +=
                {
                    "GroupId": getReference(groupId)
                }
            ]
        [/#if]
        [#if cidrBlock?contains("X")]
            [#local rule +=
                {
                    "SourceSecurityGroupId": getReference(cidrBlock)
                }
            ]
        [#else]
            [#if cidrBlock?contains(":") ]
                [#local rule +=
                    {
                        "CidrIpv6": cidrBlock
                    }
                ]
            [#else]
                [#local rule +=
                    {
                        "CidrIp": cidrBlock
                    }
                ]
            [/#if]
        [/#if]
        [#local rules += [rule] ]
    [/#list]
    [#return rules]
[/#function]

[#macro createSecurityGroupIngress id port cidr groupId]
    [#local cidrs = asArray(cidr) ]
    [#list cidrs as cidrBlock]
        [@cfResource
            id=
                formatId(
                    id,
                    (cidrs?size > 1)?then(
                        cidrBlock?index,
                        ""
                    )
                )
            type="AWS::EC2::SecurityGroupIngress"
            properties=
                getSecurityGroupRules(port, cidrBlock, groupId)[0]
        /]
    [/#list]
[/#macro]

[#macro createSecurityGroup id name vpcId tier={} component={} occurrence={} description="" ingressRules=[] egressRules=[] ]
    [#local nonemptyIngressRules = [] ]
    [#list asFlattenedArray(ingressRules) as ingressRule]
        [#if ingressRule.CIDR?has_content]
            [#local nonemptyIngressRules +=
                        getSecurityGroupRules(
                            ingressRule.Port,
                            ingressRule.CIDR) ]
        [/#if]
    [/#list]

    [#local nonemptyEgressRules = [] ]
    [#list asFlattenedArray(egressRules) as egressRule]
        [#if egressRule.CIDR?has_content]
            [#local nonemptyEgressRules +=
                        getSecurityGroupRules(
                            egressRule.Port,
                            egressRule.CIDR) ]
        [/#if]
    [/#list]

    [#local properties =
        {
            "GroupDescription" : description?has_content?then(description, name),
            "VpcId" : (vpcId?has_content)?then(
                            getReference(vpcId),
                            vpc
                      )
        } +
        attributeIfContent(
            "SecurityGroupIngress",
            nonemptyIngressRules
        ) +
        attributeIfContent(
            "SecurityGroupEgress",
            nonemptyEgressRules
        )
    ]

    [@cfResource
        id=id
        type="AWS::EC2::SecurityGroup"
        properties=properties
        tags=
            getCfTemplateCoreTags(
                name,
                contentIfContent(tier,occurrence.Core.Tier),
                contentIfContent(component,occurrence.Core.Component))
    /]
[/#macro]

[#macro createDependentSecurityGroup
            resourceId
            resourceName
            vpcId
            tier={}
            component={}
            occurrence={}
            ingressRules=[]]
    [@createSecurityGroup
        id=formatDependentSecurityGroupId(resourceId)
        name=resourceName
        vpcId=vpcId
        tier=tier
        component=component
        occurrence=occurrence
        description="Security Group for " + resourceName
        ingressRules=ingressRules
        /]
[/#macro]

[#macro createComponentSecurityGroup
            occurrence
            vpcId=vpcId
            extensions=""
            ingressRules=[] ]
    [@createSecurityGroup
        id=formatComponentSecurityGroupId(
            occurrence.Core.Tier,
            occurrence.Core.Component,
            extensions)
        name=formatComponentFullName(
            occurrence.Core.Tier,
            occurrence.Core.Component,
            extensions)
        vpcId=vpcId
        occurrence=occurrence
        ingressRules=ingressRules
    /]
[/#macro]

[#macro createDependentComponentSecurityGroup
            resourceId
            resourceName
            occurrence
            extensions=""
            vpcId=vpcId
            ingressRules=[] ]
    [#local legacyId = formatComponentSecurityGroupId(
                        occurrence.Core.Tier,
                        occurrence.Core.Component,
                        extensions)]
    [#if getExistingReference(legacyId)?has_content]
        [@createComponentSecurityGroup
            vpcId=vpcId
            occurrence=occurrence
            extensions=extensions
            ingressRules=ingressRules /]
    [#else]
        [@createDependentSecurityGroup
            resourceId=resourceId
            resourceName=resourceName
            occurrence=occurrence
            vpcId=vpcId
            ingressRules=ingressRules /]
    [/#if]
[/#macro]

[#macro createFlowLog
            id
            roleId
            logGroupName
            resourceId
            resourceType
            trafficType]
    [@cfResource
        id=id
        type="AWS::EC2::FlowLog"
        properties=
            {
                "DeliverLogsPermissionArn" : getReference(roleId, ARN_ATTRIBUTE_TYPE),
                "LogGroupName" : logGroupName,
                "ResourceId" : getReference(resourceId),
                "ResourceType" : resourceType,
                "TrafficType" : trafficType
            }
    /]
[/#macro]

[#macro createVPCFlowLog id vpcId roleId logGroupName trafficType]
    [@createFlowLog
        id,
        roleId,
        logGroupName,
        vpcId,
        "VPC",
        trafficType /]
[/#macro]

[#macro createVPC
            id
            name
            cidr
            dnsSupport
            dnsHostnames
            resourceId=""]
    [@cfResource
        id=(resourceId?has_content)?then(
                            resourceId,
                            id)
        type="AWS::EC2::VPC"
        properties=
            {
                "CidrBlock" : cidr,
                "EnableDnsSupport" : dnsSupport,
                "EnableDnsHostnames" : dnsHostnames
            }
        tags=getCfTemplateCoreTags(name)
        outputId=id
    /]
[/#macro]

[#macro createIGW
            id
            name
            resourceId=""]
    [@cfResource
        id=(resourceId?has_content)?then(
                            resourceId,
                            id)
        type="AWS::EC2::InternetGateway"
        tags=getCfTemplateCoreTags(name)
        outputId=id
    /]
[/#macro]

[#macro createIGWAttachment
            id
            vpcId
            igwId]
    [@cfResource
        id=id
        type="AWS::EC2::VPCGatewayAttachment"
        properties=
            {
                "InternetGatewayId" : getReference(igwId),
                "VpcId" : getReference(vpcId)
            }
        outputs={}
    /]
[/#macro]

[#assign EIP_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        IP_ADDRESS_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ALLOCATION_ATTRIBUTE_TYPE : {
            "Attribute" : "AllocationId"
        }
    }
]
[@addOutputMapping
    provider=AWS_PROVIDER
    resourceType=AWS_EIP_RESOURCE_TYPE
    mappings=EIP_OUTPUT_MAPPINGS
/]

[#macro createEIP
            id
            tags=[]
            dependencies=""]
    [@cfResource
        id=id
        type="AWS::EC2::EIP"
        properties=
            {
                "Domain" : "vpc"
            }
        outputs=EIP_OUTPUT_MAPPINGS
        tags=tags
        dependencies=dependencies
    /]
[/#macro]

[#macro createNATGateway
            id,
            tags,
            subnetId,
            eipId]
    [@cfResource
        id=id
        type="AWS::EC2::NatGateway"
        properties=
            {
                "AllocationId" : getReference(eipId, ALLOCATION_ATTRIBUTE_TYPE),
                "SubnetId" : getReference(subnetId)
            }
        tags=tags

    /]
[/#macro]

[#macro createRouteTable
            id,
            name,
            vpcId,
            zone=""]
    [@cfResource
        id=id
        type="AWS::EC2::RouteTable"
        properties=
            {
                "VpcId" : getReference(vpcId)
            }
        tags=getCfTemplateCoreTags(name,"","",zone)
    /]
[/#macro]

[#macro createRoute
            id,
            routeTableId,
            route
            dependencies=""]

    [#local properties =
        {
            "RouteTableId" : getReference(routeTableId),
            "DestinationCidrBlock" : route.CIDR
        }
    ]
    [#switch route.Type]
        [#case "gateway"]
            [#local properties +=
                {
                    "GatewayId" : getReference(route.IgwId)
                }
            ]
            [#break]

        [#case "instance"]
            [#local properties +=
                {
                    "InstanceId" : getReference(route.InstanceId)
                }
            ]
            [#break]

        [#case "nat"]
            [#local properties +=
                {
                    "NatGatewayId" : getReference(route.NatId)
                }
            ]
            [#break]

    [/#switch]
    [@cfResource
        id=id
        type="AWS::EC2::Route"
        properties=properties
        outputs={}
        dependencies=dependencies
    /]
[/#macro]

[#macro createNetworkACL
            id,
            name,
            vpcId]
    [@cfResource
        id=id
        type="AWS::EC2::NetworkAcl"
        properties=
            {
                "VpcId" : getReference(vpcId)
            }
        tags=getCfTemplateCoreTags(name)
        outputs={}
    /]
[/#macro]

[#macro createNetworkACLEntry
            id,
            networkACLId,
            outbound,
            rule,
            port]

    [#local protocol = port.IPProtocol]

    [#local fromPort = (port.PortRange.From)?has_content?then(
                            port.PortRange.From,
                            (port.Port)?has_content?then(
                                port.Port,
                                0
                            ))]

    [#local toPort = (port.PortRange.To)?has_content?then(
                            port.PortRange.To,
                            (port.Port)?has_content?then(
                                port.Port,
                                0
                            ))]
    [#switch port.IPProtocol]
        [#case "all"]
            [#local properties =
                {
                    "Protocol" : "-1",
                    "PortRange" : {
                        "From" : fromPort,
                        "To" : toPort
                    }
                }
            ]
            [#break]
        [#case "icmp"]
            [#local properties =
                {
                    "Protocol" : "1",
                    "Icmp" : {
                        "Code" : (port.ICMP.Code)!-1,
                        "Type" : (port.ICMP.Type)!-1
                    }
                }
            ]
            [#break]
        [#case "udp"]
            [#local properties =
                {
                    "Protocol" : "17",
                    "PortRange" : {
                        "From" : fromPort,
                        "To" : toPort
                    }
                }
            ]
            [#break]
        [#case "tcp"]
            [#local properties =
                {
                    "Protocol" : "6",
                    "PortRange" : {
                        "From" : fromPort,
                        "To" : toPort
                    }
                }
            ]
            [#break]
    [/#switch]
    [@cfResource
        id=id
        type="AWS::EC2::NetworkAclEntry"
        properties=
            properties +
            {
                "NetworkAclId" : getReference(networkACLId),
                "Egress" : outbound,
                "RuleNumber" : rule.RuleNumber,
                "RuleAction" : rule.Allow?string("allow","deny"),
                "CidrBlock" : rule.CIDRBlock
            }
        outputs={}
    /]
[/#macro]

[#macro createSubnet
            id,
            name,
            vpcId,
            tier,
            zone,
            cidr,
            private]
    [#local tags =
        private?then(
            [
                {
                    "Key" : "network",
                    "Value" : "private"
                }
            ],
            []
        )
    ]
    [@cfResource
        id=id
        type="AWS::EC2::Subnet"
        properties=
            {
                "VpcId" : getReference(vpcId),
                "AvailabilityZone" : zone.AWSZone,
                "CidrBlock" : cidr
            }
        tags=
            tags +
            getCfTemplateCoreTags(name, tier, "", zone)
    /]
[/#macro]

[#macro createRouteTableAssociation
            id,
            subnetId,
            routeTableId]

    [@cfResource
        id=id
        type="AWS::EC2::SubnetRouteTableAssociation"
        properties=
            {
                "SubnetId" : getReference(subnetId),
                "RouteTableId" : getReference(routeTableId)
            }
        outputs={}
    /]
[/#macro]

[#macro createNetworkACLAssociation
            id,
            subnetId,
            networkACLId]

    [@cfResource
        id=id
        type="AWS::EC2::SubnetNetworkAclAssociation"
        properties=
            {
                "SubnetId" : getReference(subnetId),
                "NetworkAclId" : getReference(networkACLId)
            }
        outputs={}
    /]
[/#macro]

[#macro createVPCEndpoint
            id,
            vpcId,
            service,
            type,
            privateDNSZone=false,
            subnetIds=[],
            routeTableIds=[],
            securityGroupIds=[],
            statements=[]
]

    [@cfResource
        id=id
        type="AWS::EC2::VPCEndpoint"
        properties=
            {
                "ServiceName" : service,
                "VpcId" : getReference(vpcId)
            } +
            (type == "gateway")?then(
                {
                    "VpcEndpointType" : "Gateway",
                    "RouteTableIds" : getReferences(routeTableIds)
                } +
                valueIfContent(getPolicyDocument(statements), statements),
                {}
            ) +
            (type == "interface")?then(
                {
                    "VpcEndpointType" : "Interface",
                    "SubnetIds" : getReferences(subnetIds),
                    "PrivateDnsEnabled" : privateDNSZone,
                    "SecurityGroupIds" : getReferences(securityGroupIds)
                },
                {}
            )

        outputs={}
    /]
[/#macro]
