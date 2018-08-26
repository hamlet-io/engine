[#-- DATA PIPELINE --]

[#-- Resources --]
[#assign AWS_DATA_PIPELINE_RESOURCE_TYPE = "datapipeline"]

[#-- Components --]
[#assign DATAPIPELINE_COMPONENT_TYPE = "datapipeline"]

[#assign componentConfiguration +=
    {
        DATAPIPELINE_COMPONENT_TYPE : [
            {
                "Name" : ["Fragment", "Container"],
                "Type" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Name" : "Permissions",
                "Children" : [
                    {
                        "Name" : "Decrypt",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Name" : "AsFile",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Name" : "AppData",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Name" : "AppPublic",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
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

    [#local pipelineId = formatResourceId( AWS_DATA_PIPELINE_RESOURCE_TYPE, core.Id )]

    [#return
        {
            "Resources" : {
                "dataPipeline" : {
                    "Id" : pipelineId,
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "pipelineRole" : {
                    "Id" : formatResourceId( AWS_IAM_ROLE_RESOURCE_TYPE, core.Id, "pipeline" ),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "resourceInstanceProfile" : {
                    "Id" : formatResourceId( AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE, core.Id ),
                    "Type" : AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE
                },
                "resourceRole" : {
                    "Id" : formatResourceId( AWS_IAM_ROLE_RESOURCE_TYPE, core.Id, "resource" ),
                    "Name" : core.FullName,
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "securityGroup" : {
                    "Id" : formatResourceId( AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE, core.Id ),
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "ID" : getExistingReference( pipelineId )
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]