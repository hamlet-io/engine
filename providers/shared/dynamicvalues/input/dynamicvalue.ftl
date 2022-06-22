[#ftl]

[@addDynamicValueProvider
    type=INPUT_DYNAMIC_VALUE_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Returns the value of a runbook input"
        }
    ]
    parameterOrder=["inputId"]
    parameterAttributes=[
        {
            "Names" : "inputId",
            "Description" : "The Id of the runbook input",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

[#function shared_dynamicvalue_input value properties sources={} ]

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
        [#if ! sources.inputs?keys?seq_contains(properties.inputId)?has_content ]
            [@fatal
                message="Input Id could not be found"
                context={
                    "Step" : sources.occurrence.Core.Component.RawId,
                    "Input" : inputId
                }
            /]
        [/#if]

        [#return (sources.inputs["input:${properties.inputId}"])!"" ]
    [/#if]

    [#return "__${value}__"]
[/#function]
