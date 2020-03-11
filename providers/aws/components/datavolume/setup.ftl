[#ftl]
[#macro aws_datavolume_cf_generationcontract_solution occurrence ]
    [@addDefaultGenerationContract subsets=["template", "epilogue"] /]
[/#macro]

[#macro aws_datavolume_cf_setup_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]
    [#local resources = occurrence.State.Resources]

    [#local manualSnapshotId = resources["manualSnapshot"].Id]
    [#local manualSnapshotName = getExistingReference(manualSnapshotId, NAME_ATTRIBUTE_TYPE)]


    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "Encryption"] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]

    [#local cmkKeyId = baselineComponentIds["Encryption" ]]

    [#local backupEnabled = solution.Backup.Enabled ]
    [#if backupEnabled ]
        [#local maintenanceWindowId = resources["maintenanceWindow"].Id ]
        [#local maintenanceWindowName = resources["maintenanceWindow"].Name ]
        [#local windowTargetId = resources["windowTarget"].Id]
        [#local windowTargetName = resources["windowTarget"].Name]

        [#local maintenanceServiceRoleId = resources["maintenanceServiceRole"].Id]
        [#local maintenanceLambdaRoleId = resources["maintenanceLambdaRole"].Id]

        [#local ssmWindowTargets = getSSMWindowTargets( [],[],true )]
    [/#if]

    [#list resources["Zones"] as zoneId, zoneResources ]
        [#local volumeId = zoneResources["ebsVolume"].Id ]
        [#local volumeName = zoneResources["ebsVolume"].Name ]

        [#local volumeTags = getOccurrenceCoreTags(
                                    occurrence,
                                    volumeName,
                                    "",
                                    false)]

        [#local resourceZone = {}]
        [#list zones as zone ]
            [#if zoneId == zone.Id ]
                [#local resourceZone = zone ]
            [/#if]
        [/#list]

        [#if deploymentSubsetRequired(DATAVOLUME_COMPONENT_TYPE, true)]
            [@createEBSVolume
                id=volumeId
                tags=volumeTags
                size=solution.Size
                volumeType=solution.VolumeType
                encrypted=solution.Encrypted
                kmsKeyId=cmkKeyId
                provisionedIops=solution.ProvisionedIops
                zone=resourceZone
                snapshotId=manualSnapshotName
            /]

            [#if backupEnabled ]

                [#local snapshotCreateTaskId = zoneResources["taskCreateSnapshot"].Id ]
                [#local snapshotCreateTaskName = zoneResources["taskCreateSnapshot"].Name ]

                [@createSSMMaintenanceWindowTask
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

                [#local snapshotDeleteTaskId = zoneResources["taskDeleteSnapshot"].Id ]
                [#local snapshotDeleteTaskName = zoneResources["taskDeleteSnapshot"].Name ]

                [@createSSMMaintenanceWindowTask
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

    [#if deploymentSubsetRequired(DATAVOLUME_COMPONENT_TYPE, true) && backupEnabled ]
        [#local maintenanceWindowTags = getOccurrenceCoreTags(
                                            occurrence,
                                            maintenanceWindowName,
                                            "",
                                            false)]
        [@createSSMMaintenanceWindow
            id=maintenanceWindowId
            name=maintenanceWindowName
            schedule=solution.Backup.Schedule
            durationHours=3
            cutoffHours=0
            tags=maintenanceWindowTags
            scheduleTimezone=solution.Backup.ScheduleTimeZone
        /]

        [@createSSMMaintenanceWindowTarget
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
                    id=maintenanceServiceRoleId
                    trustedServices=[
                        "ec2.amazonaws.com",
                        "ssm.amazonaws.com"
                    ]
                    managedArns=["arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"]
                /]

                [#local policyId = formatDependentPolicyId(maintenanceServiceRoleId, "passRole")]
                [@createPolicy
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
        [@addToDefaultBashScriptOutput
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
[/#macro]
