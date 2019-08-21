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

    [#if deploymentSubsetRequired("cli", false) ]

        [@addCliToDefaultJsonOutput
            id=workGroupCreateId
            command=workGroupCreateCommand
            content={
                "Name": "",
                "Configuration": {
                    "ResultConfiguration": {
                        "OutputLocation": "",
                        "EncryptionConfiguration": {
                            "EncryptionOption": "SSE_S3",
                            "KmsKey": ""
                        }
                    },
                    "EnforceWorkGroupConfiguration": true,
                    "PublishCloudWatchMetricsEnabled": true,
                    "BytesScannedCutoffPerQuery": 0
                },
                "Description": "",
                "Tags": [
                    {
                        "Key": "",
                        "Value": ""
                    }
                ]
            }
        /]
    [/#if]


[/#macro]