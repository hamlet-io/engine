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
/]

[#function shared_dynamicvalue_output value properties sources={} ]

    [#if sources.occurrence?? ]
        [#if ! [RUNBOOK_COMPONENT_TYPE, RUNBOOK_STEP_COMPONENT_TYPE]?seq_contains(sources.occurrence.Core.Type) ]
            [@fatal
                message="Dynamic value type ${OUTPUT_DYNAMIC_VALUE_TYPE} only supported for runbooks"
                context={
                    "ComponentId" : sources.occurrence.Core.Component.RawId,
                    "SubComponentId" : (sources.occur.Core.SubComponent.RawId)!"",
                    "DynamicValue" : "__${value}__"
                }
            /]
        [/#if]
    [/#if]

    [#if sources.inputs?? && sources.occurrence?? ]
        [#if ! (sources.stepIds)?seq_contains(properties.stepId) ]
            [@fatal
                message="Step could not be found for output"
                context={
                    "Step" : sources.occurrence.Core.Component.RawId,
                    "Output" :{
                        "StepId" : properties.stepId,
                        "OutputKey" : properties.outputKey
                    }
                }
            /]
        [/#if]

        [#return "__Properties:${value}__"  ]
    [/#if]

    [#return "__${value}__"]
[/#function]
