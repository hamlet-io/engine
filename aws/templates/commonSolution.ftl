[#ftl]

[#-- Macros --]

[#function getBlockDevices storageProfile]
    [#if (storageProfile.Volumes)?has_content]
        [#local ebsVolumes = [] ]
        [#list storageProfile.Volumes?values as volume]
            [#if volume?is_hash]
                [#local ebsVolumes +=
                    [
                        {
                            "DeviceName" : volume.Device,
                            "Ebs" : {
                                "DeleteOnTermination" : true,
                                "Encrypted" : false,
                                "VolumeSize" : volume.Size,
                                "VolumeType" : "gp2"
                            }
                        }
                    ]
                ]
            [/#if]
        [/#list]
        [#return
            {
                "BlockDeviceMappings" :
                    ebsVolumes + 
                    [
                        {
                            "DeviceName" : "/dev/sdc",
                            "VirtualName" : "ephemeral0"
                        },
                        {
                            "DeviceName" : "/dev/sdt",
                            "VirtualName" : "ephemeral1"
                        }
                    ]
            }
        ]
    [#else]
        [#return {} ]
    [/#if]
[/#function]
