[#ftl]

[#-- Views --]
[#-- Views allow for a freeform output generation using a similar approach to component processing --]
[#-- Providers can offer their own views which can be used to provide a specific output based on any part of a CMDB --]
[#-- View components use the views flow to generate their output --]

[#function invokeViewMacro provider deploymentFramework entrance qualifiers=[] ]
    [#local macroOptions = [] ]
    [#list asArray(qualifiers) as qualifier]
        [#local macroOptions +=
            [
                [ provider, "view", deploymentFramework, entrance ] + asFlattenedArray(qualifier, true),
                [ provider, "view", entrance ] + asFlattenedArray(qualifier, true)
            ]]
    [/#list]

    [#local macroOptions +=
        [
            [ provider, "view", deploymentFramework, entrance],
            [ provider, "view", entrance ]
        ]]

    [#list qualifiers as qualifier]
        [#local macroOptions +=
            [
                [ SHARED_PROVIDER, "view", deploymentFramework, entrance ] + asFlattenedArray(qualifier, true),
                [ SHARED_PROVIDER, "view", entrance ] + asFlattenedArray(qualifier, true)
            ]]
    [/#list]

    [#local macroOptions += [
        [ SHARED_PROVIDER, "view", deploymentFramework, entrance ],
        [ SHARED_PROVIDER, "view", entrance ]
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
