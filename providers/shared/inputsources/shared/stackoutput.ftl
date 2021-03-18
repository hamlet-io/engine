[#ftl]

[#-- Mock function --]
[#function getSharedMockStackOutputs id="" deploymentUnit="" level="" region="" account=""]
    [#switch id?split("X")?last ]
        [#case URL_ATTRIBUTE_TYPE ]
            [#local value = "https://mock.local/" + id ]
            [#break]
        [#case IP_ADDRESS_ATTRIBUTE_TYPE ]
            [#local value = "123.123.123.123" ]
            [#break]
        [#default]
            [#local value = formatId( "##MockOutput", id, "##") ]
    [/#switch]

    [#return
        [
            {
                "Account" : account,
                "Region" : region,
                "Level" : level,
                "DeploymentUnit" : deploymentUnit,
                id : value
            }
        ]
    ]
[/#function]

[#-- Cloudformation Stack Output Processing --]
[#-- Stack outputs from cloudformation are processed based on the output from the awscli command --]
[#-- aws cloudformation describe-stacks --]
[#-- The component level is determined by the first part of the file name --]

[#-- cloudformation stack outputs are used as the default shared format to align with PseudoStack Output script --]

[#function getCFCompositeStackOutputs id="" deploymentUnit="" level="" region="" account=""]

    [#local result = []]
    [#list getCompositeStackOutputs() as stackOutputFile ]

        [#local level = ((stackOutputFile["FileName"])?split('-'))[0] ]

        [#list (stackOutputFile["Content"]![]) as rawStackOutput ]
            [#if (rawStackOutput["Stacks"]!{})?has_content ]
                [#list rawStackOutput["Stacks"] as stack ]
                    [#if (stack["Outputs"]![])?has_content ]

                        [#local stackOutput = {} ]

                        [#if stack["Outputs"]?is_sequence ]
                            [#list stack["Outputs"] as output ]
                                [#local stackOutput += {
                                    output.OutputKey : output.OutputValue
                                }]
                            [/#list]
                        [/#if]

                        [#if stack["Outputs"]?is_hash ]
                            [#local stackOutput = stack["Outputs"] ]
                        [/#if]

                        [#if stackOutput?has_content ]
                            [#local result += [ mergeObjects( { "Level" : level} , stackOutput) ] ]
                        [/#if]
                    [/#if]
                [/#list]
            [/#if]
        [/#list]
    [/#list]

    [#return result]
[/#function]
