[#ftl]

[@addExtension
    id="s3vpcaccess"
    aliases=[
        "_s3vpcaccess"
    ]
    description=[
        "Set up an access within VPC to s3 items"
    ]
    supportedTypes=[
        "*"
    ]
/]

[#macro shared_extension_s3vpcaccess_deployment_setup occurrence ]
        [#local solution = occurrence.Configuration.Solution ]
        [#local policyStatements = [] ]
        [#local resources = occurrence.State.Resources ]
        [#local s3Name = resources["bucket"].Name ]

        [#list solution.PublicAccess?values as publicAccessConfiguration]
        [#list publicAccessConfiguration.Paths as publicPrefix]
            [#if publicAccessConfiguration.Enabled ]
                [#local publicIPWhiteList =
                    getIPCondition(getGroupCIDRs(publicAccessConfiguration.IPAddressGroups, true)) ]

                [#-- aws:SourceVpc condition is needed to make public files accessible from docker containers running within VPC --]

                [#local occurrenceNetwork = getOccurrenceNetwork(occurrence) ]
                [#local networkLink = occurrenceNetwork.Link!{} ]
                [#if networkLink?has_content ]
                    [#local networkLinkTarget = getLinkTarget(occurrence, networkLink, false) ]
                    [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
                    [#local networkResources = networkLinkTarget.State.Resources ]
                    [#local vpcId = networkResources["vpc"].Id ]

                    [#switch publicAccessConfiguration.Permissions ]
                        [#case "ro" ]
                            [#local policyStatements += s3ReadPermission(
                                                            s3Name,
                                                            publicPrefix,
                                                            "*",
                                                            "*",
                                                            {
                                                                "StringEquals": {
                                                                    "aws:SourceVpc": getExistingReference(vpcId)
                                                                }
                                                            })]
                            [#break]
                        [#case "wo" ]
                            [#local policyStatements += s3WritePermission(
                                                            s3Name,
                                                            publicPrefix,
                                                            "*",
                                                            "*",
                                                            {
                                                                "StringEquals": {
                                                                    "aws:SourceVpc": getExistingReference(vpcId)
                                                                }
                                                            })]
                            [#break]
                        [#case "rw" ]
                            [#local policyStatements += s3AllPermission(
                                                            s3Name,
                                                            publicPrefix,
                                                            "*",
                                                            "*",
                                                            {
                                                                "StringEquals": {
                                                                    "aws:SourceVpc": getExistingReference(vpcId)
                                                                }
                                                            })]
                            [#break]
                    [/#switch]
                [/#if]


            [/#if]
        [/#list]
    [/#list]

    [#assign _context +=
        {
            "Policy" : policyStatements
        }
    ]

[/#macro]
