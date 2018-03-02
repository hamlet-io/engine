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
        [#assign rdsRestoreSnapshot = getExistingReference(formatDependentRDSSnapshotId(rdsId), NAME_ATTRIBUTE_TYPE) ]
        [#assign rdsLastSnapshot = getExistingReference(rdsId, LASTRESTORE_ATTRIBUTE_TYPE ) ]

        [#assign noise = random.nextLong()?string.computer?replace("-","X")]
        [#assign rdsPreDeploySnapshotId = formatName(
                                            rdsFullName,
                                            noise,
                                            "pre-deploy")]

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
            [#if configuration.Backup.SnapshotOnDeploy ]
                [@cfScript
                    mode=listMode
                    content=
                    [
                        "function create_deploy_snapshot() {",
                        "# Create RDS snapshot",
                        "info \"Creating Pre-Deployment snapshot\"",
                        "create_snapshot" + 
                        " \"" + region + "\" " + 
                        " \"" + rdsFullName + "\" " + 
                        " \"" + rdsPreDeploySnapshotId + "\" || return $?",
                        "create_pseudo_stack" + " " + 
                        "\"RDS Pre-Deploy Snapshot\"" + " " +
                        "\"$\{pseudo_stack_file}\"" + " " +
                        "\"snapshotX" + rdsId + "Xname\" " + "\"" + rdsPreDeploySnapshotId + "\" || return $?", 
                        "}",
                        "pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-pseudo-stack.json\" ",
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
            
            [#switch alternative ]

                [#case "replace1" ]

                    [#assign rdsRestoreName=formatName(rdsFullName, "backup") ]

                    [@createRDSInstance 
                        mode=listMode
                        id=rdsId
                        name=rdsRestoreName
                        engine=engine
                        engineVersion=engineVersion
                        processor=processorProfile.Processor
                        size=configuration.Size
                        port=port
                        multiAZ=multiAZ
                        encrypted=configuration.Encrypted
                        masterUsername=rdsUsername
                        masterPassword=rdsPassword
                        databaseName=productName
                        retentionPeriod=configuration.Backup.RetentionPeriod
                        snapshotId=valueIfTrue(
                            rdsPreDeploySnapshotId,
                            configuration.Backup.SnapshotOnDeploy,
                            rdsRestoreSnapshot)
                        subnetGroupId=getReference(rdsSubnetGroupId)
                        parameterGroupId=getReference(rdsParameterGroupId)
                        optionGroupId=getReference(rdsOptionGroupId)
                        securityGroupId=getReference(rdsSecurityGroupId)
                    /]
                [#break]

                [#case "replace2"]
                    [@createRDSInstance 
                        mode=listMode
                        id=rdsId
                        name=rdsFullName
                        engine=engine
                        engineVersion=engineVersion
                        processor=processorProfile.Processor
                        size=configuration.Size
                        port=port
                        multiAZ=multiAZ
                        encrypted=configuration.Encrypted
                        masterUsername=rdsUsername
                        masterPassword=rdsPassword
                        databaseName=productName
                        retentionPeriod=configuration.Backup.RetentionPeriod
                        snapshotId=valueIfTrue(
                            rdsPreDeploySnapshotId,
                            configuration.Backup.SnapshotOnDeploy,
                            rdsRestoreSnapshot)
                        subnetGroupId=getReference(rdsSubnetGroupId)
                        parameterGroupId=getReference(rdsParameterGroupId)
                        optionGroupId=getReference(rdsOptionGroupId)
                        securityGroupId=getReference(rdsSecurityGroupId)
                    /]
           
                [#break]

                [#default]
                    [@createRDSInstance 
                        mode=listMode
                        id=rdsId
                        name=rdsFullName
                        engine=engine
                        engineVersion=engineVersion
                        processor=processorProfile.Processor
                        size=configuration.Size
                        port=port
                        multiAZ=multiAZ
                        encrypted=configuration.Encrypted
                        masterUsername=rdsUsername
                        masterPassword=rdsPassword
                        databaseName=productName
                        retentionPeriod=configuration.Backup.RetentionPeriod
                        snapshotId=rdsLastSnapshot
                        subnetGroupId=getReference(rdsSubnetGroupId)
                        parameterGroupId=getReference(rdsParameterGroupId)
                        optionGroupId=getReference(rdsOptionGroupId)
                        securityGroupId=getReference(rdsSecurityGroupId)
                    /]
                [/#switch]
        [/#if]
    [/#list]
[/#if]
