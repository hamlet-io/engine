[#ftl]

[#assign RDS_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        DNS_ATTRIBUTE_TYPE : {
            "Attribute" : "Endpoint.Address"
        },
        PORT_ATTRIBUTE_TYPE : {
            "Attribute" : "Endpoint.Port"
        },
        REGION_ATTRIBUTE_TYPE : {
            "Value" : { "Ref" : "AWS::Region" }
        }
    }
]
[@addOutputMapping
    provider=AWS_PROVIDER
    resourceType=AWS_RDS_RESOURCE_TYPE
    mappings=RDS_OUTPUT_MAPPINGS
/]

[#assign RDS_CLUSTER_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        DNS_ATTRIBUTE_TYPE : {
            "Attribute" : "Endpoint.Address"
        },
        PORT_ATTRIBUTE_TYPE : {
            "Attribute" : "Endpoint.Port"
        },
        "read" + DNS_ATTRIBUTE_TYPE : {
            "Attribute" : "ReadEndpoint.Address"
        }
    }

]
[@addOutputMapping
    provider=AWS_PROVIDER
    resourceType=AWS_RDS_CLUSTER_RESOURCE_TYPE
    mappings=RDS_CLUSTER_OUTPUT_MAPPINGS
/]

[#assign metricAttributes +=
    {
        AWS_RDS_RESOURCE_TYPE : {
            "Namespace" : "AWS/RDS",
            "Dimensions" : {
                "DBInstanceIdentifier" : {
                    "Output" : ""
                }
            }
        },
        AWS_RDS_CLUSTER_RESOURCE_TYPE : {
            "Namespace" : "AWS/RDS",
            "Dimensions" : {
                "DBClusterIdentifier" : {
                    "Output" : ""
                }
            }
        }
    }
]

[#macro createRDSInstance id name
    engine
    processor
    availabilityZone
    subnetGroupId
    parameterGroupId
    optionGroupId
    securityGroupId
    enhancedMonitoring
    enhancedMonitoringInterval
    performanceInsights
    performanceInsightsRetention
    tags
    caCertificate
    engineVersion=""
    clusterMember=false
    clusterId=""
    clusterPromotionTier=""
    multiAZ=false
    encrypted=false
    kmsKeyId=""
    masterUsername=""
    masterPassword=""
    databaseName=""
    port=""
    retentionPeriod=""
    size=""
    snapshotArn=""
    dependencies=""
    outputId=""
    allowMajorVersionUpgrade=true
    autoMinorVersionUpgrade=true
    deleteAutomatedBackups=true
    enhancedMonitoringRoleId=""
    deletionPolicy="Snapshot"
    updateReplacePolicy="Snapshot"
]
    [@cfResource
    id=id
    type="AWS::RDS::DBInstance"
    deletionPolicy=deletionPolicy
    updateReplacePolicy=updateReplacePolicy
    properties=
        {
            "Engine": engine,
            "DBInstanceClass" : processor,
            "AutoMinorVersionUpgrade": autoMinorVersionUpgrade,
            "AllowMajorVersionUpgrade" : allowMajorVersionUpgrade,
            "DeleteAutomatedBackups" : deleteAutomatedBackups,
            "DBSubnetGroupName": getReference(subnetGroupId),
            "DBParameterGroupName": getReference(parameterGroupId),
            "OptionGroupName": getReference(optionGroupId),
            "CACertificateIdentifier" : caCertificate
        } +
        valueIfTrue(
            {
                "AllocatedStorage": size,
                "StorageType" : "gp2",
                "BackupRetentionPeriod" : retentionPeriod,
                "DBInstanceIdentifier": name,
                "VPCSecurityGroups": asArray( getReference(securityGroupId)),
                "Port" : port,
                "EngineVersion": engineVersion
            },
            ( !clusterMember ),
            {
                "DBClusterIdentifier" : getReference(clusterId),
                "PromotionTier" : clusterPromotionTier
            }

        ) +
        valueIfTrue(
            {
                "MultiAZ": true
            },
            ( multiAZ && !clusterMember ),
            {
                "AvailabilityZone" : availabilityZone
            }
        ) +
        valueIfTrue(
            {
                "StorageEncrypted" : true,
                "KmsKeyId" : getReference(kmsKeyId, ARN_ATTRIBUTE_TYPE)
            },
            ( (!(snapshotArn?has_content) && encrypted) && !clusterMember )
        ) +
        [#-- If restoring from a snapshot the database details will be provided by the snapshot --]
        valueIfTrue(
            valueIfTrue(
                {
                    "DBSnapshotIdentifier" : snapshotArn
                },
                snapshotArn?has_content,
                {
                    "DBName" : databaseName,
                    "MasterUsername": masterUsername,
                    "MasterUserPassword": masterPassword
                }
            ),
            !clusterMember
        ) +
        performanceInsights?then(
            {
                "EnablePerformanceInsights" : performanceInsights,
                "PerformanceInsightsRetentionPeriod" : performanceInsightsRetention,
                "PerformanceInsightsKMSKeyId" : getReference(kmsKeyId, ARN_ATTRIBUTE_TYPE)
            },
            {}
        ) +
        enhancedMonitoring?then(
            {
                "MonitoringInterval" : enhancedMonitoringInterval,
                "MonitoringRoleArn" : getReference(enhancedMonitoringRoleId, ARN_ATTRIBUTE_TYPE)
            },
            {}
        )
    tags=tags
    outputs=
        RDS_OUTPUT_MAPPINGS +
        attributeIfContent(
            DATABASENAME_ATTRIBUTE_TYPE,
            databaseName,
            {
                "Value" : databaseName
            }
        ) +
        attributeIfContent(
            LASTRESTORE_ATTRIBUTE_TYPE,
            snapshotArn,
            {
                "Value" : snapshotArn
            }
        )
    /]
[/#macro]

[#macro createRDSCluster id name
    engine
    engineVersion
    port
    encrypted
    kmsKeyId
    masterUsername
    masterPassword
    databaseName
    retentionPeriod
    subnetGroupId
    parameterGroupId
    snapshotArn
    securityGroupId
    tags
    dependencies=""
    outputId=""
    deletionPolicy="Snapshot"
    updateReplacePolicy="Snapshot"
]
    [#local availabilityZones = []]
    [#list zones as zone ]
        [#local availabilityZones += [ zone.AWSZone ] ]
    [/#list]

    [@cfResource
        id=id
        type="AWS::RDS::DBCluster"
        deletionPolicy=deletionPolicy
        updateReplacePolicy=updateReplacePolicy
        properties=
            {
                "DBClusterIdentifier" : name,
                "DBClusterParameterGroupName" : parameterGroupId,
                "DBSubnetGroupName" : subnetGroupId,
                "Port" : port,
                "VpcSecurityGroupIds" : asArray(securityGroupId),
                "AvailabilityZones" : availabilityZones,
                "Engine" : engine,
                "EngineVersion" : engineVersion,
                "BackupRetentionPeriod" : retentionPeriod
            } +
            (!(snapshotArn?has_content) && encrypted)?then(
                {
                    "StorageEncrypted" : true,
                    "KmsKeyId" : getReference(kmsKeyId, ARN_ATTRIBUTE_TYPE)
                },
                {}
            ) +
            [#-- If restoring from a snapshot the database details will be provided by the snapshot --]
            (snapshotArn?has_content)?then(
                {
                    "DBSnapshotIdentifier" : snapshotArn
                },
                {
                    "DatabaseName" : databaseName,
                    "MasterUsername": masterUsername,
                    "MasterUserPassword": masterPassword
                }
            )
        tags=tags
        outputs=RDS_CLUSTER_OUTPUT_MAPPINGS +
        {
            DATABASENAME_ATTRIBUTE_TYPE : {
                "Value" : databaseName
            }
        } +
        attributeIfContent(
            LASTRESTORE_ATTRIBUTE_TYPE,
            snapshotArn,
            {
                "Value" : snapshotArn
            }
        )
    /]
[/#macro]
