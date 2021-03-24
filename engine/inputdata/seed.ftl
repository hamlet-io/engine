[#ftl]

[#-- Provider input data --]
[#macro seedProviderInputSourceData providers inputTypes ]

    [#list asFlattenedArray(providers) as provider]
        [#-- First seed input data shared across the provider --]
        [@internalSeedInputSourceData
            provider=provider
            inputTypes=inputTypes
            inputSource="shared"
        /]

        [#-- Determine the input source specific input data --]
        [#if getInputSource()?has_content]
            [@internalSeedInputSourceData
                provider=provider
                inputTypes=inputTypes
                inputSource=getInputSource()
            /]
        [/#if]
    [/#list]
[/#macro]

[#macro seedModuleData provider name parameters={} ]

    [#-- Run the module macro to load the data --]
    [#local moduleMacroOptions =
        [
            [ provider, "module", name ]
        ]]

    [#local moduleMacro = getFirstDefinedDirective(moduleMacroOptions)]

    [#local parameterConfig = {}]
    [#list parameters?values as parameter ]
        [#local parameterConfig = mergeObjects(
                                    parameterConfig,
                                    {
                                        parameter.Key : parameter.Value
                                    }

                                )]
    [/#list]

    [#local moduleDetails = getModuleDetails(name, provider, parameterConfig)]

    [#if moduleMacro?has_content && moduleDetails?has_content ]
        [@(.vars[moduleMacro])?with_args(moduleDetails.Parameters) /]
    [#else]
        [@debug
            message="Unable to invoke module or parameters were invalid"
            context=moduleMacroOptions
            enabled=true
        /]
    [/#if]
[/#macro]

[#------------------------------------------------------
-- Internal support functions for provider processing --
--------------------------------------------------------]
[#macro internalSeedInputSourceData provider inputSource inputTypes ]

    [#-- seed in data provided through inputsources  --]
    [#list asFlattenedArray(inputTypes) as type ]
        [#local seedMacroOptions =
            [
                [ provider, "input", inputSource, type, "seed" ]
            ]]

        [#local seedMacro = getFirstDefinedDirective(seedMacroOptions)]
        [#if seedMacro?has_content ]
            [@(.vars[seedMacro]) /]
        [#else]
            [@debug
                message="Unable to invoke any of the input seed macro options"
                context=seedMacroOptions
                enabled=false
            /]
        [/#if]
    [/#list]
[/#macro]
