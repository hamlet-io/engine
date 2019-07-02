[#ftl]

[#-- Macros --]

[#macro createVPCFlowLog id vpcId roleId logGroupName trafficType]
    [@createFlowLog
        id,
        roleId,
        logGroupName,
        vpcId,
        "VPC",
        trafficType /]
[/#macro]

[#macro createVPCLogGroup id name retention ]
    [#if isPartOfCurrentDeploymentUnit(id)]
        [@createLogGroup
            id
            name
            retention /]
    [/#if]
[/#macro]

[#function formatSegmentNamespace]
    [#return formatSegmentFullName()]
[/#function]

[#macro createSegmentCountLogMetric id name logGroup filter dependencies=""]
    [@createLogMetric
        id,
        name,
        logGroup,
        filter,
        formatSegmentNamespace(),
        "1"
        dependencies
    /]
[/#macro]

