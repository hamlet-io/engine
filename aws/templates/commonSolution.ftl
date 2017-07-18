[#ftl]

[#-- Macros --]

[#macro createBlockDevices storageProfile]
    [#if (storageProfile.Volumes)?? ]
        "BlockDeviceMappings" : [
            [#list storageProfile.Volumes?values as volume]
                [#if volume?is_hash]
                    {
                        "DeviceName" : "${volume.Device}",
                        "Ebs" : {
                            "DeleteOnTermination" : true,
                            "Encrypted" : false,
                            "VolumeSize" : "${volume.Size}",
                            "VolumeType" : "gp2"
                        }
                    },
                [/#if]
            [/#list]
            {
                "DeviceName" : "/dev/sdc",
                "VirtualName" : "ephemeral0"
            },
            {
                "DeviceName" : "/dev/sdt",
                "VirtualName" : "ephemeral1"
            }
        ],
    [/#if]
[/#macro]

[#macro createComponentLogGroup tier component]
    [#local componentLogGroupId = formatComponentLogGroupId(tier, component)]
    [#if isPartOfCurrentDeploymentUnit(componentLogGroupId)]
        [@createLogGroup 
            solutionListMode
            componentLogGroupId
            formatComponentLogGroupName(
                tier,
                component)
        /]
    [/#if]
[/#macro]

