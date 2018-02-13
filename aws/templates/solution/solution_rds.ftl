[#-- RDS --]
[#if (componentType == "rds") ]

    [#assign db = component.RDS]
    
    [#list getOccurrences(component, deploymentUnit) as occurrence]
        [#assign engine = occurrence.Engine]
        [#switch engine]
            [#case "mysql"]
                [#assign engineVersion =
                    occurrence.EngineVersion?has_content?then(
                        occurrence.EngineVersion,
                        "5.6"
                    )
                ]
                [#assign family = "mysql" + engineVersion]
            [#break]

            [#case "postgres"]
                [#assign engineVersion =
                    occurrence.EngineVersion?has_content?then(
                        occurrence.EngineVersion,
                        "9.4"
                    )
                ]
                [#assign family = "postgres" + engineVersion]
                [#break]
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

        [#assign rdsSecurityGroupId = formatDependentComponentSecurityGroupId(
                                        tier, 
                                        component,
                                        rdsId)]
        [#assign rdsSecurityGroupIngressId = formatDependentSecurityGroupIngressId(
                                                rdsSecurityGroupId, 
                                                ports[occurrence.Port].Port?c)]
        [#assign rdsTags = getCfTemplateCoreTags(
                                        rdsFullName,
                                        tier,
                                        component)]

        [#assign processorProfile = getProcessor(tier, component, "RDS")]

        [#if deploymentSubsetRequired("prologue", false)]
            [#if occurrence.SnapShotOnDeploy ]
                [@cfScript
                    mode=listMode
                    content=
                    [
                        "function create_deploy_snapshot() {",
                        "# Create RDS snapshot",
                        "snapshot_arn=$(create_snapshot" + " \"" + 
                        region + "\" \"" + 
                        rdsFullName + "\" " + 
                        "\"pre-deploy\" ) || return $?",
                        "create_pseudo_stack" + " " + 
                        "\"RDS Pre-Deploy Snapshot\"" + " " +
                        "\"$\{pseudo_stack_file}\"" + " " +
                        "\"snapshotX" + rdsId + "\" " + "\"$\{snapshot_arn}\" || return $?", 
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
                port=occurrence.Port
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
                        "Port" : ports[occurrence.Port].Port,
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
                    }
            /]
        [/#if]
    [/#list]
[/#if]
