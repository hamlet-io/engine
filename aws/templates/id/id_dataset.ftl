[#-- DATA SET --]

[#-- Components --]
[#assign DATASET_COMPONENT_TYPE = "dataset"]

[#assign componentConfiguration +=
    {
        DATASET_COMPONENT_TYPE : [
            {
                "Name" : "Engine",
                "Type" : STRING_TYPE,
                "Values" : ["s3", "rdsSnapshot"],
                "Default" : "",
                "Mandatory" : true
            }
            {
                "Name" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Name" : "Prefix",
                "Type" : STRING_TYPE,
                "Default" : ""
            }
        ]
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

    [#switch solution.Engine ]
        [#case "s3" ]
            [#local attributes += {
                "DATASET_REGISTRY" : "s3://" + getRegistryEndPoint("dataset", occurrence) + 
                                            formatAbsolutePath(
                                                getRegistryPrefix("dataset", occurrence),
                                                productName,
                                                getOccurrenceBuildUnit(occurrence)
                                            ),
                "DATASET_LOCATION" : "s3://" + getRegistryEndPoint("dataset", occurrence) + 
                                            formatAbsolutePath(
                                                getRegistryPrefix("dataset", occurrence),
                                                productName,
                                                getOccurrenceBuildUnit(occurrence),
                                                buildReference
                                            )
            }]
            [#break]
        [#case "rdsSnapshot" ]
            [#local attributes += {
                "DATASET_REGISTRY" : formatName( "dataset",  core.FullName ),
                "DATASET_LOCATION" : formatName( "dataset",  core.FullName, buildReference )
            }]
            [#break]
    [/#switch]

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

    [#return
        {
            "Resources" : {
            },
            "Attributes" : attributes,
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]