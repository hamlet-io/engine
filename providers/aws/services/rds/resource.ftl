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

[#assign metricAttributes +=
    {
        AWS_RDS_RESOURCE_TYPE : {
            "Namespace" : "AWS/RDS",
            "Dimensions" : {
                "DBInstanceIdentifier" : {
                    "Output" : ""
                }
            }
        }
    }
]

[#macro createRDSInstance id name
    engine
    engineVersion
    processor
    size
    port
    multiAZ
    encrypted
    kmsKeyId
    masterUsername
    masterPassword
    databaseName
    retentionPeriod
    subnetGroupId
    parameterGroupId
    optionGroupId
    snapshotId
    securityGroupId
    enhancedMonitoring
    enhancedMonitoringInterval
    performanceInsights
    performanceInsightsRetention
    enhancedMonitoringRoleId=""
    tier=""
    component=""
    dependencies=""
    outputId=""
    allowMajorVersionUpgrade=true
    autoMinorVersionUpgrade=true
    deleteAutomatedBackups=true
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
            "EngineVersion": engineVersion,
            "DBInstanceClass" : processor,
            "AllocatedStorage": size,
            "AutoMinorVersionUpgrade": autoMinorVersionUpgrade,
            "AllowMajorVersionUpgrade" : allowMajorVersionUpgrade,
            "DeleteAutomatedBackups" : deleteAutomatedBackups,
            "StorageType" : "gp2",
            "Port" : port,
            "BackupRetentionPeriod" : retentionPeriod,
            "DBInstanceIdentifier": name,
            "DBSubnetGroupName": subnetGroupId,
            "DBParameterGroupName": parameterGroupId,
            "OptionGroupName": optionGroupId,
            "VPCSecurityGroups": [securityGroupId]
        } +
        multiAZ?then(
            {
                "MultiAZ": true
            },
            {
                "AvailabilityZone" : zones[0].AWSZone
            }
        ) +
        (!(snapshotId?has_content) && encrypted)?then(
            {
                "StorageEncrypted" : true,
                "KmsKeyId" : getReference(kmsKeyId, ARN_ATTRIBUTE_TYPE)
            },
            {}
        ) +
        [#-- If restoring from a snapshot the database details will be provided by the snapshot --]
        (snapshotId?has_content)?then(
            {
                "DBSnapshotIdentifier" : snapshotId
            },
            {
                "DBName" : databaseName,
                "MasterUsername": masterUsername,
                "MasterUserPassword": masterPassword
            }
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
    tags=
        getCfTemplateCoreTags(
            name,
            tier,
            component)
    outputs=
        RDS_OUTPUT_MAPPINGS +
        {
            DATABASENAME_ATTRIBUTE_TYPE : {
                "Value" : databaseName
            }
        } +
        attributeIfContent(
            LASTRESTORE_ATTRIBUTE_TYPE,
            snapshotId,
            {
                "Value" : snapshotId
            }
        )
    /]

[/#macro]
