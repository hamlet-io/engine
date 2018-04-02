[#-- RDS --]
[#if (componentType == "rds")]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]
        [#assign attributes = occurrence.State.Attributes ]

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

        [#if solution.GenerateCredentials.Enabled ]
            [#assign rdsUsername = solution.GenerateCredentials.MasterUserName]
            [#assign rdsPasswordLength = solution.GenerateCredentials.CharacterLength]
            [#assign rdsPassword = "DummyPassword" ]
            [#assign rdsEncryptedPassword = getExistingReference(rdsId, GENERATEDPASSWORD_ATTRIBUTE_TYPE)]
        [#else]
            [#assign rdsUsername = attributes.USERNAME ]
            [#assign rdsPassword = attributes.PASSWORD ]
        [/#if]

        [#assign rdsRestoreSnapshot = getExistingReference(formatDependentRDSSnapshotId(rdsId), NAME_ATTRIBUTE_TYPE)]
        [#assign rdsManualSnapshot = getExistingReference(formatDependentRDSManualSnapshotId(rdsId), NAME_ATTRIBUTE_TYPE)]
        [#assign rdsLastSnapshot = getExistingReference(rdsId, LASTRESTORE_ATTRIBUTE_TYPE )]

        [#assign segmentKMSKey = getReference(formatSegmentCMKId(), ARN_ATTRIBUTE_TYPE)]

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
            [@cfScript
                mode=listMode
                content=
                [] + 
                [#-- If a manual snapshot has been added the pseudo stack output should be replaced with an automated one --]
                (solution.Backup.SnapshotOnDeploy || rdsManualSnapshot?has_content)?then(
                    [
                        "# Create RDS snapshot",
                        "function create_deploy_snapshot() {",
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
                    ],
                    []) +
                (solution.Backup.SnapshotOnDeploy && solution.Encrypted)?then(
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
                    [])
            /]
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
                                solution.Backup.SnapshotOnDeploy,
                                rdsRestoreSnapshot)]
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
                    databaseName=solution.DatabaseName!productName
                    retentionPeriod=solution.Backup.RetentionPeriod
                    snapshotId=snapshotId
                    subnetGroupId=getReference(rdsSubnetGroupId)
                    parameterGroupId=getReference(rdsParameterGroupId)
                    optionGroupId=getReference(rdsOptionGroupId)
                    securityGroupId=getReference(rdsSecurityGroupId)
                    autoMinorVersionUpgrade = solution.AutoMinorVersionUpgrade!RDSAutoMinorVersionUpgrade
                /]
        [/#if]

        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript
                mode=listMode
                content=
                [] + 
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
                        "create_pseudo_stack" + " " + 
                        "\"RDS Master Password\"" + " " + 
                        "\"$\{password_pseudo_stack_file}\"" + " " + 
                        "\"" + rdsId + "Xgeneratedpassword\" " + "\"$\{encrypted_master_password}\" || return $?",
                        "}",
                        "password_pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")password-pseudo-stack.json\" ",
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
                        " \"$\{encrypted_master_password}\" || return $?)\"",
                        "info \"Resetting Master Password... \"",
                        "set_rds_master_password" +
                        " \"" + region + "\" " + 
                        " \"" + rdsFullName + "\" " + 
                        " \"$\{master_password}\" || return $?"
                        "}",
                        "reset_master_password || return $?"
                    ],
                []) 
            /]
        [/#if]
    [/#list]
[/#if]
