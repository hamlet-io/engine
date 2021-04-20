[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_schema ]

  [@generateOutput
    deploymentFramework=getCLODeploymentFramework()
    type=getCLODeploymentOutputType()
    format=getCLODeploymentOutputFormat()
  /]

[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_schema_inputsteps ]

    [@registerInputSeeder
        id=SCHEMA_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=SCHEMA_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Set the required flow/view --]
[#function schema_configseeder_commandlineoptions filter state]

    [#local schemaCLOConfig = state.CommandLineOptions.Schema!{}]
    [#local schemaId = "" ]
    [#local schemaPrefixed = false ]
    [#local schemaVersion = "latest" ]
    [#if schemaCLOConfig?has_content]
        [#local schemaId = schemaCLOConfig.Id!"" ]
        [#local schemaPrefixed = schemaCLOConfig.Prefixed!false ]
        [#local schemaVersion = schemaCLOConfig.Version!"latest" ]
    [/#if]

    [#return
        addToConfigPipelineClass(
            state,
            COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS,
            {
                "Deployment" : {
                    "Framework" : {
                        "Name" : DEFAULT_DEPLOYMENT_FRAMEWORK
                    }
                },
                "Flow" : {
                    "Names" : [ "views" ]
                },
                "View" : {
                    "Name" : SCHEMA_VIEW_TYPE
                },
                "Schema" : {
                    "Prefixed" : schemaPrefixed,
                    "Version" : schemaVersion
                } +
                attributeIfContent("Id", schemaId)
            }
        )
    ]

[/#function]
