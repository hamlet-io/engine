[#ftl]

[@addOutputHandler
    id="filename_from_base_options"
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Generate a base file name using the standard command line input options"
        }
    ]
/]

[#function shared_outputhandler_filename_from_base_options properties content ]

    [#local outputPrefix =
            getOutputFilePrefix(
                commandLineOptions.Entrance.Type,
                getDeploymentGroup(),
                getDeploymentUnit(),
                "",
                "",
                "",
                "",
                ""
            )]

    [#local outputSuffixMapping = getGenerationContractStepOutputMapping(
                                    combineEntities(
                                        commandLineOptions.Deployment.Provider.Names,
                                        [ SHARED_PROVIDER],
                                        UNIQUE_COMBINE_BEHAVIOUR
                                    ),
                                commandLineOptions.Deployment.Unit.Subset )]

    [#local outputSuffix = (outputSuffixMapping["OutputSuffix"])!"missing.json" ]
    [#local outputFileName = formatName(outputPrefix, outputSuffix )]

    [#local currentProperties = getOutputFileProperties()]

    [#-- Only use the default option if it hasn't been set --]
    [#if ! ((currentProperties.filename)!"")?has_content]
        [#local properties = mergeObjects( properties, { "filename" : outputFileName })]
    [/#if]

    [#return properties]
[/#function]
