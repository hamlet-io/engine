[#-- Security Group --]
[#if ! (component.S3?? || component.SQS?? || component.ElasticSearch??) ]
    [#if count > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
                            "securityGroupX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::EC2::SecurityGroup",
                                "Properties" : {
                                    "GroupDescription": "Security Group for ${tier.Name}-${component.Name}",
                                    "VpcId": "${vpc}",
                                    "Tags" : [
                                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                                        { "Key" : "cot:account", "Value" : "${accountId}" },
                                        { "Key" : "cot:product", "Value" : "${productId}" },
                                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                                        { "Key" : "cot:category", "Value" : "${categoryId}" },
                                        { "Key" : "cot:tier", "Value" : "${tier.Id}" },
                                        { "Key" : "cot:component", "Value" : "${component.Id}" },
                                        { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}" }
                                    ]
                                }
                            }
            [#break]

        [#case "outputs"]
                            "securityGroupX${tier.Id}X${component.Id}" : {
                                "Value" : { "Ref" : "securityGroupX${tier.Id}X${component.Id}" }
                            }
            [#break]

    [/#switch]
    [#assign count += 1]
[/#if]