[#-- BASTION --]

[#-- Components --]
[#assign BASTION_COMPONENT_TYPE = "bastion" ]

[#assign componentConfiguration +=
    {
        BASTION_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "An bastion instance to manage vpc only components"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Active",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "OS",
                    "Type" : STRING_TYPE,
                    "Values" : ["linux"],
                    "Default" : "linux"
                },
                {
                    "Names" : ["Fragment", "Container"],
                    "Type" : STRING_TYPE,
                    "Default" : ""
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
                },
                {
                    "Names" : "AutoScaling",
                    "Children" : autoScalingChildConfiguration
                },
                {
                    "Names" : "Permissions",
                    "Children" : [
                        {
                            "Names" : "Decrypt",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "AsFile",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "AppData",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "AppPublic",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                },
                {
                    "Names" : "Role",
                    "Description" : "Server configuration role",
                    "Default" : ""
                }
            ]
        }
    }]

[#macro aws_bastion_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getBastionState(occurrence)]
[/#macro]

[#function getBastionState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local result =
        {
            "Resources" : {
                "eip" : {
                    "Id" : formatEIPId(core.Id),
                    "Type" : AWS_EIP_RESOURCE_TYPE
                },
                "securityGroupTo" : {
                    "Id" : formatResourceId( AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE, core.Id ),
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "securityGroupFrom" : {
                    "Id" : formatSSHFromProxySecurityGroupId(),
                    "Name" : formatName( formatSegmentFullName(), "all", core.Component.Name),
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "role" : {
                    "Id" : formatResourceId( AWS_IAM_ROLE_RESOURCE_TYPE, core.Id ),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "instanceProfile" : {
                    "Id" : formatResourceId( AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE, core.Id ),
                    "Type" : AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE
                },
                "autoScaleGroup" : {
                    "Id" : formatResourceId( AWS_EC2_AUTO_SCALE_GROUP_RESOURCE_TYPE, core.Id ),
                    "Name" : core.FullName,
                    "Type" : AWS_EC2_AUTO_SCALE_GROUP_RESOURCE_TYPE
                },
                "lg" : {
                    "Id" : formatLogGroupId(core.Id),
                    "Name" : core.FullAbsolutePath,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                },
                "launchConfig" : {

                    "Id" : solution.AutoScaling.AlwaysReplaceOnUpdate?then(
                                formatResourceId(AWS_EC2_LAUNCH_CONFIG_RESOURCE_TYPE, core.Id, runId),
                                formatResourceId(AWS_EC2_LAUNCH_CONFIG_RESOURCE_TYPE, core.Id)
                    ),
                    "Type" : AWS_EC2_LAUNCH_CONFIG_RESOURCE_TYPE
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
    [#return result ]
[/#function]
