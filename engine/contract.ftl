[#ftl]

[#-- Standard routines for contract output generation --]

[#macro shared_output_contract level="" include=""]
    [#-- Resources --]
    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@processComponents level /]
    [/#if]

    [#if getOutputContent("stage")?has_content || logMessages?has_content]
        [@toJSON
            {
                "Metadata" : {
                    "Id" : getOutputContent("contract"),
                    "Prepared" : .now?iso_utc,
                    "RunId" : commandLineOptions.Run.Id,
                    "RequestReference" : commandLineOptions.References.Request,
                    "ConfigurationReference" : commandLineOptions.References.Configuration
                },
                "Stages" : getOutputContent("stages")
            } +
            attributeIfContent("COTMessages", logMessages)
        /]
    [/#if]
[/#macro]

[#assign CONTRACT_EXECUTION_MODE_SERIAL = "serial" ]
[#assign CONTRACT_EXECUTION_MODE_PARALLEL = "parallel" ]

[#function getContractStage id executionMode steps ]
    [#return
        {
            "Id" : id,
            "ExeuctionMode" : executionMode,
            "Steps" : asArray(steps)
        }

    ]
[/#function]

[#function getContractStep id task parameters ]
    [#return
        {
            "Id" : id,
            "Task" : task,
            "Parameters" : parameters
        }
    ]
[/#function]
