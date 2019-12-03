[#ftl]

[#-- Resources --]
[#assign AWS_RDS_RESOURCE_TYPE = "rds" ]
[#assign AWS_RDS_SUBNET_GROUP_RESOURCE_TYPE = "rdsSubnetGroup" ]
[#assign AWS_RDS_PARAMETER_GROUP_RESOURCE_TYPE = "rdsParameterGroup" ]
[#assign AWS_RDS_OPTION_GROUP_RESOURCE_TYPE = "rdsOptionGroup" ]
[#assign AWS_RDS_SNAPSHOT_RESOURCE_TYPE = "rdsSnapShot" ]

[#assign AWS_RDS_CLUSTER_RESOURCE_TYPE = "rdsCluster" ]
[#assign AWS_RDS_CLUSTER_PARAMETER_GROUP_RESOURCE_TYPE = "rdsClusterParameterGroup" ]

[#function formatDependentRDSSnapshotId resourceId extensions... ]
    [#return formatDependentResourceId(
                "snapshot",
                resourceId,
                extensions)]
[/#function]

[#function formatDependentRDSManualSnapshotId resourceId extensions... ]
    [#return formatDependentResourceId(
                "manualsnapshot",
                resourceId,
                extensions)]
[/#function]
