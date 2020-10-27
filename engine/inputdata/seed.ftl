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

[#macro seedScenarioData provider name parameters={} ]

    [#-- Run the scenario to load the data --]
    [#local scenarioMacroOptions =
        [
            [ provider, "scenario", name ]
        ]]

    [#local scenarioMacro = getFirstDefinedDirective(scenarioMacroOptions)]

    [#local parameterConfig = {}]
    [#list parameters?values as parameter ]
        [#local parameterConfig = mergeObjects(
                                    parameterConfig,
                                    {
                                        parameter.Key : parameter.Value
                                    }

                                )]
    [/#list]

    [#local scenarioDetails = getScenarioDetails(name, provider, parameterConfig)]

    [#if scenarioMacro?has_content && scenarioDetails?has_content ]
        [@(.vars[scenarioMacro])?with_args(scenarioDetails.Parameters) /]
    [#else]
        [@debug
            message="Unable to invoke scenario or parmeters were invalid"
            context=scenarioMacroOptions
            enabled=false
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
