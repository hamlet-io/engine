[#-- DATA SET --]

[#-- Components --]
[#assign DATASET_COMPONENT_TYPE = "dataset"]

[#assign componentConfiguration +=
    {
        DATASET_COMPONENT_TYPE : [
            {
                "Name" : "DataSource",
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

    [#local dataSource = getLinkTarget(occurrence, solution.DataSource)]
    [#local dataSourceType = dataSource.Core.Type ]
    [#local dataSourceAttributes = dataSource.State.Attributes]

    [#local attributes = {
    } + 
        dataSourceAttributes]

    [#switch dataSourceType ]
        [#case S3_COMPONENT_TYPE ]
            [#local attributes += { 
                "DATASET_ENGINE" : "s3",
                "DATASET_MASTER_LOCATION" :  "s3://" + dataSourceAttributes.NAME + formatAbsolutePath(solution.Prefix),
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
                "DATASET_MASTER_LOCATION" : formatName( "dataset", core.FullName, solution.Prefix),
                "DATASET_LOCATION" : formatName( "dataset",  core.FullName, getOccurrenceBuildReference(occurrence) )
            }]
            [#break]
        
        [#default]
            [#local attributes += {
                "DATASET_ENGINE" : "COTException: DataSet Support not available for " + dataSourceType
            }]
    [/#switch]

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