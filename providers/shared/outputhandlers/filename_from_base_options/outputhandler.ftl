[#ftl]

[@addOutputHandler
    id="filename_from_base_options"
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Get filename from command line options"
        }
    ]
/]

[#function shared_outputhandler_filename_from_base_options properties ]

    [#local filePrefix =
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

    [#return properties]
[/#function]
