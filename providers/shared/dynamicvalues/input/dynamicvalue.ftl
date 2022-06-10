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
    supportedComponentTypes=[
        RUNBOOK_COMPONENT_TYPE,
        RUNBOOK_STEP_COMPONENT_TYPE
    ]
/]

[#function shared_dynamicvalue_input value properties occurrence extraSources={} ]
    [#if ((extraSources.inputs)!{})?has_content]

        [#if ! extraSources.inputs?keys?seq_contains(properties.inputId)?has_content ]
            [@fatal
                message="Input Id could not be found"
                context={
                    "Step" : occurrence.Core.Component.RawId,
                    "Input" : inputId
                }
            /]
        [/#if]
        [#return "__Properties:${value}__" ]
    [/#if]

    [#return value]
[/#function]
