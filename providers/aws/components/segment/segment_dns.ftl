[#ftl]
[#macro aws_dns_cf_segment occurrence ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["template"])
        /]
        [#return]
    [/#if]

    [@cfDebug listMode occurrence false /]

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
[/#macro]
