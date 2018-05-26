[#-- Components --]
[#assign COMPUTECLUSTER_COMPONENT_TYPE = "computecluster"]

[#assign componentConfiguration +=
    {
        COMPUTECLUSTER_COMPONENT_TYPE : [
            "Container",
            {
                "Name" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Name" : "MinUpdateInstances",
                "Default" : 1
            }
            {
                "Name" : "ReplaceOnUpdate",
                "Default" : false
            },
            {
                "Name" : "UpdatePauseTime",
                "Default" : "5M"
            },
            {
                "Name" : "StartupTimeout",
                "Default" : "15M"
            },
            {
                "Name" : "DockerHost",
                "Default" : false
            },
            {
                "Name" : "Ports",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Name" : "IPAddressGroups",
                        "Default" : []
                    },
                    {
                        "Name" : "LB",
                        "Children" : lbChildConfiguration
                    }
                ]
            }
        ]
    }]

[#function getComputeClusterState occurrence]
    
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution ]
    [#local buildReference = getOccurrenceBuildReference(occurrence) ]

    [#return
        {
            "Resources" : {
                "securityGroup" : {
                    "Id" : formatComponentSecurityGroupId(core.Tier, core.Component),
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "role" : {
                    "Id" : formatComponentRoleId(core.Tier, core.Component),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "instanceProfile" : {
                    "Id" : formatEC2InstanceProfileId(core.Tier, core.Component),
                    "Type" : AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE
                },
                "autoScaleGroup" : {
                    "Id" : formatEC2AutoScaleGroupId(core.Tier, core.Component),
                    "Type" : AWS_EC2_AUTO_SCALE_GROUP_RESOURCE_TYPE
                },
                "launchConfig" : {
                    "Id" : formatEC2LaunchConfigId(
                                core.Tier, 
                                core.Component, 
                                [#-- changing the launch config logical Id forces a replacement of the autoscale group instances --]
                                [#-- we only want this to happen when the build reference changes --]
                                replaceAlphaNumericOnly(buildReference)),
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
[/#function]