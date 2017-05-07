[#ftl]
[#include "setContext.ftl"]

[#-- Functions --]

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

[#-- Initialisation --]

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    [#assign compositeList=solutionList]
    "Resources" : {
        [#assign solutionListMode="definition"]
        [#include "componentList.ftl"]
    },
    
    "Outputs" : {
        [#assign solutionListMode="outputs"]
        [#include "componentList.ftl"]
    }
}
