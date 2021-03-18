[#ftl]

[#macro shared_view_default_validate_generationcontract ]
    [@addDefaultGenerationContract subsets="config" /]
[/#macro]

[#macro shared_view_default_validate_config ]

    [#-- perform validation --]
    [#local blueprintAttributes = getBlueprintConfiguration()]
    [#local validComposite = getBluePrintObject(blueprintAttributes, blueprintObject)]

    [#if getLogLevel() > INFORMATION_LOG_LEVEL]
        [#local logLevel = updateLogLevel(INFORMATION_LOG_LEVEL)]
    [/#if]
    [@info
        message="Blueprint Validation Results"
        context=
            {
                "BlueprintAttributes" : blueprintAttributes,
                "Blueprint" : blueprintObject,
                "Composite" : validComposite
            }
        enabled=true
    /]

    [@addToDefaultJsonOutput
        content=logMessages
    /]
[/#macro]