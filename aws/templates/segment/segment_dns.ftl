[#-- Private DNS zone --]
[#if componentType == "dns" &&
        deploymentSubsetRequired("dns", true)]
    [@cfTemplate
        mode=segmentListMode
        id=formatSegmentDNSZoneId()
        type="AWS::Route53::HostedZone"
        properties=
            {
                "HostedZoneConfig" : {
                    "Comment" : formatName(productName, segmentName)
                },
                "HostedZoneTags" : getCfTemplateCoreTags(),
                "Name" : segmentName + "." + productName + ".internal",
                "VPCs" : [                
                    {
                        "VPCId" : getReference(formatVPCId()),
                        "VPCRegion" : regionId
                    }
                ]
            }
    /]
[/#if]

