[#ftl]

[#-- Resources --]
[#assign DATASET_S3_SNAPSHOT_RESOURCE_TYPE = "s3Snapshot" ]

[#macro aws_dataset_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution ]
    [#local buildReference = getOccurrenceBuildReference(occurrence, true ) ]

    [#local dataSetDeploymentUnit = (solution.DeploymentUnits[0])!"" ]

    [#local attributes = {
            "DATASET_ENGINE" : solution.Engine
    }]
    [#local resources = {}]
    [#local producePolicy = []]
    [#local consumePolicy = []]

    [#local codeBuildEnv = productObject.Builds.Data.Environment ]

    [#switch solution.Engine ]
        [#case "s3" ]
            [#local registryBucket = getRegistryEndPoint("dataset", occurrence) ]
            [#local registryPrefix = formatRelativePath(
                                                getRegistryPrefix("dataset", occurrence),
                                                productName,
                                                getOccurrenceBuildUnit(occurrence))]
            [#local datasetPrefix = formatRelativePath(solution.Prefix)]

            [#local attributes += {
                "DATASET_PREFIX" : datasetPrefix,
                "DATASET_REGISTRY" : "s3://" + registryBucket +
                                            formatAbsolutePath(
                                                registryPrefix),
                "DATASET_LOCATION" : "s3://" + registryBucket +
                                            formatAbsolutePath(
                                                registryPrefix,
                                                buildReference)
                }]

            [#local consumePolicy +=
                    s3ConsumePermission(
                        registryBucket,
                        registryPrefix)]

            [#local resources += {
                "datasetS3" : {
                    "Id" : formatId(DATASET_S3_SNAPSHOT_RESOURCE_TYPE, core.Id),
                    "Type" : DATASET_S3_SNAPSHOT_RESOURCE_TYPE,
                    "Deployed" : true
                }
            }]

            [#break]

        [#case "rds" ]

            [#local registryPrefix = getRegistryPrefix("rdssnapshot", occurrence) ]
            [#local registryImage = formatName(
                                        registryPrefix,
                                        "rdssnapshot",
                                        productId,
                                        dataSetDeploymentUnit,
                                        buildReference)]

            [#local attributes += {
                "SNAPSHOT_NAME" : registryImage,
                "DATASET_LOCATION" : formatName( "dataset",  core.FullName, buildReference )
            }]

            [#local resources += {
                "datasetRDS" : {
                    "Id" : formatId(AWS_RDS_SNAPSHOT_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_RDS_SNAPSHOT_RESOURCE_TYPE,
                    "Deployed" : true
                }
            }]

            [#break]
    [/#switch]

    [#if codeBuildEnv == environmentObject.Id ]
        [#local linkCount = 0 ]
        [#list solution.Links?values as link]
            [#if link?is_hash]
                [#local linkCount += 1 ]
                [#if linkCount > 1 ]
                    [@cfException
                        mode=listMode
                        description="A data set can only have one data source"
                        context=subOccurrence
                    /]
                    [#continue]
                [/#if]

                [#local linkTarget = getLinkTarget(occurrence, link) ]

                [@debug message="Link Target" context=linkTarget enabled=false /]

                [#if !linkTarget?has_content]
                    [#continue]
                [/#if]

                [#local linkTargetCore = linkTarget.Core ]
                [#local linkTargetConfiguration = linkTarget.Configuration ]
                [#local linkTargetResources = linkTarget.State.Resources ]
                [#local linkTargetAttributes = linkTarget.State.Attributes ]

                [#local attributes += linkTargetAttributes]

                [#switch linkTargetCore.Type]
                    [#case S3_COMPONENT_TYPE ]
                        [#local attributes += {
                            "DATASET_MASTER_LOCATION" :  "s3://" + linkTargetAttributes.NAME + formatAbsolutePath(datasetPrefix )
                        }]
                        [#local producePolicy += s3ProducePermission(
                                                    linkTargetAttributes.NAME,
                                                    datasetPrefix
                            )]
                        [#break]

                    [#case RDS_COMPONENT_TYPE ]
                        [#break]

                    [#default]
                        [#local attributes += {
                            "DATASET_ENGINE" : "COTException: DataSet Support not available for " + linkTargetCore.Type
                        }]
                [/#switch]
            [/#if]
        [/#list]
    [/#if]

    [#assign componentState =
        {
            "Resources" : resources,
            "Attributes" : attributes,
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {
                    "default" : "consume",
                    "produce" : producePolicy,
                    "consume" : consumePolicy
                }
            }
        }
    ]
[/#macro]