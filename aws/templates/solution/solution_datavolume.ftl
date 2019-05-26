[#ftl]
[#macro solution_datavolume tier component]
    [#-- DATAVOLUME --]
    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign solution = occurrence.Configuration.Solution]
        [#assign resources = occurrence.State.Resources]

        [#assign manualSnapshotId = resources["manualSnapshot"].Id]
        [#assign manualSnapshotName = getExistingReference(manualSnapshotId, NAME_ATTRIBUTE_TYPE)]

        [#assign backupEnabled = solution.Backup.Enabled ]
        [#if backupEnabled ]
            [#assign maintenanceWindowId = resources["maintenanceWindow"].Id ]
            [#assign maintenanceWindowName = resources["maintenanceWindow"].Name ]
            [#assign windowTargetId = resources["windowTarget"].Id]
            [#assign windowTargetName = resources["windowTarget"].Name]

            [#assign maintenanceServiceRoleId = resources["maintenanceServiceRole"].Id]
            [#assign maintenanceLambdaRoleId = resources["maintenanceLambdaRole"].Id]

            [#assign ssmWindowTargets = getSSMWindowTargets( [],[],true )]
        [/#if]

        [#list resources["Zones"] as zoneId, zoneResources ]
            [#assign volumeId = zoneResources["ebsVolume"].Id ]
            [#assign volumeName = zoneResources["ebsVolume"].Name ]

            [#assign volumeTags = getOccurrenceCoreTags(
                                        occurrence,
                                        volumeName,
                                        "",
                                        false)]

            [#assign resourceZone = {}]
            [#list zones as zone ]
                [#if zoneId == zone.Id ]
                    [#assign resourceZone = zone ]
                [/#if]
            [/#list]

            [#if deploymentSubsetRequired(DATAVOLUME_COMPONENT_TYPE, true)]
                [@createEBSVolume
                    mode=listMode
                    id=volumeId
                    tags=volumeTags
                    size=solution.Size
                    volumeType=solution.VolumeType
                    encrypted=solution.Encrypted
                    provisionedIops=solution.ProvisionedIops
                    zone=resourceZone
                    snapshotId=manualSnapshotName
                /]

                [#if backupEnabled ]

                    [#assign snapshotCreateTaskId = zoneResources["taskCreateSnapshot"].Id ]
                    [#assign snapshotCreateTaskName = zoneResources["taskCreateSnapshot"].Name ]

                    [@createSSMMaintenanceWindowTask
                        mode=listMode
                        id=snapshotCreateTaskId
                        name=snapshotCreateTaskName
                        targets=ssmWindowTargets
                        priority=10
                        serviceRoleId=maintenanceServiceRoleId
                        windowId=maintenanceWindowId
                        taskId="AWS-CreateSnapshot"
                        taskType="Automation"
                        taskParameters=getSSMWindowAutomationTaskParameters(
                                            {
                                                "AutomationAssumeRole" : asArray(getReference(maintenanceServiceRoleId,ARN_ATTRIBUTE_TYPE)),
                                                "VolumeId" : asArray(getReference(volumeId))
                                            }
                        )
                        priority=10
                    /]

                    [#assign snapshotDeleteTaskId = zoneResources["taskDeleteSnapshot"].Id ]
                    [#assign snapshotDeleteTaskName = zoneResources["taskDeleteSnapshot"].Name ]

                    [@createSSMMaintenanceWindowTask
                        mode=listMode
                        id=snapshotDeleteTaskId
                        name=snapshotDeleteTaskName
                        targets=ssmWindowTargets
                        priority=20
                        serviceRoleId=maintenanceServiceRoleId
                        windowId=maintenanceWindowId
                        taskId="AWS-DeleteEbsVolumeSnapshots"
                        taskType="Automation"
                        taskParameters=getSSMWindowAutomationTaskParameters(
                                            {
                                                "AutomationAssumeRole" : asArray(getReference(maintenanceServiceRoleId, ARN_ATTRIBUTE_TYPE)),
                                                "LambdaAssumeRole" : asArray(getReference(maintenanceLambdaRoleId, ARN_ATTRIBUTE_TYPE)),
                                                "VolumeId" : asArray(getReference(volumeId)),
                                                "RetentionDays" : asArray(solution.Backup.RetentionPeriod),
                                                "RetentionCount" : asArray("")
                                            }
                        )
                        priority=10
                    /]
                [/#if]
            [/#if]
        [/#list]

        [#if deploymentSubsetRequired(DATAVOLUME_COMPONENT_TYPE, true)]
            [#assign maintenanceWindowTags = getOccurrenceCoreTags(
                                                occurrence,
                                                maintenanceWindowName,
                                                "",
                                                false)]
            [@createSSMMaintenanceWindow
                mode=listMode
                id=maintenanceWindowId
                name=maintenanceWindowName
                schedule=solution.Backup.Schedule
                durationHours=3
                cutoffHours=0
                tags=maintenanceWindowTags
                scheduleTimezone=solution.Backup.ScheduleTimeZone
            /]

            [@createSSMMaintenanceWindowTarget
                mode=listMode
                id=windowTargetId
                name=windowTargetName
                windowId=maintenanceWindowId
                targets=ssmWindowTargets
            /]
        [/#if]

        [#if deploymentSubsetRequired("iam", true) ]

            [#if backupEnabled ]
                [#if isPartOfCurrentDeploymentUnit(maintenanceServiceRoleId) ]
                    [@createRole
                        mode=listMode
                        id=maintenanceServiceRoleId
                        trustedServices=[
                            "ec2.amazonaws.com",
                            "ssm.amazonaws.com"
                        ]
                        managedArns=["arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"]
                    /]

                    [#assign policyId = formatDependentPolicyId(maintenanceServiceRoleId, "passRole")]
                    [@createPolicy
                        mode=listMode
                        id=policyId
                        name="passRole"
                        statements=iamPassRolePermission(
                                        [
                                            getReference(maintenanceLambdaRoleId, ARN_ATTRIBUTE_TYPE),
                                            getReference(maintenanceServiceRoleId, ARN_ATTRIBUTE_TYPE)
                                        ]
                                    ) +
                                    ec2EBSVolumeSnapshotAllPermission() +
                                    lambdaSSMAutomationPermission()
                        roles=maintenanceServiceRoleId
                    /]
                [/#if]
                [#if isPartOfCurrentDeploymentUnit(maintenanceLambdaRoleId) ]
                    [@createRole
                        mode=listMode
                        id=maintenanceLambdaRoleId
                        trustedServices=[
                                "lambda.amazonaws.com"
                            ]
                        policies=
                            [
                                getPolicyDocument(
                                    ec2EBSVolumeSnapshotAllPermission(),
                                    "snapshot")
                            ]
                    /]
                [/#if]
            [/#if]
        [/#if]
        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript
                mode=listMode
                content=
                [
                    "case $\{STACK_OPERATION} in",
                    "  create|update)"
                ] +
                pseudoStackOutputScript(
                    "Manual Snapshot",
                    { manualSnapshotId : "" }
                ) +
                [
                    "       ;;",
                    "       esac"
                ]
            /]
        [/#if]
    [/#list]
[/#macro]