[#ftl]

[#macro aws_objectsql_cf_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=true /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets=["cli", "prologue"] /]
        [#return]
    [/#if]

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

    [#local workGroupConfig = 
        {
            "EnforceWorkGroupConfiguration": true,
            "PublishCloudWatchMetricsEnabled": true,
            "ResultConfiguration": {
                "OutputLocation": outputLocation
            }
        } + 
        ( solution.Encrypted )?then(
            {
                "EncryptionConfiguration" : {
                    "EncryptionOption" : "SSE_KMS",
                    "KmsKey" : getExistingReference(kmsKeyId, ARN_ATTRIBUTE_TYPE)
                }
            },
            {}
        ) + 
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
                "Configuration" : workGroupConfig
            }
        /]

        [@addCliToDefaultJsonOutput
            id=workGroupUpdateId
            command=workGroupUpdateCommand
            content={
                "Name" : workGroupName,
                "ConfigurationUpdates" : workGroupConfig
            }
        /]
    [/#if]

    [#if deploymentSubsetRequired("prologue", false)]
        [@addToDefaultBashScriptOutput
            content=
                [
                    "case $\{STACK_OPERATION} in",
                    "  create|update)"
                    "       # Get cli config file",
                    "       split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?"
                ] + 
                getExistingReference(workGroupId, NAME_ATTRIBUTE_TYPE )?has_content?then(
                    [
                        "info \"Updating Athena workgroup\"",
                        "aws --region " + region + 
                        " athena update-work-group --cli-input-json \"file://$\{tmpdir}/cli-" +
                            workGroupUpdateId + "-" + workGroupUpdateCommand + ".json\" || exit $?",
                        " ;;"
                    ],
                    [
                        "info \"Creating Athena workgroup\"",
                        "aws --region " + region + 
                        " athena create-work-group --cli-input-json \"file://$\{tmpdir}/cli-" +
                            workGroupCreateId + "-" + workGroupCreateCommand + ".json\" || exit $?"
                    ] + 
                    pseudoStackOutputScript(
                        "Athena WorkGroup",
                        {
                            formatId( workGroupId, NAME_ATTRIBUTE_TYPE ) : workGroupName
                        }
                    ) + 
                    [
                        " ;;"
                    ]
                ) + 
                [
                    "  delete)",
                    "info \"Deleting Athena workgroup\"",
                    "aws --region " + region + " athena delete-work-group --work-group \"" + workGroupName + "\" --recursive-delete-option || exit $?", 
                    " ;;"
                ] + 
                [
                    "esac"
                ]
        /]
    [/#if]
[/#macro]