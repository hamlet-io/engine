[#-- DATA PIPELINE --]

[#-- Resources --]
[#assign AWS_DATA_PIPELINE_RESOURCE_TYPE = "datapipeline"]

[#-- Components --]
[#assign DATAPIPELINE_COMPONENT_TYPE = "datapipeline"]

[#assign componentConfiguration +=
    {
        DATAPIPELINE_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "Managed Data ETL Processing"
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
                    "Names" : ["Fragment", "Container"],
                    "Type" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "Permissions",
                    "Children" : [
                        {
                            "Names" : "Decrypt",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "AsFile",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "AppData",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "AppPublic",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        }
                    ]
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration +
                                    [
                                        {
                                            "Names" : "Processor",
                                            "Type" : STRING_TYPE,
                                            "Default" : "default"
                                        }
                                    ]
                }
            ]
        }
    }]


[#macro aws_datapipeline_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getDataPipelineState(occurrence)]
[/#macro]

[#function getDataPipelineState occurrence]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution ]
    [#local buildReference = getOccurrenceBuildReference(occurrence) ]

    [#local pipelineId = formatResourceId( AWS_DATA_PIPELINE_RESOURCE_TYPE, core.Id )]

    [#-- The ec2 Role and Instance profile must have the same name --]
    [#local resourceRoleName = formatName(core.FullName, "resource")]

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
                    "Name" : formatName(core.FullName, "pipeline"),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "resourceRole" : {
                    "Id" : formatResourceId( AWS_IAM_ROLE_RESOURCE_TYPE, core.Id, "resource" ),
                    "Name" : resourceRoleName,
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "resourceInstanceProfile" : {
                    "Id" : formatResourceId( AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE, core.Id ),
                    "Name" : resourceRoleName,
                    "Type" : AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE
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