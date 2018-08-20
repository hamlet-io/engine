[#-- DATA SET --]

[#-- Components --]
[#assign DATASET_COMPONENT_TYPE = "dataset"]

[#assign componentConfiguration +=
    {
        DATASET_COMPONENT_TYPE : [
            {
                "Name" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Name" : "Prefix",
                "Default" : ""
            }
        ]
    }]

[#function getDataSetState occurrence]
    
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution ]
    [#local buildReference = getOccurrenceBuildReference(occurrence) ]
    [#local attributes = {}]

    [#list solution.Links["DATASOURCE"]?values as link]
        [#if link?is_hash]
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
                        "DATASET_ENGINE" : "s3",
                        "DATASET_PREFIX" : formatAbsolutePath(solution.Prefix),
                        "DATASET_MASTER_LOCATION" :  "s3://" + linkTargetAttributes.NAME + formatAbsolutePath(solution.Prefix),
                        "DATASET_REGISTRY" : "s3://" + getRegistryEndPoint("swagger", occurrence) + 
                                                    formatAbsolutePath(
                                                        getRegistryPrefix("dataset", occurrence),
                                                        productName,
                                                        getOccurrenceBuildUnit(occurrence),
                                                    ),
                        "DATASET_LOCATION" : "s3://" + getRegistryEndPoint("swagger", occurrence) + 
                                                    formatAbsolutePath(
                                                        getRegistryPrefix("dataset", occurrence),
                                                        productName,
                                                        getOccurrenceBuildUnit(occurrence),
                                                        getOccurrenceBuildReference(occurrence)
                                                    )
                    }]
                    [#break]
                [#case RDS_COMPONENT_TYPE ]
                    [#local masterDataLocation = formatName( core.FullName, solution.Prefix )]
                    [#local attributes += { 
                        "DATASET_ENGINE" : "rdsSnapshot",
                        "DATASET_PREFIX" : formatAbsolutePath(solution.Prefix)
                        "DATASET_MASTER_LOCATION" : formatName( "dataset", core.FullName, solution.Prefix),
                        "DATASET_REGISTRY" : formatName( "dataset",  core.FullName ),
                        "DATASET_LOCATION" : formatName( "dataset",  core.FullName, getOccurrenceBuildReference(occurrence) )
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