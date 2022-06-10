[#ftl]

[@addDynamicValueProvider
    type=OUTPUT_DYNAMIC_VALUE_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Returns the value of a runbook step output"
        }
    ]
    parameterOrder=["stepId", "outputKey"]
    parameterAttributes=[
        {
            "Names" : "stepId",
            "Description" : "The Id of the step to collect the output from",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "outputKey",
            "Description" : "The key of the output to return",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
    supportedComponentTypes=[
        RUNBOOK_COMPONENT_TYPE,
        RUNBOOK_STEP_COMPONENT_TYPE
    ]
/]

[#function shared_dynamicvalue_output value properties occurrence extraSources={} ]

    [#if ((extraSources.stepIds)!{})?has_content]
        [#if ! (extraSources.stepIds)?seq_contains(properties.stepId) ]
            [@fatal
                message="Step could not be found for output"
                context={
                    "Step" : occurrence.Core.Component.RawId,
                    "Output" :{
                        "StepId" : properties.stepId,
                        "OutputKey" : properties.outputKey
                    }
                }
            /]
        [/#if]

        [#return "__Properties:${value}__"  ]
    [/#if]

    [#return value]
[/#function]
