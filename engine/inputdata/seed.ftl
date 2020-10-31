[#ftl]

[#-- Provider command line information --]
[#macro seedCoreProviderInputSourceData providers... ]

    [#list asFlattenedArray(providers) as provider]
        [#-- First seed input data shared across the provider --]
        [@internalSeedCoreProviderInputSourceData
            provider=provider
            inputSource="shared"
        /]

        [#-- Determine the input source specific input data --]
        [#if commandLineOptions.Input.Source?has_content]
            [@internalSeedCoreProviderInputSourceData
                provider=provider
                inputSource=commandLineOptions.Input.Source
            /]
        [/#if]
    [/#list]

[/#macro]

[#-- Provider input data --]
[#macro seedProviderInputSourceData providers... ]

    [#list asFlattenedArray(providers) as provider]
        [#-- First seed input data shared across the provider --]
        [@internalSeedProviderInputSourceData
            provider=provider
            inputSource="shared"
        /]

        [#-- Determine the input source specific input data --]
        [#if commandLineOptions.Input.Source?has_content]
            [@internalSeedProviderInputSourceData
                provider=provider
                inputSource=commandLineOptions.Input.Source
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
            message="Unable to invoke module or parmeters were invalid"
            context=moduleMacroOptions
            enabled=true
        /]
    [/#if]
[/#macro]

[#------------------------------------------------------
-- Internal support functions for provider processing --
--------------------------------------------------------]

[#macro internalSeedCoreProviderInputSourceData provider inputSource ]

    [#-- seed in data provided at the inputsources level for provider and inputSource --]
    [#list [ "commandlineoption", "masterdata" ] as level ]
        [#local seedMacroOptions =
            [
                [ provider, "input", inputSource, level, "seed" ]
            ]]

        [#local seedMacro = getFirstDefinedDirective(seedMacroOptions)]
        [#if seedMacro?has_content ]
            [@(.vars[seedMacro]) /]
        [#else]
            [@debug
                message="Unable to invoke any of the setting seed macro options"
                context=seedMacroOptions
                enabled=false
            /]
        [/#if]
    [/#list]

[/#macro]

[#macro internalSeedProviderInputSourceData provider inputSource ]

    [#-- seed in data provided at the inputsources level for provider and inputSource --]
    [#list [ "blueprint", "stackoutput", "setting", "definition"  ] as level ]
        [#local seedMacroOptions =
            [
                [ provider, "input", inputSource, level, "seed" ]
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
