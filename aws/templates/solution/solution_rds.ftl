[#-- RDS --]

[#if (componentType == RDS_COMPONENT_TYPE)]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]
        [#assign attributes = occurrence.State.Attributes ]

        [#assign networkLink = getOccurrenceNetwork(occurrence).Link!{} ]

        [#assign networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

        [#if ! networkLinkTarget?has_content ]
            [@cfException listMode "Network could not be found" networkLink /]
            [#break]
        [/#if]

        [#assign networkConfiguration = networkLinkTarget.Configuration.Solution]
        [#assign networkResources = networkLinkTarget.State.Resources ]

        [#assign vpcId = networkResources["vpc"].Id ]

        [#assign engine = solution.Engine]
        [#switch engine]
            [#case "mysql"]
                [#assign engineVersion =
                    valueIfContent(
                        solution.EngineVersion!"",
                        solution.EngineVersion!"",
                        "5.6"
                    )
                ]
                [#assign family = "mysql" + engineVersion]
                [#assign port = solution.Port!"mysql" ]
                [#if (ports[port].Port)?has_content]
                    [#assign port = ports[port].Port ]
                [#else]
                    [@cfException listMode "Unknown Port" port /]
                [/#if]
                [#break]

            [#case "postgres"]
                [#assign engineVersion =
                    valueIfContent(
                        solution.EngineVersion!"",
                        solution.EngineVersion!"",
                        "9.4"
                    )
                ]
                [#assign family = "postgres" + engineVersion]
                [#assign port = solution.Port!"postgresql" ]
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

        [#assign rdsSecurityGroupId =  formatDependentComponentSecurityGroupId(core.Tier, core.Component, rdsId) ]
        [#assign rdsSecurityGroupIngressId = formatDependentSecurityGroupIngressId(
                                                rdsSecurityGroupId,
                                                port)]

        [#assign rdsDatabaseName = solution.DatabaseName!productName]
        [#assign passwordEncryptionScheme = (solution.GenerateCredentials.EncryptionScheme?has_content)?then(
                solution.GenerateCredentials.EncryptionScheme?ensure_ends_with(":"),
                "" )]

        [#if solution.GenerateCredentials.Enabled ]
            [#assign rdsUsername = solution.GenerateCredentials.MasterUserName]
            [#assign rdsPasswordLength = solution.GenerateCredentials.CharacterLength]
            [#assign rdsPassword = "DummyPassword" ]
            [#assign rdsEncryptedPassword = (
                        getExistingReference(
                            rdsId,
                            GENERATEDPASSWORD_ATTRIBUTE_TYPE)
                        )?remove_beginning(
                            passwordEncryptionScheme
                        )]
        [#else]
            [#assign rdsUsername = attributes.USERNAME ]
            [#assign rdsPassword = attributes.PASSWORD ]
        [/#if]

        [#assign hibernate = solution.Hibernate.Enabled  &&
                (getExistingReference(rdsId)?has_content) ]

        [#assign hibernateStartUpMode = solution.Hibernate.StartUpMode ]

        [#assign rdsRestoreSnapshot = getExistingReference(formatDependentRDSSnapshotId(rdsId), NAME_ATTRIBUTE_TYPE)]
        [#assign rdsManualSnapshot = getExistingReference(formatDependentRDSManualSnapshotId(rdsId), NAME_ATTRIBUTE_TYPE)]
        [#assign rdsLastSnapshot = getExistingReference(rdsId, LASTRESTORE_ATTRIBUTE_TYPE )]

        [#assign links = getLinkTargets(occurrence, {}, false) ]
        [#list links as linkId,linkTarget]

            [#assign linkTargetCore = linkTarget.Core ]
            [#assign linkTargetConfiguration = linkTarget.Configuration ]
            [#assign linkTargetResources = linkTarget.State.Resources ]
            [#assign linkTargetAttributes = linkTarget.State.Attributes ]

            [#switch linkTargetCore.Type]
                [#case DATASET_COMPONENT_TYPE]
                    [#if linkTargetConfiguration.Solution.Engine == "rds" ]
                        [#assign rdsManualSnapshot = linkTargetAttributes["SNAPSHOT_NAME"] ]
                    [/#if]
                    [#break]
            [/#switch]
        [/#list]

        [#assign deletionPolicy = solution.Backup.DeletionPolicy]
        [#assign updateReplacePolicy = solution.Backup.UpdateReplacePolicy]

        [#assign segmentKMSKey = getReference(formatSegmentCMKId(), ARN_ATTRIBUTE_TYPE)]

        [#assign rdsPreDeploySnapshotId = formatName(
                                            rdsFullName,
                                            runId,
                                            "pre-deploy")]

        [#assign rdsTags = getOccurrenceCoreTags(occurrence, rdsFullName)]

        [#assign restoreSnapshotName = "" ]

        [#if hibernate && hibernateStartUpMode == "restore" ]
            [#assign restoreSnapshotName = rdsPreDeploySnapshotId ]
        [/#if]

        [#assign preDeploySnapshot = solution.Backup.SnapshotOnDeploy ||
                                ( hibernate && hibernateStartUpMode == "restore" ) ||
                                rdsManualSnapshot?has_content ]

        [#if solution.AlwaysCreateFromSnapshot ]
            [#if !rdsManualSnapshot?has_content ]
                [@cfException
                    mode=listMode
                    description="Snapshot must be provided to create this database"
                    context=occurrence
                    detail="Please provie a manual snapshot or a link to an RDS data set"
                /]
            [/#if]

            [#assign restoreSnapshotName = rdsManualSnapshot ]
            [#assign preDeploySnapshot = false ]

        [/#if]

        [#assign dbParameters = {} ]
        [#list solution.DBParameters as key,value ]
            [#if key != "Name" && key != "Id" ]
                [#assign dbParameters += { key : value }]
            [/#if]
        [/#list]

        [#assign processorProfile = getProcessor(occurrence, "RDS")]

        [#if deploymentSubsetRequired("prologue", false)]
            [@cfScript
                mode=listMode
                content=
                [
                    "case $\{STACK_OPERATION} in",
                    "  create|update)"
                ] +
                [#-- If a manual snapshot has been added the pseudo stack output should be replaced with an automated one --]
                (getExistingReference(rdsId)?has_content)?then(
                    (rdsManualSnapshot?has_content)?then(
                        [
                            "# Check Snapshot MasterUserName",
                            "check_rds_snapshot_username" +
                            " \"" + region + "\" " +
                            " \"" + rdsManualSnapshot + "\" " +
                            " \"" + rdsUsername + "\" || return $?"
                        ],
                        []
                    ) +
                    preDeploySnapshot?then(
                        [
                            "# Create RDS snapshot",
                            "function create_deploy_snapshot() {",
                            "info \"Creating Pre-Deployment snapshot... \"",
                            "create_snapshot" +
                            " \"" + region + "\" " +
                            " \"" + rdsFullName + "\" " +
                            " \"" + rdsPreDeploySnapshotId + "\" || return $?"
                        ] +
                        pseudoStackOutputScript(
                            "RDS Pre-Deploy Snapshot",
                            {
                                formatId("snapshot", rdsId, "name") : rdsPreDeploySnapshotId,
                                formatId("manualsnapshot", rdsId, "name") : ""
                            }
                        ) +
                        [
                            "}",
                            "create_deploy_snapshot || return $?"
                        ],
                        []) +
                    (( solution.Backup.SnapshotOnDeploy ||
                        ( hibernate && hibernateStartUpMode == "restore" ) )
                        && solution.Encrypted)?then(
                        [
                            "# Encrypt RDS snapshot",
                            "function convert_plaintext_snapshot() {",
                            "info \"Checking Snapshot Encryption... \"",
                            "encrypt_snapshot" +
                            " \"" + region + "\" " +
                            " \"" + rdsPreDeploySnapshotId + "\" " +
                            " \"" + segmentKMSKey + "\" || return $?",
                            "}",
                            "convert_plaintext_snapshot || return $?"
                        ],
                        []
                    ),
                    pseudoStackOutputScript(
                        "RDS Manual Snapshot Restore",
                        { formatId("manualsnapshot", rdsId, "name") : restoreSnapshotName }
                    )
                ) +
                [
                    " ;;",
                    " esac"
                ]
            /]
        [/#if]

        [#if deploymentSubsetRequired("rds", true)]

            [@createDependentComponentSecurityGroup
                mode=listMode
                occurrence=occurrence
                resourceId=rdsId
                resourceName=rdsFullName
                vpcId=vpcId
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
                        "SubnetIds" : getSubnets(core.Tier, networkResources)
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
                        "Parameters" : dbParameters
                    }
                tags=getOccurrenceCoreTags(occurrence, rdsFullName)
                outputs={}
            /]

            [@cfResource
                mode=listMode
                id=rdsOptionGroupId
                type="AWS::RDS::OptionGroup"
                deletionPolicy="Retain"
                properties=
                    {
                        "EngineName": engine,
                        "MajorEngineVersion": engineVersion,
                        "OptionGroupDescription" : rdsFullName,
                        "OptionConfigurations" : [
                        ]
                    }
                tags=getOccurrenceCoreTags(occurrence, rdsFullName)
                outputs={}
            /]

            [#switch alternative ]
                [#case "replace1" ]
                    [#assign multiAZ = false]
                    [#assign deletionPolicy = "Delete" ]
                    [#assign updateReplacePolicy = "Delete" ]
                    [#assign rdsFullName=formatName(rdsFullName, "backup") ]
                    [#if rdsManualSnapshot?has_content ]
                        [#assign snapshotId = rdsManualSnapshot ]
                    [#else]
                        [#assign snapshotId = valueIfTrue(
                                rdsPreDeploySnapshotId,
                                solution.Backup.SnapshotOnDeploy,
                                rdsRestoreSnapshot)]
                    [/#if]

                    [#if solution.Backup.UpdateReplacePolicy == "Delete" ]
                        [#assign hibernate = true ]
                    [/#if]
                [#break]

                [#case "replace2"]
                    [#if rdsManualSnapshot?has_content ]
                        [#assign snapshotId = rdsManualSnapshot ]
                    [#else]
                    [#assign snapshotId = valueIfTrue(
                            rdsPreDeploySnapshotId,
                            solution.Backup.SnapshotOnDeploy,
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

            [#if !hibernate]

                [#list solution.Alerts?values as alert ]

                    [#assign monitoredResources = getMonitoredResources(resources, alert.Resource)]
                    [#list monitoredResources as name,monitoredResource ]

                        [@cfDebug listMode monitoredResource false /]

                        [#switch alert.Comparison ]
                            [#case "Threshold" ]
                                [@createCountAlarm
                                    mode=listMode
                                    id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                                    severity=alert.Severity
                                    resourceName=core.FullName
                                    alertName=alert.Name
                                    actions=[
                                        getReference(formatSegmentSNSTopicId())
                                    ]
                                    metric=getMetricName(alert.Metric, monitoredResource.Type, core.ShortFullName)
                                    namespace=getResourceMetricNamespace(monitoredResource.Type)
                                    description=alert.Description!alert.Name
                                    threshold=alert.Threshold
                                    statistic=alert.Statistic
                                    evaluationPeriods=alert.Periods
                                    period=alert.Time
                                    operator=alert.Operator
                                    reportOK=alert.ReportOk
                                    missingData=alert.MissingData
                                    dimensions=getResourceMetricDimensions(monitoredResource, resources)
                                    dependencies=monitoredResource.Id
                                /]
                            [#break]
                        [/#switch]
                    [/#list]
                [/#list]

                [@createRDSInstance
                        mode=listMode
                        id=rdsId
                        name=rdsFullName
                        engine=engine
                        engineVersion=engineVersion
                        processor=processorProfile.Processor
                        size=solution.Size
                        port=port
                        multiAZ=multiAZ
                        encrypted=solution.Encrypted
                        masterUsername=rdsUsername
                        masterPassword=rdsPassword
                        databaseName=rdsDatabaseName
                        retentionPeriod=solution.Backup.RetentionPeriod
                        snapshotId=snapshotId
                        subnetGroupId=getReference(rdsSubnetGroupId)
                        parameterGroupId=getReference(rdsParameterGroupId)
                        optionGroupId=getReference(rdsOptionGroupId)
                        securityGroupId=getReference(rdsSecurityGroupId)
                        autoMinorVersionUpgrade = solution.AutoMinorVersionUpgrade!RDSAutoMinorVersionUpgrade
                        deleteAutomatedBackups = solution.Backup.DeleteAutoBackups
                        deletionPolicy=deletionPolicy
                        updateReplacePolicy=updateReplacePolicy
                    /]
            [/#if]
        [/#if]

        [#if !hibernate ]
            [#if deploymentSubsetRequired("epilogue", false)]

                [#assign rdsFQDN = getExistingReference(rdsId, DNS_ATTRIBUTE_TYPE)]

                [#assign passwordPseudoStackFile = "\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-password-pseudo-stack.json\"" ]
                [#assign urlPseudoStackFile = "\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-url-pseudo-stack.json\""]
                [@cfScript
                    mode=listMode
                    content=
                    [
                        "case $\{STACK_OPERATION} in",
                        "  create|update)"
                    ] +
                    ( solution.GenerateCredentials.Enabled && !(rdsEncryptedPassword?has_content))?then(
                        [
                            "# Generate Master Password",
                            "function generate_master_password() {",
                            "info \"Generating Master Password... \"",
                            "master_password=\"$(generateComplexString" +
                            " \"" + rdsPasswordLength + "\" )\"",
                            "encrypted_master_password=\"$(encrypt_kms_string" +
                            " \"" + region + "\" " +
                            " \"$\{master_password}\" " +
                            " \"" + segmentKMSKey + "\" || return $?)\"",
                            "info \"Setting Master Password... \"",
                            "set_rds_master_password" +
                            " \"" + region + "\" " +
                            " \"" + rdsFullName + "\" " +
                            " \"$\{master_password}\" || return $?"
                        ] +
                        pseudoStackOutputScript(
                                "RDS Master Password",
                                { formatId(rdsId, "generatedpassword") : "$\{encrypted_master_password}" },
                                "password"
                        ) +
                        [
                            "info \"Generating URL... \"",
                            "rds_hostname=\"$(get_rds_hostname" +
                            " \"" + region + "\" " +
                            " \"" + rdsFullName + "\" || return $?)\"",
                            "rds_url=\"$(get_rds_url" +
                            " \"" + engine + "\" " +
                            " \"" + rdsUsername + "\" " +
                            " \"$\{master_password}\" " +
                            " \"$\{rds_hostname}\" " +
                            " \"" + port?c + "\" " +
                            " \"" + rdsDatabaseName + "\" || return $?)\"",
                            "encrypted_rds_url=\"$(encrypt_kms_string" +
                            " \"" + region + "\" " +
                            " \"$\{rds_url}\" " +
                            " \"" + segmentKMSKey + "\" || return $?)\""
                        ] +
                        pseudoStackOutputScript(
                                "RDS Connection URL",
                                { formatId(rdsId, "url") : "$\{encrypted_rds_url}" },
                                "url"
                        ) +
                        [
                            "}",
                            "generate_master_password || return $?"
                        ],
                        []) +
                    (rdsEncryptedPassword?has_content)?then(
                        [
                            "# Reset Master Password",
                            "function reset_master_password() {",
                            "info \"Getting Master Password... \"",
                            "encrypted_master_password=\"" + rdsEncryptedPassword + "\"",
                            "master_password=\"$(decrypt_kms_string" +
                            " \"" + region + "\" " +
                            " \"$\{encrypted_master_password}\" || return $?)\"",
                            "info \"Resetting Master Password... \"",
                            "set_rds_master_password" +
                            " \"" + region + "\" " +
                            " \"" + rdsFullName + "\" " +
                            " \"$\{master_password}\" || return $?",
                            "info \"Generating URL... \"",
                            "rds_hostname=\"$(get_rds_hostname" +
                            " \"" + region + "\" " +
                            " \"" + rdsFullName + "\" || return $?)\"",
                            "rds_url=\"$(get_rds_url" +
                            " \"" + engine + "\" " +
                            " \"" + rdsUsername + "\" " +
                            " \"$\{master_password}\" " +
                            " \"$\{rds_hostname}\" " +
                            " \"" + port?c + "\" " +
                            " \"" + rdsDatabaseName + "\" || return $?)\"",
                            "encrypted_rds_url=\"$(encrypt_kms_string" +
                            " \"" + region + "\" " +
                            " \"$\{rds_url}\" " +
                            " \"" + segmentKMSKey + "\" || return $?)\""
                        ] +
                        pseudoStackOutputScript(
                                "RDS Connection URL",
                                { formatId(rdsId, "url") : "$\{encrypted_rds_url}" },
                                "url"
                        ) +
                        [
                            "}",
                            "reset_master_password || return $?"
                        ],
                    []) +
                    [
                        "       ;;",
                        "       esac"
                    ]
                /]
            [/#if]
        [/#if]
    [/#list]
[/#if]
