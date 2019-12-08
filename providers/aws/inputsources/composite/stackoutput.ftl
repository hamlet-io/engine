[#ftl]

[#-- Get stack output --]
[#function aws_input_composite_stackoutput_filter outputFilter ]
    [#return {
        "Account" : (outputFilter.Account)!accountObject.AWSId,
        "Region" : outputFilter.Region,
        "DeploymentUnit" : outputFilter.DeploymentUnit
    }]
[/#function]

[#macro aws_input_composite_stackoutput_seed id="" deploymentUnit="" level="" region="" account=""]

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

                    [#local stackOutput = {
                        "Level" : level
                    } ]

                    [#if (stack["Outputs"]![])?has_content ]
                        [#list stack["Outputs"] as output ]
                            [#local stackOutput += {
                                output.OutputKey : output.OutputValue
                            }]
                        [/#list]
                    [/#if]

                    [#local stackOutputs += [ stackOutput ] ]

                [/#list]
            [/#if]
        [/#list]
    [/#list]

    [@addStackOutputs stackOutputs /]
[/#macro]
