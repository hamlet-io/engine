[#-- Resources --]
[#assign AWS_EC2_INSTANCE_RESOURCE_TYPE = "ec2Instance" ]
[#assign AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE = "instanceProfile" ]
[#assign AWS_EC2_AUTO_SCALE_GROUP_RESOURCE_TYPE = "asg" ]
[#assign AWS_EC2_LAUNCH_CONFIG_RESOURCE_TYPE = "launchConfig" ]
[#assign AWS_EC2_NETWORK_INTERFACE_RESOURCE_TYPE = "eni" ]
[#assign AWS_EC2_KEYPAIR_RESOURCE_TYPE = "keypair" ]

[#assign AWS_EC2_EBS_RESOURCE_TYPE = "ebs" ]
[#assign AWS_EC2_EBS_ATTACHMENT_RESOURCE_TYPE = "ebsAttachment" ]
[#assign AWS_EC2_EBS_MANUAL_SNAPSHOT_RESOURCE_TYPE = "manualsnapshot" ]

[#function formatEC2InstanceId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_EC2_INSTANCE_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatEC2InstanceProfileId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatEC2AutoScaleGroupId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_EC2_AUTO_SCALE_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatEC2LaunchConfigId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_EC2_LAUNCH_CONFIG_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatEC2ENIId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_EC2_NETWORK_INTERFACE_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatEC2SecurityGroupId tier component]
    [#return formatComponentSecurityGroupId(
                        tier,
                        component)]
[/#function]

[#function formatEC2RoleId tier component]
    [#-- TODO: Use formatDependentRoleId() --]
    [#return formatComponentRoleId(
                tier,
                component)]
[/#function]

[#function formatEC2SecurityGroupIngressId tier component port]
    [#return formatComponentSecurityGroupIngressId(
                tier,
                component,
                port.Port?c)]
[/#function]

[#function formatEC2KeyPairId extensions...]
    [#return formatSegmentResourceId(
                AWS_EC2_KEYPAIR_RESOURCE_TYPE,
                extensions)]
[/#function]

[#macro aws_ec2_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]

    [#local zoneResources = {}]

    [#list zones as zone ]
        [#local zoneResources +=
            { zone.Id : {
                "ec2Instance" : {
                    "Id"   : formatResourceId(AWS_EC2_INSTANCE_RESOURCE_TYPE, core.Id, zone.Id),
                    "Name" : formatName(tenantId, formatComponentFullName(core.Tier, core.Component), zone.Id),
                    "Type" : AWS_EC2_INSTANCE_RESOURCE_TYPE
                },
                "ec2ENI" : {
                    "Id" : formatResourceId(AWS_EC2_NETWORK_INTERFACE_RESOURCE_TYPE, core.Id, zone.Id, "eth0"),
                    "Type" : AWS_EC2_NETWORK_INTERFACE_RESOURCE_TYPE
                },
                "ec2EIP" : {
                    "Id" : getExistingReference(formatEIPId( core.Id, zone.Id))?has_content?then(
                        formatEIPId( core.Id, zone.Id),
                        formatEIPId( core.Id, zone.Id, "eth0")
                    ),
                    "Type" : AWS_EIP_RESOURCE_TYPE
                },
                "ec2EIPAssociation" : {
                    "Id" : formatEIPAssociationId( core.Id, zone.Id, "eth0"),
                    "Type" : AWS_EIP_ASSOCIATION_RESOURCE_TYPE
                }
            }}
        ]
    [/#list]

    [#assign componentState =
        {
            "Resources" : {
                "instanceProfile" : {
                    "Id" : formatEC2InstanceProfileId(core.Tier, core.Component),
                    "Type" : AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE
                },
                "sg" : {
                    "Id" : formatComponentSecurityGroupId(core.Tier, core.Component),
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "ec2Role" : {
                    "Id" : formatComponentRoleId(core.Tier, core.Component),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "lg" : {
                    "Id" : formatLogGroupId(core.Id),
                    "Name" : core.FullAbsolutePath,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                },
                "Zones" : zoneResources
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