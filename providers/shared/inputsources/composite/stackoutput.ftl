[#ftl]

[#macro shared_input_composite_stackoutput_seed id="" deploymentUnit="" level="" region="" account=""]

    [#local stackOutputs = [] ]

    [#-- Cloudformation Stack Output Processing --]
    [#-- Stack outputs from cloudformation are processed based on the output from the awscli command --]
    [#-- aws cloudformation describe-stacks --]
    [#-- The component level is determined by the first part of the file name --]
    [#list commandLineOptions.Composites.StackOutputs as stackOutputFile ]

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

                        [#if stack["Outputs"]?is_collection ]
                            [#local stackOutput = stack["Outputs"] ]
                        [/#if]

                        [#if stackOutput?has_content ]
                            [#local stackOutputs += [ mergeObjects( { "Level" : level} , stackOutput) ] ]
                        [/#if]
                    [/#if]
                [/#list]
            [/#if]
        [/#list]
    [/#list]

    [@addStackOutputs stackOutputs /]
[/#macro]
