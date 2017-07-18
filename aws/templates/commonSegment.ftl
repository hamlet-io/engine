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

[#macro createSegmentCountLogMetric mode id name logGroup filter]
    [@createLogMetric 
        mode,
        id,
        name,
        logGroup,
        filter,
        "${formatSegmentFullName()}",
        "1" /]
[/#macro]

