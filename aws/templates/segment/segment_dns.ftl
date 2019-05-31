[#-- Private DNS zone --]
[#if componentType == "dns" &&
        deploymentSubsetRequired("dns", true)]
    [@cfResource
        mode=listMode
        id=formatSegmentDNSZoneId()
        type="AWS::Route53::HostedZone"
        properties=
            {
                "HostedZoneConfig" : {
                    "Comment" : formatSegmentFullName()
                },
                "HostedZoneTags" : getOccurrenceCoreTags(),
                "Name" : concatenate(fullNamePrefixes?reverse + ["internal"], "."),
                "VPCs" : [
                    {
                        "VPCId" : getReference(formatVPCId()),
                        "VPCRegion" : regionId
                    }
                ]
            }
    /]
[/#if]

