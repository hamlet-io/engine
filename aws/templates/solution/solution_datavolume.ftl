[#-- DATAVOLUME --]

[#if componentType == DATAVOLUME_COMPONENT_TYPE  ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign solution = occurrence.Configuration.Solution]
        [#assign resources = occurrence.State.Resources]

        [#assign manualSnapshotId = resources["manualSnapshot"].Id]
        [#assign manualSnapshotName = getExistingReference(manualSnapshotId, NAME_ATTRIBUTE_TYPE)]

        [#list resources["Zones"] as zoneId, zoneResources ]
            [#assign volumeId = zoneResources["ebsVolume"].Id ]
            [#assign volumeName = zoneResources["ebsVolume"].Name ]

            [#assign volumeTags = getCfTemplateCoreTags(
                                        volumeName,
                                        tier,
                                        component,
                                        "",
                                        false)]
            
            [#assign resourceZone = {}]
            [#list zones as zone ]
                [#if zoneId == zone.Id ]
                    [#assign resourceZone = zone ]
                [/#if]
            [/#list]

            [#if deploymentSubsetRequired(DATAVOLUME_COMPONENT_TYPE, true)]
                [@createEBSVolume 
                    mode=listMode
                    id=volumeId
                    tags=volumeTags
                    size=solution.Size
                    volumeType=solution.VolumeType
                    encrypted=solution.Encrypted
                    provisionedIops=solution.ProvisionedIops
                    zone=resourceZone
                    snapshotId=manualSnapshotName
                /]
            [/#if]
        [/#list]

        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript
                mode=listMode
                content=
                [
                    "case $\{STACK_OPERATION} in",
                    "  create|update)"
                ] +    
                pseudoStackOutputScript(
                    "Manual Snapshot",
                    { manualSnapshotId : "" }
                ) +
                [            
                    "       ;;",
                    "       esac"
                ]
            /]
        [/#if]
    [/#list]
[/#if]