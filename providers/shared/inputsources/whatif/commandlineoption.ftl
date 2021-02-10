[#ftl]

[#-- This should be a valid region in the Masterdata --]
[#macro shared_input_whatif_commandlineoption_seed ]

    [#-- Reference metadata --]
    [@addCommandLineOption
        option={
            "References" : {
                "Request" : requestReference!"",
                "Configuration" : configurationReference!""
            }
        }
    /]

    [#-- Composite Inputs --]
    [@addCommandLineOption
        option={
            "Composites" : {
                "Blueprint" : (blueprint!"")?has_content?then(
                                    blueprint?eval,
                                    {}
                ),
                "Settings" : (settings!"")?has_content?then(
                                    settings?eval,
                                    {}
                ),
                "Definitions" : ((definitions!"")?has_content && (!definitions?contains("null")))?then(
                                    definitions?eval,
                                    {}
                ),
                "StackOutputs" : (stackOutputs!"")?has_content?then(
                                    stackOutputs?eval,
                                    []
                )
            }
        }
    /]

    [#-- Regions --]
    [@addCommandLineOption
        option={
            "Regions" : {
                "Segment" : region!"",
                "Account" : accountRegion!""
            }
        }
    /]

[/#macro]
