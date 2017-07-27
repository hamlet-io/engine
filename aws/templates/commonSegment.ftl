[#ftl]

[#-- Macros --]

[#macro createVPCFlowLog mode id vpcId roleId logGroupName trafficType]
    [@createFlowLog 
        mode,
        id,
        roleId,
        logGroupName,
        vpcId,
        "VPC",
        trafficType /]
[/#macro]

[#macro createVPCLogGroup mode id name retention ]
    [#if isPartOfCurrentDeploymentUnit(id)]
        [@createLogGroup 
            mode
            id
            name
            retention /]
    [/#if]
[/#macro]

[#function formatSegmentNamespace]
    [#return formatSegmentFullName()]
[/#function]

[#macro createSegmentCountLogMetric mode id name logGroup filter dependencies=""]
    [@createLogMetric 
        mode,
        id,
        name,
        logGroup,
        filter,
        formatSegmentNamespace(),
        "1"
        dependencies
    /]
[/#macro]

