[#ftl]

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

[#assign AWS_EIP_RESOURCE_TYPE = "eip" ]
[#assign AWS_EIP_ASSOCIATION_RESOURCE_TYPE = "eipAssoc" ]

[#assign AWS_SSH_KEY_PAIR_RESOURCE_TYPE = "sshKeyPair" ]

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

[#function formatEIPId ids...]
    [#return formatResourceId(
                AWS_EIP_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatEIPAssociationId ids...]
    [#return formatResourceId(
        AWS_EIP_ASSOCIATION_RESOURCE_TYPE,
        ids)]
[/#function]

[#function formatDependentEIPId resourceId extensions...]
    [#return formatEIPId(
                resourceId,
                extensions)]
[/#function]

[#function formatComponentEIPId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_EIP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatComponentEIPAssociationId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_EIP_ASSOCIATION_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]
