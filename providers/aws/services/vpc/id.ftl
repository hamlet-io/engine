[#ftl]

[#-- Resources --]
[#assign AWS_VPC_RESOURCE_TYPE = "vpc" ]
[#assign AWS_VPC_SUBNET_RESOURCE_TYPE = "subnet" ]
[#assign AWS_VPC_FLOWLOG_RESOURCE_TYPE = "vpcflowlogs" ]

[#assign AWS_VPC_ROUTE_TABLE_RESOURCE_TYPE = "routeTable" ]
[#assign AWS_VPC_ROUTE_RESOURCE_TYPE = "route" ]
[#assign AWS_VPC_NETWORK_ROUTE_TABLE_ASSOCIATION_TYPE = "association" ]

[#assign AWS_VPC_NETWORK_ACL_RESOURCE_TYPE = "networkACL" ]
[#assign AWS_VPC_NETWORK_ACL_RULE_RESOURCE_TYPE = "rule"]
[#assign AWS_VPC_NETWORK_ACL_ASSOCIATION_TYPE = "association" ]

[#assign AWS_VPC_SUBNET_TYPE = "subnet"]

[#assign AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE = "securityGroup" ]
[#assign AWS_VPC_SECURITY_GROUP_INGRESS_RESOURCE_TYPE = "securityGroupIngress" ]

[#assign AWS_VPC_IGW_RESOURCE_TYPE = "igw" ]
[#assign AWS_VPC_IGW_ATTACHMENT_TYPE = formatId( AWS_VPC_IGW_RESOURCE_TYPE, "attachment") ]

[#assign AWS_VPC_NAT_GATEWAY_RESOURCE_TYPE = "natGateway" ]

[#assign AWS_VPC_ENDPOINNT_RESOURCE_TYPE = "vpcEndPoint"]

[#function formatSecurityGroupId ids...]
    [#return formatResourceId(
                AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentSecurityGroupId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#-- Where possible, the dependent resource variant should be used --]
[#-- based on the resource id of the component using the security  --]
[#-- group. This avoids clashes where components has the same id   --]
[#-- but different types                                           --]
[#function formatComponentSecurityGroupId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatDependentComponentSecurityGroupId
            tier
            component
            resourceId
            extensions...]
    [#return
        migrateToResourceId(
            formatDependentSecurityGroupId(resourceId, extensions),
            formatComponentSecurityGroupId(tier, component, extensions)
        )]
[/#function]

[#function formatSecurityGroupIngressId ids...]
    [#return formatResourceId(
                AWS_VPC_SECURITY_GROUP_INGRESS_RESOURCE_TYPE,
                ids)]
[/#function]

[#-- Use the associated security group where possible as the dependent --]
[#-- resource. (It may well in turn be a dependent resource)           --]
[#-- As nothing depends in ingress resources, Cloud Formation will     --]
[#-- deal with deleting the resource with the old format id.           --]
[#function formatDependentSecurityGroupIngressId resourceId extensions...]
    [#return formatDependentResourceId(
                "ingress",
                resourceId,
                extensions)]
[/#function]

[#function formatComponentSecurityGroupIngressId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_VPC_SECURITY_GROUP_INGRESS_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatSSHFromProxySecurityGroupId ]
    [#return
        migrateToResourceId(
            formatComponentSecurityGroupId("all", "ssh"),
            formatComponentSecurityGroupId("mgmt", "nat")
        )]
[/#function]

[#function formatVPCId]
    [#return
        migrateToResourceId(
            formatSegmentResourceId(AWS_VPC_RESOURCE_TYPE),
            formatSegmentResourceId(AWS_VPC_RESOURCE_TYPE, AWS_VPC_RESOURCE_TYPE)
        )]
[/#function]

[#function formatVPCIGWId]
    [#return
        migrateToResourceId(
            formatSegmentResourceId(AWS_VPC_IGW_RESOURCE_TYPE),
            formatSegmentResourceId(AWS_VPC_IGW_RESOURCE_TYPE, AWS_VPC_IGW_RESOURCE_TYPE)
        )]
[/#function]

[#function formatVPCTemplateId]
    [#return
        getExistingReference(
            formatSegmentResourceId(AWS_VPC_RESOURCE_TYPE, AWS_VPC_RESOURCE_TYPE))?has_content?then(
                AWS_VPC_RESOURCE_TYPE,
                formatSegmentResourceId(AWS_VPC_RESOURCE_TYPE)
            )]
[/#function]

[#function formatVPCIGWTemplateId]
    [#return
        getExistingReference(
            formatSegmentResourceId(AWS_VPC_IGW_RESOURCE_TYPE, AWS_VPC_IGW_RESOURCE_TYPE))?has_content?then(
                AWS_VPC_IGW_RESOURCE_TYPE,
                formatSegmentResourceId(AWS_VPC_IGW_RESOURCE_TYPE)
            )]
[/#function]

[#function formatVPCFlowLogsId extensions...]
    [#return formatDependentResourceId(
        AWS_VPC_FLOWLOG_RESOURCE_TYPE,
        formatSegmentResourceId(AWS_VPC_RESOURCE_TYPE),
        extensions)]
[/#function]

[#function formatSubnetId tier zone]
    [#return formatZoneResourceId(
            AWS_VPC_SUBNET_TYPE,
            tier,
            zone)]
[/#function]

[#function formatRouteTableAssociationId subnetId extensions...]
    [#return formatDependentResourceId(
            AWS_VPC_NETWORK_ROUTE_TABLE_ASSOCIATION_TYPE,
            subnetId,
            AWS_VPC_ROUTE_TABLE_RESOURCE_TYPE,
            extensions)]
[/#function]

[#function formatNetworkACLAssociationId subnetId extensions...]
    [#return formatDependentResourceId(
            AWS_VPC_NETWORK_ACL_ASSOCIATION_TYPE,
            subnetId,
            AWS_VPC_NETWORK_ACL_RESOURCE_TYPE,
            extensions)]
[/#function]

[#function formatRouteTableId ids...]
    [#return formatResourceId(
            AWS_VPC_ROUTE_TABLE_RESOURCE_TYPE,
            ids)]
[/#function]

[#function formatRouteId routeTableId extensions...]
    [#return formatDependentResourceId(
            AWS_VPC_ROUTE_RESOURCE_TYPE,
            routeTableId,
            extensions)]
[/#function]

[#function formatNetworkACLId ids...]
    [#return formatResourceId(
            AWS_VPC_NETWORK_ACL_RESOURCE_TYPE,
            ids)]
[/#function]

[#function formatNetworkACLEntryId networkACLId outbound extensions...]
    [#return formatDependentResourceId(
            "rule",
            networkACLId,
            outbound?then("out","in"),
            extensions)]
[/#function]

[#function formatNATGatewayId tier zone]
    [#return formatZoneResourceId(
            AWS_VPC_NAT_GATEWAY_RESOURCE_TYPE,
            tier,
            zone)]
[/#function]

[#function formatVPCEndPointId service extensions...]
    [#return formatSegmentResourceId(
        AWS_VPC_ENDPOINNT_RESOURCE_TYPE,
        service,
        extensions)]
[/#function]







