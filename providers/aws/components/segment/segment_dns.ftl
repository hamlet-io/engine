[#ftl]
[#macro aws_dns_cf_generationcontract_segment occurrence ]
    [@addDefaultGenerationContract subsets="template" /]
[/#macro]

[#macro aws_dns_cf_setup_segment occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("dns", true)]
        [@cfResource
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
