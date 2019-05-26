[#ftl]
[#macro segment_dns tier component]
    [#-- Private DNS zone --]
    [#if deploymentSubsetRequired("dns", true)]
        [@cfResource
            mode=listMode
            id=formatSegmentDNSZoneId()
            type="AWS::Route53::HostedZone"
            properties=
                {
                    "HostedZoneConfig" : {
                        "Comment" : formatSegmentFullName()
                    },
                    "HostedZoneTags" : getCfTemplateCoreTags(),
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
[/#macro]

