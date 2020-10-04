[#ftl]

[#-- Views --]
[#-- Views allow for a freeform output generation using a similar approach to component processing --]
[#-- Providers can offer their own views which can be used to provide a specific output based on any part of a CMDB --]
[#-- Views are invoked through a Model Scope which allows for the view to be implemented across different models --]

[#function invokeViewMacro provider deploymentFramework documentSet qualifiers=[] ]
    [#local macroOptions = [] ]
    [#list qualifiers as qualifier]
        [#local macroOptions +=
            [
                [ provider, "view", deploymentFramework, documentSet ] + asArray(qualifier),
                [ provider, "view", documentSet ] + asArray(qualifier)
            ]]
    [/#list]

    [#local macroOptions +=
        [
            [ provider, "view", deploymentFramework, documentSet],
            [ provider, "view", documentSet ]
        ]]

    [#list qualifiers as qualifier]
        [#local macroOptions +=
            [
                [ SHARED_PROVIDER, "view", deploymentFramework, documentSet ] + asArray(qualifier),
                [ SHARED_PROVIDER, "view", documentSet ] + asArray(qualifier)
            ]]
    [/#list]

    [#local macroOptions += [
        [ SHARED_PROVIDER, "view", deploymentFramework, documentSet ],
        [ SHARED_PROVIDER, "view", documentSet ]
    ]]
    [#local macro = getFirstDefinedDirective(macroOptions)]
    [#if macro?has_content]
        [@(.vars[macro]) /]
        [#return true]
    [#else]
        [@debug
            message="Unable to invoke any of the macro options"
            context=macroOptions
            enabled=true
        /]
    [/#if]
    [#return false]
[/#function]
