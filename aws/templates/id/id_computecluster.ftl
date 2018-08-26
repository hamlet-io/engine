[#-- Components --]
[#assign COMPUTECLUSTER_COMPONENT_TYPE = "computecluster"]

[#assign componentConfiguration +=
    {
        COMPUTECLUSTER_COMPONENT_TYPE : [
            {
                "Name" : ["Fragment", "Container"],
                "Type" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Name" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Name" : "UseInitAsService",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Name" : "MinUpdateInstances",
                "Type" : NUMBER_TYPE,
                "Default" : 1
            }
            {
                "Name" : "ReplaceOnUpdate",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Name" : "UpdatePauseTime",
                "Type" : STRING_TYPE,
                "Default" : "5M"
            },
            {
                "Name" : "StartupTimeout",
                "Type" : STRING_TYPE,
                "Default" : "15M"
            },
            {
                "Name" : "DockerHost",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Name" : "Ports",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Name" : "IPAddressGroups",
                        "Type" : ARRAY_OF_STRING_TYPE,
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
                    "Id" : formatResourceId( AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE, core.Id ),
                    "Name" : core.FullName,
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
                    "Id" : formatResourceId(
                                AWS_EC2_LAUNCH_CONFIG_RESOURCE_TYPE,
                                core.Id,
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