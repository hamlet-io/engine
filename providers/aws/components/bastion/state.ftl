[#ftl]
[#macro aws_bastion_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#assign componentState =
        {
            "Resources" : {
                "eip" : {
                    "Id" : formatEIPId(core.Id),
                    "Name" : core.FullName,
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
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
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
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                },
                "launchConfig" : {

                    "Id" : solution.AutoScaling.AlwaysReplaceOnUpdate?then(
                                formatResourceId(AWS_EC2_LAUNCH_CONFIG_RESOURCE_TYPE, core.Id, commandLineOptions.Run.Id),
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
[/#macro]
