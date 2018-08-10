[#-- DATA PIPELINE --]

[#-- Resources --]
[#assign AWS_DATA_PIPELINE_RESOURCE_TYPE = "datapipeline"]

[#-- Components --]
[#assign DATAPIPELINE_COMPONENT_TYPE = "datapipeline"]

[#assign componentConfiguration +=
    {
        DATAPIPELINE_COMPONENT_TYPE : [
            {
                "Name" : "Container",
                "Default" : ""
            },
            {
                "Name" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
    }]

[#function getDataPipelineState occurrence]
    
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution ]
    [#local buildReference = getOccurrenceBuildReference(occurrence) ]

    [#return
        {
            "Resources" : {
                "dataPipeline" : {
                    "Id" : formatResourceId( AWS_DATA_PIPELINE_RESOURCE_TYPE, core.Id ),
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "pipelineRole" : {
                    "Id" : formatResourceId( AWS_IAM_ROLE_RESOURCE_TYPE, core.Id, "pipeline" ),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "resourceRole" : {
                    "Id" : formatResourceId( AWS_IAM_ROLE_RESOURCE_TYPE, core.Id, "resource" ),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "securityGroup" : {
                    "Id" : formatResourceId( AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE, core.Id ),
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]