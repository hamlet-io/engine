[#ftl]
[#macro aws_db_cf_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan
            subsets=["prologue", "template", "epilogue"]
            alternatives=["primary", "replace1", "replace2"]
        /]
        [#return]
    [/#if]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]
    [#local attributes = occurrence.State.Attributes ]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "OpsData", "AppData", "Encryption", "SSHKey" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local cmkKeyId = baselineComponentIds["Encryption"] ]
    [#local cmkKeyArn = getReference(cmkKeyId, ARN_ATTRIBUTE_TYPE)]

    [#local networkLink = getOccurrenceNetwork(occurrence).Link!{} ]

    [#local networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

    [#if ! networkLinkTarget?has_content ]
        [@fatal message="Network could not be found" context=networkLink /]
        [#return]
    [/#if]

    [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
    [#local networkResources = networkLinkTarget.State.Resources ]

    [#local vpcId = networkResources["vpc"].Id ]

    [#local engine = solution.Engine]
    [#switch engine]
        [#case "mysql"]
            [#local engineVersion =
                valueIfContent(
                    solution.EngineVersion!"",
                    solution.EngineVersion!"",
                    "5.6"
                )
            ]
            [#local family = "mysql" + engineVersion]
            [#local port = solution.Port!"mysql" ]
            [#if (ports[port].Port)?has_content]
                [#local port = ports[port].Port ]
            [#else]
                [@fatal message="Unknown Port" context=port /]
            [/#if]
            [#break]

        [#case "postgres"]
            [#local engineVersion =
                valueIfContent(
                    solution.EngineVersion!"",
                    solution.EngineVersion!"",
                    "9.4"
                )
            ]
            [#local family = "postgres" + engineVersion]
            [#local port = solution.Port!"postgresql" ]
            [#if (ports[port].Port)?has_content]
                [#local port = ports[port].Port ]
            [#else]
                [@fatal message="Unknown Port" context=port /]
            [/#if]
            [#break]

        [#default]
            [@precondition
                function="solution_rds"
                context=occurrence
                detail="Unsupported engine provided"
            /]
            [#local engineVersion = "unknown" ]
            [#local family = "unknown" ]
            [#local port = "unknown" ]
            [#break]
    [/#switch]

    [#local rdsId = resources["db"].Id ]
    [#local rdsFullName = resources["db"].Name ]
    [#local rdsSubnetGroupId = resources["subnetGroup"].Id ]
    [#local rdsParameterGroupId = resources["parameterGroup"].Id ]
    [#local rdsOptionGroupId = resources["optionGroup"].Id ]

    [#local rdsSecurityGroupId =  formatDependentComponentSecurityGroupId(core.Tier, core.Component, rdsId) ]
    [#local rdsSecurityGroupIngressId = formatDependentSecurityGroupIngressId(
                                            rdsSecurityGroupId,
                                            port)]

    [#local rdsDatabaseName = solution.DatabaseName!productName]
    [#local passwordEncryptionScheme = (solution.GenerateCredentials.EncryptionScheme?has_content)?then(
            solution.GenerateCredentials.EncryptionScheme?ensure_ends_with(":"),
            "" )]

    [#if solution.GenerateCredentials.Enabled ]
        [#local rdsUsername = solution.GenerateCredentials.MasterUserName]
        [#local rdsPasswordLength = solution.GenerateCredentials.CharacterLength]
        [#local rdsPassword = "DummyPassword" ]
        [#local rdsEncryptedPassword = (
                    getExistingReference(
                        rdsId,
                        GENERATEDPASSWORD_ATTRIBUTE_TYPE)
                    )?remove_beginning(
                        passwordEncryptionScheme
                    )]
    [#else]
        [#local rdsUsername = attributes.USERNAME ]
        [#local rdsPassword = attributes.PASSWORD ]
    [/#if]

    [#local hibernate = solution.Hibernate.Enabled && isOccurrenceDeployed(occurrence)]

    [#local hibernateStartUpMode = solution.Hibernate.StartUpMode ]

    [#local rdsRestoreSnapshot = getExistingReference(formatDependentRDSSnapshotId(rdsId), NAME_ATTRIBUTE_TYPE)]
    [#local rdsManualSnapshot = getExistingReference(formatDependentRDSManualSnapshotId(rdsId), NAME_ATTRIBUTE_TYPE)]
    [#local rdsLastSnapshot = getExistingReference(rdsId, LASTRESTORE_ATTRIBUTE_TYPE )]

    [#local links = getLinkTargets(occurrence, {}, false) ]
    [#list links as linkId,linkTarget]

        [#local linkTargetCore = linkTarget.Core ]
        [#local linkTargetConfiguration = linkTarget.Configuration ]
        [#local linkTargetResources = linkTarget.State.Resources ]
        [#local linkTargetAttributes = linkTarget.State.Attributes ]

        [#switch linkTargetCore.Type]
            [#case DATASET_COMPONENT_TYPE]
                [#if linkTargetConfiguration.Solution.Engine == "rds" ]
                    [#local rdsManualSnapshot = linkTargetAttributes["SNAPSHOT_NAME"] ]
                [/#if]
                [#break]
        [/#switch]
    [/#list]

    [#local deletionPolicy = solution.Backup.DeletionPolicy]
    [#local updateReplacePolicy = solution.Backup.UpdateReplacePolicy]

    [#local rdsPreDeploySnapshotId = formatName(
                                        rdsFullName,
                                        runId,
                                        "pre-deploy")]

    [#local rdsTags = getOccurrenceCoreTags(occurrence, rdsFullName)]

    [#local restoreSnapshotName = "" ]

    [#if hibernate && hibernateStartUpMode == "restore" ]
        [#local restoreSnapshotName = rdsPreDeploySnapshotId ]
    [/#if]

    [#local preDeploySnapshot = solution.Backup.SnapshotOnDeploy ||
                            ( hibernate && hibernateStartUpMode == "restore" ) ||
                            rdsManualSnapshot?has_content ]

    [#if solution.AlwaysCreateFromSnapshot ]
        [#if !rdsManualSnapshot?has_content ]
            [@fatal
                message="Snapshot must be provided to create this database"
                context=occurrence
                detail="Please provie a manual snapshot or a link to an RDS data set"
            /]
        [/#if]

        [#local restoreSnapshotName = rdsManualSnapshot ]
        [#local preDeploySnapshot = false ]

    [/#if]

    [#local dbParameters = {} ]
    [#list solution.DBParameters as key,value ]
        [#if key != "Name" && key != "Id" ]
            [#local dbParameters += { key : value }]
        [/#if]
    [/#list]

    [#local processorProfile = (getProcessor(occurrence, "RDS")?has_content)?then(
                                getProcessor(occurrence, "RDS"),
                                getProcessor(occurrence, DB_COMPONENT_TYPE )
                            )]

    [#if deploymentSubsetRequired("prologue", false)]
        [@addToDefaultBashScriptOutput
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
                        " \"" + cmkKeyArn + "\" || return $?",
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
            occurrence=occurrence
            resourceId=rdsId
            resourceName=rdsFullName
            vpcId=vpcId
        /]

        [@createSecurityGroupIngress
            id=rdsSecurityGroupIngressId
            port=port
            cidr="0.0.0.0/0"
            groupId=rdsSecurityGroupId
        /]

        [@cfResource
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

        [#switch alternative!"" ]
            [#case "replace1" ]
                [#local multiAZ = false]
                [#local deletionPolicy = "Delete" ]
                [#local updateReplacePolicy = "Delete" ]
                [#local rdsFullName=formatName(rdsFullName, "backup") ]
                [#if rdsManualSnapshot?has_content ]
                    [#local snapshotId = rdsManualSnapshot ]
                [#else]
                    [#local snapshotId = valueIfTrue(
                            rdsPreDeploySnapshotId,
                            solution.Backup.SnapshotOnDeploy,
                            rdsRestoreSnapshot)]
                [/#if]

                [#if solution.Backup.UpdateReplacePolicy == "Delete" ]
                    [#local hibernate = true ]
                [/#if]
            [#break]

            [#case "replace2"]
                [#if rdsManualSnapshot?has_content ]
                    [#local snapshotId = rdsManualSnapshot ]
                [#else]
                [#local snapshotId = valueIfTrue(
                        rdsPreDeploySnapshotId,
                        solution.Backup.SnapshotOnDeploy,
                        rdsRestoreSnapshot)]
                [/#if]
            [#break]

            [#default]
                [#if rdsManualSnapshot?has_content ]
                    [#local snapshotId = rdsManualSnapshot ]
                [#else]
                    [#local snapshotId = rdsLastSnapshot]
                [/#if]
        [/#switch]

        [#if !hibernate]

            [#list solution.Alerts?values as alert ]

                [#local monitoredResources = getMonitoredResources(resources, alert.Resource)]
                [#list monitoredResources as name,monitoredResource ]

                    [@debug message="Monitored resource" context=monitoredResource enabled=false /]

                    [#switch alert.Comparison ]
                        [#case "Threshold" ]
                            [@createCountAlarm
                                id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                                severity=alert.Severity
                                resourceName=core.FullName
                                alertName=alert.Name
                                actions=getCWAlertActions(occurrence, solution.Profiles.Alert, alert.Severity )
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
                    id=rdsId
                    name=rdsFullName
                    engine=engine
                    engineVersion=engineVersion
                    processor=processorProfile.Processor
                    size=solution.Size
                    port=port
                    multiAZ=multiAZ
                    encrypted=solution.Encrypted
                    kmsKeyId=cmkKeyId
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

            [#local rdsFQDN = getExistingReference(rdsId, DNS_ATTRIBUTE_TYPE)]

            [#local passwordPseudoStackFile = "\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-password-pseudo-stack.json\"" ]
            [#local urlPseudoStackFile = "\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-url-pseudo-stack.json\""]
            [@addToDefaultBashScriptOutput
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
                        " \"" + cmkKeyArn + "\" || return $?)\"",
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
                        " \"" + cmkKeyArn + "\" || return $?)\""
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
                        " \"" + cmkKeyArn + "\" || return $?)\""
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
[/#macro]
