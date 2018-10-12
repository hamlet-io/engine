[#-- DATA SET --]

[#-- Components --]
[#assign DATASET_COMPONENT_TYPE = "dataset"]

[#assign componentConfiguration +=
    {
        DATASET_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A data aretefact that is managed in a similar way to a code unit"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "application"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Engine",
                    "Type" : STRING_TYPE,
                    "Values" : ["s3", "rdsSnapshot"],
                    "Mandatory" : true
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Prefix",
                    "Type" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        }
    }]

[#function getDataSetState occurrence]
    
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution ]
    [#local buildReference = getOccurrenceBuildReference(occurrence, true ) ]

    [#local datasetPrefix = formatRelativePath(solution.Prefix)]
    [#local attributes = {
            "DATASET_ENGINE" : solution.Engine,
            "DATASET_PREFIX" : datasetPrefix
    }]
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
            [#local attributes += {
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

            [#break]

        [#case "rdsSnapshot" ]
            [#local attributes += {
                "DATASET_REGISTRY" : formatName( "dataset",  core.FullName ),
                "DATASET_LOCATION" : formatName( "dataset",  core.FullName, buildReference )
            }]
            [#break]
    [/#switch]

    [#if codeBuildEnv == environmentObject.Id ]
        [#assign linkCount = 0 ]
        [#list solution.Links?values as link]
            [#if link?is_hash]
                [#assign linkCount += 1 ]
                [#if linkCount > 1 ]
                    [@cfException
                        mode=listMode
                        description="A data set can only have one data source"
                        context=subOccurrence
                    /]
                    [#continue]
                [/#if]

                [#assign linkTarget = getLinkTarget(occurrence, link) ]

                [@cfDebug listMode linkTarget false /]

                [#if !linkTarget?has_content]
                    [#continue]
                [/#if]

                [#assign linkTargetCore = linkTarget.Core ]
                [#assign linkTargetConfiguration = linkTarget.Configuration ]
                [#assign linkTargetResources = linkTarget.State.Resources ]
                [#assign linkTargetAttributes = linkTarget.State.Attributes ]
                
                [#local attributes += linkTargetAttributes]

                [#switch linkTargetCore.Type]
                    [#case S3_COMPONENT_TYPE ]
                        [#local attributes += { 
                            "DATASET_MASTER_LOCATION" :  "s3://" + linkTargetAttributes.NAME + datasetPrefix
                        }]
                        [#local producePolicy += s3ProducePermission(
                                                    linkTargetAttributes.NAME,
                                                    datasetPrefix 
                            )]
                        [#break]
                    [#case RDS_COMPONENT_TYPE ]
                        [#local masterDataLocation = formatName( core.FullName, solution.Prefix )]
                        [#local attributes += { 
                            "DATASET_MASTER_LOCATION" : formatName( "dataset", core.FullName, solution.Prefix)
                        }]
                        [#break]
                    
                    [#default]
                        [#local attributes += {
                            "DATASET_ENGINE" : "COTException: DataSet Support not available for " + linkTargetCore.Type
                        }]
                [/#switch]
            [/#if]
        [/#list]
    [/#if]

    [#return
        {
            "Resources" : {
            },
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
[/#function]