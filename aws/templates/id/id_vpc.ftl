[#-- VPC --]

[#-- Resources --]

[#function formatSecurityGroupId ids...]
    [#return formatResourceId(
                "securityGroup",
                ids)]
[/#function]

[#function formatDependentSecurityGroupId resourceId extensions...]
    [#return formatDependentResourceId(
                "securityGroup",
                resourceId,
                extensions)]
[/#function]

[#-- Where possible, the dependent resource variant should be used --]
[#-- based on the resource id of the component using the security  --]
[#-- group. This avoids clashes where components has the same id   --]
[#-- but different types                                           --]
[#function formatComponentSecurityGroupId tier component extensions...]
    [#return formatComponentResourceId(
                "securityGroup",
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
                "securityGroupIngress",
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
                "securityGroupIngress",
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
            formatSegmentResourceId("vpc"),
            formatSegmentResourceId("vpc", "vpc")
        )]
[/#function]

[#function formatVPCIGWId]
    [#return
        migrateToResourceId(
            formatSegmentResourceId("igw"),
            formatSegmentResourceId("igw", "igw")
        )]
[/#function]

[#function formatVPCFlowLogsId extensions...]
    [#return formatDependentResourceId(
        "vpcflowlogs",
        formatSegmentResourceId("vpc"),
        extensions)]
[/#function]

[#-- Legacy functions reflecting inconsistencies in template id naming --]
[#function formatVPCTemplateId]
    [#return
        getExistingReference(
            formatSegmentResourceId("vpc", "vpc"))?has_content?then(
                "vpc",
                formatSegmentResourceId("vpc")
            )]
[/#function]

[#function formatVPCIGWTemplateId]
    [#return
        getExistingReference(
            formatSegmentResourceId("igw", "igw"))?has_content?then(
                "igw",
                formatSegmentResourceId("igw")
            )]
[/#function]

[#function formatSubnetId tier zone]
    [#return formatZoneResourceId(
            "subnet",
            tier,
            zone)]
[/#function]

[#function formatRouteTableAssociationId subnetId extensions...]
    [#return formatDependentResourceId(
            "association",
            subnetId,
            "routeTable",
            extensions)]
[/#function]

[#function formatNetworkACLAssociationId subnetId extensions...]
    [#return formatDependentResourceId(
            "association",
            subnetId,
            "networkACL",
            extensions)]
[/#function]

[#function formatRouteTableId ids...]
    [#return formatResourceId(
            "routeTable",
            ids)]
[/#function]

[#function formatRouteId routeTableId extensions...]
    [#return formatDependentResourceId(
            "route",
            routeTableId,
            extensions)]
[/#function]

[#function formatNetworkACLId ids...]
    [#return formatResourceId(
            "networkACL",
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
            "natGateway",
            tier,
            zone)]
[/#function]

[#function formatVPCEndPointId service extensions...]
    [#return formatSegmentResourceId(
        "vpcEndPoint",
        service,
        extensions)]
[/#function]



