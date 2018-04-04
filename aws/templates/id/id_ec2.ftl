[#-- EC2 --]

[#-- Resources --]
[#assign AWS_EC2_INSTANCE_RESOURCE_TYPE = "ec2Instance" ]
[#assign AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE = "instanceProfile" ]
[#assign AWS_EC2_AUTO_SCALE_GROUP_RESOURCE_TYPE = "asg" ]
[#assign AWS_EC2_LAUNCH_CONFIG_RESOURCE_TYPE = "launchConfig" ]
[#assign AWS_EC2_NETWORK_INTERFACE_RESOURCE_TYPE = "eni" ]

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

[#-- Components --]
[#assign EC2_COMPONENT_TYPE = "ec2"]

[#assign componentConfiguration +=
    {
        EC2_COMPONENT_TYPE : [
            {
                "Name" : "FixedIP",
                "Default" : false
            },
            {
                "Name" : "LoadBalanced",
                "Default" : false
            },
            {
                "Name" : "DockerHost",
                "Default" : false
            },
            {
                "Name" : "Ports",
                "Default" : []
            }
        ]
    }]

[#function getEc2State occurrence]
    [#local core = occurrence.Core]

    [#local ec2ELBId = formatELBId("elb", core.Id) ]

    [#return
        {
            "Resources" : {
                "ec2Instance" : { 
                    "Id" : formatEC2InstanceId(core.Tier, core.Component),
                    "Name" : formatName(tenantId, formatComponentFullName(core.Tier, core.Component)),
                    "Type" : AWS_EC2_INSTANCE_RESOURCE_TYPE
                },
                "instanceProfile" : {
                    "Id" : formatEC2InstanceProfileId(core.Tier, core.Component),
                    "Type" : AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE
                },
                "secGroup" : { 
                    "Id" : formatSecurityGroupId(core.Id),
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "ec2Role" : { 
                    "Id" : formatComponentRoleId(core.Tier, core.Component),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "ec2ELB" : {
                    "Id" : ec2ELBId,
                    "Type" : AWS_ELB_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "FQDN" : getReference(ec2ELBId, DNS_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]