[#ftl]

[#-- Override command line options for region setup --]
[#-- This should be a valid region in the Masterdata --]
[#macro shared_input_mock_commandlineoption_seed ]
    [@addCommandLineOption
        option={
            "Regions" : {
                "Segment" : "ap-southeast-2",
                "Account" : "ap-southeast-2"
            }
        }
    
    /]
[/#macro]
