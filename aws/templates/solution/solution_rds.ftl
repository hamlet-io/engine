[#-- RDS --]
[#if (componentType == "rds") ]

    [#assign db = component.RDS]
    
    [#list requiredOccurrences(
            getOccurrences(component, tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]

        [#assign engine = configuration.Engine!""]
        [#switch engine]
            [#case "mysql"]
                [#assign engineVersion =
                    configuration.EngineVersion?has_content?then(
                        configuration.EngineVersion,
                        "5.6"
                    )
                ]
                [#assign family = "mysql" + engineVersion]
                [#assign port = ports[configuration.Port].Port?has_content?then(
                    ports[configuration.Port].Port,
                    "3306"
                )]
                
            [#break]

            [#case "postgres"]
                [#assign engineVersion =
                    configuration.EngineVersion?has_content?then(
                        configuration.EngineVersion,
                        "9.4"
                    )
                ]
                [#assign family = "postgres" + engineVersion]
                [#assign port = ports[configuration.Port].Port?has_content?then(
                    ports[configuration.Port].Port,
                    "5432"
                )]
            [#break]

            [#default]
                [@cfPreconditionFailed listMode "solution_rds" occurrence "No Engine Provided" /]
        [/#switch]

        [#assign rdsId = formatRDSId(tier, component, occurrence)]
        [#assign rdsFullName = formatComponentFullName(tier, component, occurrence)]
        [#assign rdsSubnetGroupId = formatRDSSubnetGroupId(tier, component, occurrence)]
        [#assign rdsParameterGroupId = formatRDSParameterGroupId(tier, component, occurrence)]
        [#assign rdsOptionGroupId = formatRDSOptionGroupId(tier, component, occurrence)]
        [#assign rdsCredentials = credentialsObject[componentShortNameWithType]!
                                    credentialsObject[componentShortName]]
        [#assign rdsUsername = rdsCredentials.Login.Username]
        [#assign rdsPassword = rdsCredentials.Login.Password]
        [#assign rdsRestoreSnapshot = getExistingReference(formatDependentRDSSnapshotId(rdsId), "ARN_ATTRIBUTE_TYPE") ]
        [#assign rdsLastSnapshot = getExistingReference(rdsId, "LASTRESTORE_ATTRIBUTE_TYPE") ]

        [#assign rdsSecurityGroupId = formatDependentComponentSecurityGroupId(
                                        tier, 
                                        component,
                                        rdsId)]
        [#assign rdsSecurityGroupIngressId = formatDependentSecurityGroupIngressId(
                                                rdsSecurityGroupId, 
                                                port)]
        [#assign rdsTags = getCfTemplateCoreTags(
                                        rdsFullName,
                                        tier,
                                        component)]

        [#assign processorProfile = getProcessor(tier, component, "RDS")]

        [#if deploymentSubsetRequired("prologue", false)]
            [#if configuration.SnapShotOnDeploy ]
                [@cfScript
                    mode=listMode
                    content=
                    [
                        "function create_deploy_snapshot() {",
                        "# Create RDS snapshot",
                        "info \"Creating Pre-Deployment snapshot\"",
                        "snapshot_arn=$(create_snapshot" + " \"" + 
                        region + "\" \"" + 
                        rdsFullName + "\" " + 
                        "\"pre-deploy\" ) || return $?",
                        "create_pseudo_stack" + " " + 
                        "\"RDS Pre-Deploy Snapshot\"" + " " +
                        "\"$\{pseudo_stack_file}\"" + " " +
                        "\"snapshotX" + rdsId + "Xarn\" " + "\"$\{snapshot_arn}\" || return $?", 
                        "}",
                        "pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-snapshot-pseudo-stack.json\" ",
                        "create_deploy_snapshot || return $?"
                    ]
                /]
            [/#if]
        [/#if]

        [#if deploymentSubsetRequired("rds", true)]
            [@createDependentComponentSecurityGroup
                mode=listMode
                tier=tier
                component=component
                resourceId=rdsId
                resourceName=rdsFullName
            /]
                
            [@createSecurityGroupIngress
                mode=listMode
                id=rdsSecurityGroupIngressId
                port=port
                cidr="0.0.0.0/0"
                groupId=rdsSecurityGroupId
            /]
            
            [@cfResource
                mode=listMode
                id=rdsSubnetGroupId
                type="AWS::RDS::DBSubnetGroup"
                properties=
                    {
                        "DBSubnetGroupDescription" : rdsFullName,
                        "SubnetIds" : getSubnets(tier)
                    }
                tags=rdsTags
                outputs={}
            /]

            [@cfResource
                mode=listMode
                id=rdsParameterGroupId
                type="AWS::RDS::DBParameterGroup"
                properties=
                    {
                        "Family" : family,
                        "Description" : rdsFullName,
                        "Parameters" : {
                        }
                    }
                tags=
                    getCfTemplateCoreTags(
                        rdsFullName,
                        tier,
                        component)
                outputs={}
            /]

            [@cfResource
                mode=listMode
                id=rdsOptionGroupId
                type="AWS::RDS::OptionGroup"
                properties=
                    {
                        "EngineName": engine,
                        "MajorEngineVersion": engineVersion,
                        "OptionGroupDescription" : rdsFullName,
                        "OptionConfigurations" : [
                        ]
                    }
                tags=
                    getCfTemplateCoreTags(
                        rdsFullName,
                        tier,
                        component)
                outputs={}
            /]

            [#if replacement?has_content && replacement == "replace1" ]
               [@cfResource 
                    mode=listMode
                    id=rdsId
                    type="AWS::RDS::DBInstance"
                    properties=
                        {
                            "Engine": engine,
                            "EngineVersion": engineVersion,
                            "DBInstanceClass" : processorProfile.Processor,
                            "AllocatedStorage": occurrence.Size,
                            "StorageType" : "gp2",
                            "Port" : port,
                            "MasterUsername": rdsUsername,
                            "MasterUserPassword": rdsPassword,
                            "BackupRetentionPeriod" : occurrence.Backup.RetentionPeriod,
                            "DBInstanceIdentifier": formatName(rdsFullName, "backup"),
                            "DBName": productName,
                            "DBSubnetGroupName": getReference(rdsSubnetGroupId),
                            "DBParameterGroupName": getReference(rdsParameterGroupId),
                            "OptionGroupName": getReference(rdsOptionGroupId),
                            "VPCSecurityGroups":[getReference(rdsSecurityGroupId)]
                        } +
                        multiAZ?then(
                            {
                                "MultiAZ": true
                            },
                            {
                                "AvailabilityZone" : zones[0].AWSZone
                            }
                        ) + 
                        attributeIfContent(
                            "DBSnapshotIdentifier"
                            rdsRestoreSnapshot,
                            rdsRestoreSnapshot
                        ) + 
                        occurrence.Encrypted?then(
                            {
                                "StorageEncrypted" : true,
                                "KmsKeyId" : getReference(formatSegmentCMKId(), ARN_ATTRIBUTE_TYPE)
                            }
                        )
                    tags=
                        getCfTemplateCoreTags(
                            rdsFullName,
                            tier,
                            component)
                    outputs=
                        RDS_OUTPUT_MAPPINGS +
                        {
                            DATABASENAME_ATTRIBUTE_TYPE : { 
                                "Value" : productName
                            }
                        } +
                        attributeIfContent(
                            LASTRESTORE_ATTRIBUTE_TYPE,
                            rdsRestoreSnapshot,
                            {
                                "Value" : rdsRestoreSnapshot
                            }
                        )
                /]

            [#else]
                [@cfResource
                    mode=listMode
                    id=rdsId
                    type="AWS::RDS::DBInstance"
                    properties=
                        {
                            "Engine": engine,
                            "EngineVersion": engineVersion,
                            "DBInstanceClass" : processorProfile.Processor,
                            "AllocatedStorage": occurrence.Size,
                            "StorageType" : "gp2",
                            "Port" : port,
                            "MasterUsername": rdsUsername,
                            "MasterUserPassword": rdsPassword,
                            "BackupRetentionPeriod" : occurrence.Backup.RetentionPeriod,
                            "DBInstanceIdentifier": rdsFullName,
                            "DBName": productName,
                            "DBSubnetGroupName": getReference(rdsSubnetGroupId),
                            "DBParameterGroupName": getReference(rdsParameterGroupId),
                            "OptionGroupName": getReference(rdsOptionGroupId),
                            "VPCSecurityGroups":[getReference(rdsSecurityGroupId)]
                        } +
                        multiAZ?then(
                            {
                                "MultiAZ": true
                            },
                            {
                                "AvailabilityZone" : zones[0].AWSZone
                            }
                        ) + 
                        attributeIfContent(
                            "DBSnapshotIdentifier",
                            rdsLastSnapshot,
                            rdsLastSnapshot
                        )
                    tags=
                        getCfTemplateCoreTags(
                            rdsFullName,
                            tier,
                            component)
                    outputs=
                        RDS_OUTPUT_MAPPINGS +
                        {
                            DATABASENAME_ATTRIBUTE_TYPE : { 
                                "Value" : productName
                            }
                        } +
                        attributeIfContent(
                            LASTRESTORE_ATTRIBUTE_TYPE,
                            rdsRestoreSnapshot,
                            {
                                "Value" : rdsRestoreSnapshot
                            }
                        )
                /]
            [/#if]
             
        [/#if]
    [/#list]
[/#if]
