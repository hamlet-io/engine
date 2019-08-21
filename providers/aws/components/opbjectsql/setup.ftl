[#ftl]

[#macro aws_objectsql_cf_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets=[ "template", "epilogue", "cli"] /]
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

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "AppData", "Encryption" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]]

    [#local dataBucket = getExistingReference(baselineComponentIds["AppData"])]
    [#local dataPrefix = getAppDataFilePrefix(occurrence) ]

    [#local kmsKeyId = baselineComponentIds["Encryption"] ]
    
    [#local outputLocation = formatRelativePath( "s3:/", dataBucket, dataPrefix, "/" )]

    [#if deploymentSubsetRequired("cli", false) ]

        [@addCliToDefaultJsonOutput
            id=workGroupCreateId
            command=workGroupCreateCommand
            content={
                "Name" : workGroupName,
                "Tags": getCfTemplateCoreTags(workGroupName, core.Tier, core.Component)
                "Configuration": {
                    "EnforceWorkGroupConfiguration": true,
                    "PublishCloudWatchMetricsEnabled": true
                    "ResultConfiguration": {
                        "OutputLocation": outputLocation,
                    } + 
                    ( solution.Encryption )?then(
                        {
                            "EncryptionConfiguration" : {
                                "EncryptionOption" : "SSE_KMS",
                                "KmsKey" : getExistingReference(kmsKeyId, ARN_ATTRIBUTE_TYPE)
                            }
                        },
                        {}
                    )
                } + 
                attributeIfTrue(
                    "BytesScannedCutoffPerQuery",
                    solution.ScanLimitSize > 0,
                    solution.ScanLimitSize
                )
            }
        /]
    [/#if]


[/#macro]