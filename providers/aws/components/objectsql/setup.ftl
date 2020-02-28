[#ftl]
[#macro aws_objectsql_cf_generationcontract_solution occurrence ]
    [@addDefaultGenerationContract subsets=["cli", "prologue"] /]
[/#macro]

[#macro aws_objectsql_cf_setup_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=true /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]
    [#local links = getLinkTargets(occurrence )]

    [#local workGroupId = resources["workgroup"].Id ]
    [#local workGroupName = resources["workgroup"].Name ]

    [#local workGroupCreateId = formatId(workGroupId, "create")]
    [#local workGroupCreateCommand = "createWorkGroup" ]

    [#local workGroupUpdateId = formatId(workGroupId, "update")]
    [#local workGroupUpdateCommand = "updateWorkGroup" ]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "AppData", "Encryption" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]]

    [#local dataBucket = getExistingReference(baselineComponentIds["AppData"])]
    [#local dataPrefix = getAppDataFilePrefix(occurrence) ]

    [#local kmsKeyId = baselineComponentIds["Encryption"] ]

    [#local outputLocation = formatRelativePath( "s3://", dataBucket, dataPrefix, "/" )]

    [#local resultConfiguration = {
        "OutputLocation": outputLocation
    } +
    ( solution.Encrypted )?then(
        {
            "EncryptionConfiguration" : {
                "EncryptionOption" : "SSE_KMS",
                "KmsKey" : getExistingReference(kmsKeyId, ARN_ATTRIBUTE_TYPE)
            }
        },
        {}
    )]

    [#local workGroupConfig =
        {
            "EnforceWorkGroupConfiguration": true,
            "PublishCloudWatchMetricsEnabled": true
        } +
        attributeIfTrue(
            "BytesScannedCutoffPerQuery",
            solution.ScanLimitSize > 0,
            solution.ScanLimitSize
        )
    ]

    [#if deploymentSubsetRequired("cli", true) ]

        [@addCliToDefaultJsonOutput
            id=workGroupCreateId
            command=workGroupCreateCommand
            content={
                "Name" : workGroupName,
                "Configuration" :
                    mergeObjects(
                        workGroupConfig,
                        {
                            "ResultConfiguration" : resultConfiguration
                        }
                    )
            }
        /]

        [@addCliToDefaultJsonOutput
            id=workGroupUpdateId
            command=workGroupUpdateCommand
            content={
                "WorkGroup" : workGroupName,
                "ConfigurationUpdates" :
                        mergeObjects(
                            workGroupConfig,
                            {
                                "ResultConfigurationUpdates" : resultConfiguration
                            }
                        )
            }
        /]
    [/#if]

    [#if deploymentSubsetRequired("prologue", false)]
        [@addToDefaultBashScriptOutput
            content=
                [
                    "workgroup_deployed=\"$(aws --region " + region + " athena list-work-groups --query 'WorkGroups[?Name==`" + workGroupName + "`].Name' --output text)\"",
                    "case $\{STACK_OPERATION} in",
                    "  create|update)"
                    "       # Get cli config file",
                    "       split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?",
                    "       info \"Setting up athena workgroup " + workGroupName + "\"",
                    "       if [[ -z \"$\{workgroup_deployed}\" ]]; then ",
                    "           info \"Creating Athena workgroup\"",
                    "           aws --region " + region +
                    "           athena create-work-group --cli-input-json \"file://$\{tmpdir}/cli-" +
                                        workGroupCreateId + "-" + workGroupCreateCommand + ".json\" || exit $?",
                    "       else",
                    "           info \"Updating Athena workgroup" + workGroupName + "\"",
                    "           aws --region " + region +
                    "           athena update-work-group --cli-input-json \"file://$\{tmpdir}/cli-" +
                                    workGroupUpdateId + "-" + workGroupUpdateCommand + ".json\" || exit $?",
                    "        fi"
                ] +
                    pseudoStackOutputScript(
                        "Athena WorkGroup",
                        {
                            formatId( workGroupId, NAME_ATTRIBUTE_TYPE ) : workGroupName
                        }
                    ) +
                [
                    "       ;;",
                    "  delete)",
                    "       if [[ -n \"$\{workgroup_deployed}\" ]]; then ",
                    "           info \"Deleting Athena workgroup" + workGroupName + "\"",
                    "           aws --region " + region + " athena delete-work-group --work-group \"" + workGroupName + "\" --recursive-delete-option || exit $?",
                    "       fi",
                    " ;;",
                    "esac"
                ]
        /]
    [/#if]
[/#macro]
