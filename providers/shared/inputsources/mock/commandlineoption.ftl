[#ftl]

[#-- This should be a valid region in the Masterdata --]
[#macro shared_input_mock_commandlineoption_seed ]

    [@addCommandLineOption
        option={
            "Regions" : {
                "Segment" : "mock-region-1",
                "Account" : "mock-region-1"
            },
            "References" : {
                "Request" : "SRVREQ01",
                "Configuration" : "configRef_v123"
            }
        }
    /]
[/#macro]
