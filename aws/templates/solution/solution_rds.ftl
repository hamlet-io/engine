[#-- RDS --]
[#if (componentType == "rds")]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]
        [#assign resources = occurrence.State.Resources ]

        [#assign engine = configuration.Engine]
        [#switch engine]
            [#case "mysql"]
                [#assign engineVersion =
                    valueIfContent(
                        configuration.EngineVersion!"",
                        configuration.EngineVersion!"",
                        "5.6"
                    )
                ]
                [#assign family = "mysql" + engineVersion]
                [#assign port = configuration.Port!"mysql" ]
                [#if (ports[port].Port)?has_content]
                    [#assign port = ports[port].Port ]
                [#else]
                    [@cfException listMode "Unknown Port" port /]
                [/#if]                
                [#break]

            [#case "postgres"]
                [#assign engineVersion =
                    valueIfContent(
                        configuration.EngineVersion!"",
                        configuration.EngineVersion!"",
                        "9.4"
                    )
                ]
                [#assign family = "postgres" + engineVersion]
                [#assign port = configuration.Port!"postgresql" ]
                [#if (ports[port].Port)?has_content]
                    [#assign port = ports[port].Port ]
                [#else]
                    [@cfException listMode "Unknown Port" port /]
                [/#if]
                [#break]

            [#default]
                [@cfPreconditionFailed listMode "solution_rds" occurrence "Unsupported engine provided" /]
                [#assign engineVersion = "unknown" ]
                [#assign family = "unknown" ]
                [#assign port = "unknown" ]
                [#break]
        [/#switch]

        [#assign rdsId = resources["db"].Id ]
        [#assign rdsFullName = resources["db"].Name ]
        [#assign rdsSubnetGroupId = resources["subnetGroup"].Id ]
        [#assign rdsParameterGroupId = resources["parameterGroup"].Id ]
        [#assign rdsOptionGroupId = resources["optionGroup"].Id ]
        [#assign rdsCredentials =
            credentialsObject[formatComponentShortNameWithType(tier, component)]!
            credentialsObject[formatComponentShortName(tier, component)]!
            {
                "Login" : {
                    "Username" : "Not provided",
                    "Password" : "Not provided"
                }
            } ]
        [#assign rdsUsername = rdsCredentials.Login.Username]
        [#assign rdsPassword = rdsCredentials.Login.Password]
        [#assign rdsRestoreSnapshot = getExistingReference(formatDependentRDSSnapshotId(rdsId), NAME_ATTRIBUTE_TYPE)]
        [#assign rdsManualSnapshot = getExistingReference(formatDependentRDSManualSnapshotId(rdsId), NAME_ATTRIBUTE_TYPE)]
        [#assign rdsLastSnapshot = getExistingReference(rdsId, LASTRESTORE_ATTRIBUTE_TYPE )]

        [#assign rdsPreDeploySnapshotId = formatName(
                                            rdsFullName,
                                            runId,
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
            [#-- If a manual snapshot has been added the pseudo stack has be replaced with an automated one --]
            [#if configuration.Backup.SnapshotOnDeploy || rdsManualSnapshot?has_content ]
                [@cfScript
                    mode=listMode
                    content=
                    [
                        "function create_deploy_snapshot() {",
                        "# Create RDS snapshot",
                        "info \"Creating Pre-Deployment snapshot... \"",
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
                    [#assign rdsFullName=formatName(rdsFullName, "backup") ]
                    [#if rdsManualSnapshot?has_content ]
                        [#assign snapshotId = rdsManualSnapshot ]
                    [#else]
                        [#assign snapshotId = valueIfTrue(
                                rdsPreDeploySnapshotId,
                                configuration.Backup.SnapshotOnDeploy,
                                rdsRestoreSnapshot)]
                    [/#if]
                [#break]

                [#case "replace2"]
                    [#if rdsManualSnapshot?has_content ]
                        [#assign snapshotId = rdsManualSnapshot ]
                    [#else]
                    [#assign snapshotId = valueIfTrue(
                            rdsPreDeploySnapshotId,
                            configuration.Backup.SnapshotOnDeploy,
                            rdsRestoreSnapshot)]
                    [/#if]
                [#break]

                [#default]
                    [#if rdsManualSnapshot?has_content ]
                        [#assign snapshotId = rdsManualSnapshot ]
                    [#else]
                        [#assign snapshotId = rdsLastSnapshot]
                    [/#if]
            [/#switch]

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
                    snapshotId=snapshotId
                    subnetGroupId=getReference(rdsSubnetGroupId)
                    parameterGroupId=getReference(rdsParameterGroupId)
                    optionGroupId=getReference(rdsOptionGroupId)
                    securityGroupId=getReference(rdsSecurityGroupId)
                    autoMinorVersionUpgrade = configuration.AutoMinorVersionUpgrade!RDSAutoMinorVersionUpgrade
                /]
        [/#if]
    [/#list]
[/#if]
