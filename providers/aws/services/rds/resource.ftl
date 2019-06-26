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
[#assign outputMappings +=
    {
        AWS_RDS_RESOURCE_TYPE : RDS_OUTPUT_MAPPINGS
    }
]

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

[#macro createRDSInstance mode id name
    engine
    engineVersion
    processor
    size
    port
    multiAZ
    encrypted
    masterUsername
    masterPassword
    databaseName
    retentionPeriod
    subnetGroupId
    parameterGroupId
    optionGroupId
    snapshotId
    securityGroupId
    tier=""
    component=""
    dependencies=""
    outputId=""
    autoMinorVersionUpgrade=true
    deleteAutomatedBackups=true
    deletionPolicy="Snapshot"
    updateReplacePolicy="Snapshot"
]
    [@cfResource
    mode=listMode
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
                "KmsKeyId" : getReference(formatSegmentCMKId(), ARN_ATTRIBUTE_TYPE)
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