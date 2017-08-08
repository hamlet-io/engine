[#-- VPC --]

[#function getSecurityGroupIngressRules port cidr groupId=""]
    [#local cidrs = cidr?is_sequence?then(
            cidr,
            [cidr]
        )]
    [#local rules = []]
    [#list cidrs as cidrBlock]
        [#local rule = {
                "IpProtocol": ports[port]?has_content?then(
                                    ports[port].IPProtocol,
                                    "-1"),
                "FromPort": ports[port]?has_content?then(
                                    ports[port].Port?c,
                                    "1"),
                "ToPort": ports[port]?has_content?then(
                                    ports[port].Port?c,
                                    "65535")
            }]

        [#if groupId?has_content]
            [#local rule += {
                    "GroupId": getReference(groupId)
                }]
        [/#if]
        [#if cidrBlock?contains("X")]
            [#local rule += {
                    "SourceSecurityGroupId": getReference(cidrBlock)
                }]
        [#else]
            [#if cidrBlock?contains(":") ]
                [#local rule += {
                        "CidrIpv6": cidrBlock
                    }]
            [#else]
                [#local rule += {
                        "CidrIp": cidrBlock
                    }]
            [/#if]
        [/#if]
        [#local rules += [rule]]
    [/#list]
    [#return rules]
[/#function]

[#macro createSecurityGroupIngress mode id port cidr groupId]
    [#local cidrs = cidr?is_sequence?then(
            cidr,
            [cidr]
        )]
    [#list cidrs as cidrBlock]
        [#switch mode]
            [#case "definition"]
                [@cfTemplate
                    mode,
                    formatId(
                        id,
                        (cidrs?size > 1)?then(
                            cidrBlock?index?c,
                            "")),
                    "AWS::EC2::SecurityGroupIngress",
                    getSecurityGroupIngressRules(port, cidrBlock, groupId)[0]
                /]
            [#break]
        [/#switch]
    [/#list]
[/#macro]

[#macro createSecurityGroup mode tier component id name description="" ingressRules=""]
    [#local nonemptyIngressRules = []]
    [#if ingressRules?has_content && ingressRules?is_sequence]
        [#list ingressRules as ingressRule]
            [#if ingressRule.CIDR?has_content]
                [#local nonemptyIngressRules +=
                            getSecurityGroupIngressRules(
                                ingressRule.Port,
                                ingressRule.CIDR)]
            [/#if]
        [/#list]
    [/#if]
    [#local properties = {
            "GroupDescription" : description?has_content?then(description, name),
            "VpcId" : (vpcId?has_content)?then(
                        getReference(vpcId),
                        vpc)
        }]
    [#if nonemptyIngressRules?has_content]
        [#local properties += {
                "SecurityGroupIngress" : nonemptyIngressRules
            }]
    [/#if]

    [@cfTemplate
        mode,
        id,
        "AWS::EC2::SecurityGroup",
        properties,
        [{"UseRef" : true}],
        cfTemplateCoreTags(name, tier, component)
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
        mode 
        tier 
        component
        formatDependentSecurityGroupId(resourceId)
        resourceName
        "Security Group for " + resourceName
        ingressRules /]
[/#macro]

[#macro createComponentSecurityGroup
            mode
            tier
            component
            idExtension=""
            nameExtension=""
            ingressRules=""]
    [@createSecurityGroup 
        mode 
        tier 
        component
        formatComponentSecurityGroupId(
            tier,
            component,
            idExtension)
        formatComponentFullName(
            tier,
            component,
            nameExtension)
        ""
        ingressRules /]
[/#macro]

[#macro createDependentComponentSecurityGroup
            mode
            tier
            component
            resourceId
            resourceName
            idExtension=""
            nameExtension=""
            ingressRules=""]
    [#local legacyId = formatComponentSecurityGroupId(
                        tier,
                        component,
                        idExtension)]
    [#if getKey(legacyId)?has_content]
        [@createComponentSecurityGroup 
            mode 
            tier 
            component
            idExtension
            nameExtension
            ingressRules /]
    [#else]
        [@createDependentSecurityGroup 
            mode 
            tier 
            component
            resourceId
            resourceName
            ingressRules /]
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
    [@cfTemplate mode, id, "AWS::EC2::FlowLog",
        {
            "DeliverLogsPermissionArn" : getArnReference(roleId),
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
    [@cfTemplate mode, id, "AWS::EC2::VPC",
        {
            "CidrBlock" : cidr,
            "EnableDnsSupport" : dnsSupport,
            "EnableDnsHostnames" : dnsHostnames
        },
        [
            { "UseRef" : true, "AlternateId" : formatVPCId() }
        ],
        cfTemplateCoreTags(name)
    /]
[/#macro]

[#macro createIGW
            mode
            id
            name]
    [@cfTemplate mode, id, "AWS::EC2::InternetGateway",
        {},
        [
            { "UseRef" : true, "AlternateId" : formatVPCIGWId() }
        ],
        cfTemplateCoreTags(name)
    /]
[/#macro]

[#macro createIGWAttachment
            mode
            id
            vpcId
            igwId]
    [@cfTemplate mode, id, "AWS::EC2::VPCGatewayAttachment",
        {
            "InternetGatewayId" : { "Ref" : igwId },
            "VpcId" : { "Ref" : vpcId }
        },
        []
    /]
[/#macro]

[#macro createEIP
            mode
            id]
    [@cfTemplate mode, id, "AWS::EC2::EIP",
        {
            "Domain" : "vpc"
        },
        [
            { "Type" : "ip", "UseRef" : true},
            { "Type" : "id", "Attribute" : "AllocationId" },
            { "UseRef" : true}
        ]
    /]
[/#macro]

[#macro createNATGateway
            mode,
            id,
            subnetId,
            eipId]
    [@cfTemplate mode, id, "AWS::EC2::NatGateway",
        {
            "AllocationId" : getKey(formatAllocationAttributeId(eipId)),
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
    [@cfTemplate mode, id, "AWS::EC2::RouteTable",
        {
            "VpcId" : getReference(vpcId)
        },
        [],
        cfTemplateCoreTags(name,"",""zone)
    /]
[/#macro]

[#macro createRoute
            mode,
            id,
            routeTableId,
            route]
            
    [#local properties = {
            "RouteTableId" : getReference(routeTableId),
            "DestinationCidrBlock" : route.CIDR
        }]
    [#switch route.Type]
        [#case "gateway"]
            [#local properties += {
                    "GatewayId" : getReference(route.IgwId)
                }]
            [#break]

        [#case "instance"]
            [#local properties += {
                    "InstanceId" : getReference(route.InstanceId)
                }]
            [#break]
        
        [#case "nat"]
            [#local properties += {
                    "NatGatewayId" : getReference(route.NatId)
                }]
            [#break]
        
    [/#switch]
    [@cfTemplate mode, id, "AWS::EC2::Route",
        properties,
        []
    /]
[/#macro]

[#macro createNetworkACL
            mode,
            id,
            name,
            vpcId]
    [@cfTemplate mode, id, "AWS::EC2::NetworkAcl",
        {
            "VpcId" : getReference(vpcId)
        },
        [],
        cfTemplateCoreTags(name)
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
            [#local properties = {
                    "Protocol" : "-1",
                    "PortRange" : {
                        "From" : (rule.PortRange.From)!0,
                        "To" : (rule.PortRange.To)!65535
                    }
                }]
            [#break]
        [#case "icmp"]
            [#local properties = {
                    "Protocol" : "1",
                    "Icmp" : {
                        "Code" : (rule.ICMP.Code)!-1,
                        "Type" : (rule.ICMP.Type)!-1
                    }
                }]
            [#break]
        [#case "udp"]
            [#local properties = {
                    "Protocol" : "17",
                    "PortRange" : {
                        "From" : (rule.PortRange.From)!0,
                        "To" : (rule.PortRange.To)!65535
                    }
                }]
            [#break]
        [#case "tcp"]
            [#local properties = {
                    "Protocol" : "6",
                    "PortRange" : {
                        "From" : (rule.PortRange.From)!0,
                        "To" : (rule.PortRange.To)!65535
                    }
                }]
            [#break]
    [/#switch]
    [@cfTemplate mode, id, "AWS::EC2::NetworkAclEntry",
        {
            "NetworkAclId" : getReference(networkACLId),
            "Egress" : outbound,
            "RuleNumber" : rule.RuleNumber,
            "RuleAction" : rule.Allow?string("allow","deny"),
            "CidrBlock" : rule.CIDRBlock
        } + properties,
        []
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
    [#local tags = private?then(
        [
            {
                "Key" : "network",
                "Value" : "private"
            }
        ],
        [])]
    [@cfTemplate mode, id, "AWS::EC2::Subnet",
        {
            "VpcId" : getReference(vpcId),
            "AvailabilityZone" : zone.AWSZone,
            "CidrBlock" : cidr
        },
        [
            { "UseRef" : true}
        ],
        tags + cfTemplateCoreTags(name, tier, "", zone)
    /]
[/#macro]

[#macro createRouteTableAssociation
            mode,
            id,
            subnetId
            routeTableId]
            
    [@cfTemplate mode, id, "AWS::EC2::SubnetRouteTableAssociation",
        {
            "SubnetId" : getReference(subnetId),
            "RouteTableId" : getReference(routeTableId)
        },
        []
    /]
[/#macro]

[#macro createNetworkACLAssociation
            mode,
            id,
            subnetId
            networkACLId]
            
    [@cfTemplate mode, id, "AWS::EC2::SubnetNetworkAclAssociation",
        {
            "SubnetId" : getReference(subnetId),
            "NetworkAclId" : getReference(networkACLId)
        },
        []
    /]
[/#macro]



