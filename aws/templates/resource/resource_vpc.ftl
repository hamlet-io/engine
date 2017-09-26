[#-- VPC --]

[#function getSecurityGroupIngressRules port cidr groupId=""]
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
                                        ports[port].IPProtocol,
                                        -1),
                    "FromPort": ports[port]?has_content?then(
                                        ports[port].Port,
                                        1),
                    "ToPort": ports[port]?has_content?then(
                                        ports[port].Port,
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

[#macro createSecurityGroupIngress mode id port cidr groupId]
    [#local cidrs = asArray(cidr) ]
    [#list cidrs as cidrBlock]
        [#switch mode]
            [#case "definition"]
                [@cfTemplate
                    mode=mode
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
                        getSecurityGroupIngressRules(port, cidrBlock, groupId)[0]
                /]
            [#break]
        [/#switch]
    [/#list]
[/#macro]

[#macro createSecurityGroup mode tier component id name description="" ingressRules=""]
    [#local nonemptyIngressRules = [] ]
    [#if ingressRules?has_content && ingressRules?is_sequence]
        [#list ingressRules as ingressRule]
            [#if ingressRule.CIDR?has_content]
                [#local nonemptyIngressRules +=
                            getSecurityGroupIngressRules(
                                ingressRule.Port,
                                ingressRule.CIDR) ]
            [/#if]
        [/#list]
    [/#if]
    [#local properties =
        {
            "GroupDescription" : description?has_content?then(description, name),
            "VpcId" : (vpcId?has_content)?then(
                            getReference(vpcId),
                            vpc
                      )
        }
    ]
    [#if nonemptyIngressRules?has_content]
        [#local properties +=
            {
                "SecurityGroupIngress" : nonemptyIngressRules
            }
        ]
    [/#if]

    [@cfTemplate
        mode=mode
        id=id
        type="AWS::EC2::SecurityGroup"
        properties=properties
        tags=getCfTemplateCoreTags(name, tier, component)
    /]
[/#macro]

[#macro createDependentSecurityGroup
            mode
            tier
            component
            resourceId
            resourceName
            ingressRules=""]
    [@createSecurityGroup 
        mode=mode 
        tier=tier 
        component=component
        id=formatDependentSecurityGroupId(resourceId)
        name=resourceName
        description="Security Group for " + resourceName
        ingressRules=ingressRules /]
[/#macro]

[#macro createComponentSecurityGroup
            mode
            tier
            component
            extensions=""
            ingressRules=""]
    [@createSecurityGroup 
        mode=mode 
        tier=tier 
        component=component
        id=formatComponentSecurityGroupId(
            tier,
            component,
            extensions)
        name=formatComponentFullName(
            tier,
            component,
            extensions)
        ingressRules=ingressRules /]
[/#macro]

[#macro createDependentComponentSecurityGroup
            mode
            tier
            component
            resourceId
            resourceName
            extensions=""
            ingressRules=""]
    [#local legacyId = formatComponentSecurityGroupId(
                        tier,
                        component,
                        extensions)]
    [#if getExistingReference(legacyId)?has_content]
        [@createComponentSecurityGroup 
            mode=mode 
            tier=tier 
            component=component
            extensions=extensions
            ingressRules=ingressRules /]
    [#else]
        [@createDependentSecurityGroup 
            mode=mode 
            tier=tier 
            component=component
            extensions=
                {
                    "Internal" : {
                        "IdExtensions" : [resourceId],
                        "NameExtensions" : [resourceName]
                    }
                }
            ingressRules=ingressRules /]
    [/#if]
[/#macro]

[#macro createFlowLog 
            mode
            id
            roleId
            logGroupName
            resourceId
            resourceType
            trafficType]
    [@cfTemplate 
        mode=mode
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

[#macro createVPC
            mode
            id
            name
            cidr
            dnsSupport
            dnsHostnames]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::EC2::VPC"
        properties=
            {
                "CidrBlock" : cidr,
                "EnableDnsSupport" : dnsSupport,
                "EnableDnsHostnames" : dnsHostnames
            }
        tags=getCfTemplateCoreTags(name)
        outputId=formatVPCId()
    /]
[/#macro]

[#macro createIGW
            mode
            id
            name]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::EC2::InternetGateway"
        tags=getCfTemplateCoreTags(name)
        outputId=formatVPCIGWId()
    /]
[/#macro]

[#macro createIGWAttachment
            mode
            id
            vpcId
            igwId]
    [@cfTemplate
        mode=mode
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
[#assign outputMappings +=
    {
        EIP_RESOURCE_TYPE : EIP_OUTPUT_MAPPINGS
    }
]

[#macro createEIP
            mode
            id
            dependencies=""]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::EC2::EIP"
        properties=
            {
                "Domain" : "vpc"
            }
        outputs=EIP_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

[#macro createNATGateway
            mode,
            id,
            subnetId,
            eipId]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::EC2::NatGateway"
        properties=
            {
                "AllocationId" : getReference(eipId, ALLOCATION_ATTRIBUTE_TYPE),
                "SubnetId" : getReference(subnetId)
            }
    /]
[/#macro]

[#macro createRouteTable
            mode,
            id,
            name,
            vpcId,
            zone=""]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::EC2::RouteTable"
        properties=
            {
                "VpcId" : getReference(vpcId)
            }
        tags=getCfTemplateCoreTags(name,"","",zone)
        outputs={}
    /]
[/#macro]

[#macro createRoute
            mode,
            id,
            routeTableId,
            route]
            
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
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::EC2::Route"
        properties=properties
        outputs={}
    /]
[/#macro]

[#macro createNetworkACL
            mode,
            id,
            name,
            vpcId]
    [@cfTemplate
        mode=mode
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
            mode,
            id,
            networkACLId,
            outbound,
            rule]
    [#switch rule.Protocol]
        [#case "all"]
            [#local properties =
                {
                    "Protocol" : "-1",
                    "PortRange" : {
                        "From" : (rule.PortRange.From)!0,
                        "To" : (rule.PortRange.To)!65535
                    }
                }
            ]
            [#break]
        [#case "icmp"]
            [#local properties =
                {
                    "Protocol" : "1",
                    "Icmp" : {
                        "Code" : (rule.ICMP.Code)!-1,
                        "Type" : (rule.ICMP.Type)!-1
                    }
                }
            ]
            [#break]
        [#case "udp"]
            [#local properties =
                {
                    "Protocol" : "17",
                    "PortRange" : {
                        "From" : (rule.PortRange.From)!0,
                        "To" : (rule.PortRange.To)!65535
                    }
                }
            ]
            [#break]
        [#case "tcp"]
            [#local properties =
                {
                    "Protocol" : "6",
                    "PortRange" : {
                        "From" : (rule.PortRange.From)!0,
                        "To" : (rule.PortRange.To)!65535
                    }
                }
            ]
            [#break]
    [/#switch]
    [@cfTemplate
        mode=mode
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
            mode,
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
    [@cfTemplate
        mode=mode
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
            mode,
            id,
            subnetId,
            routeTableId]
            
    [@cfTemplate
        mode=mode
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
            mode,
            id,
            subnetId,
            networkACLId]
            
    [@cfTemplate
        mode=mode
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
            mode,
            id,
            vpcId,
            service,
            routeTableIds=[]
            statements=[]
]

    [#local routeTableRefs = [] ]
    [#list asArray(routeTableIds) as routeTableId]
        [#local routeTableRefs += [getReference(routeTableId)] ]
    [/#list]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::EC2::VPCEndpoint"
        properties=
            {
                "RouteTableIds" : routeTableRefs,
                "ServiceName" :
                    formatDomainName(
                        "com.amazonaws",
                        region,
                        service),
                "VpcId" : getReference(vpcId)
            } +
            statements?has_content?then(
                getPolicyDocument(statements),
                {}
            )
        outputs={}
    /]
[/#macro]
