[#ftl]
[#include "/bootstrap.ftl" ]

[#-- Load the entrance to make sure that it is defined --]
[#-- Avoid the variable "entrance" to ensure the input --]
[#-- variable isn't overwritten                        --]
[#assign entranceType = getCLOEntranceType() ]
[#assign entranceEntry = getEntrance(entranceType) ]

[#-- Ensure any entrance specific input processing is performed before attempting to validate the inputs. --]
[@addEntranceInputSteps
    type=entranceType
/]

[#-- Validate Command line options are right for the entrance --]
[#assign validCommandLineOptions = getCompositeObject(entranceEntry.Configuration, getCommandLineOptions()) ]

[#assign entrancePasses = []]
[#assign activePass = {} ]

[#assign ENTRANCE_PASS_STATUS_COMPLETED = "completed" ]
[#assign ENTRANCE_PASS_STATUS_FAILED = "failed" ]

[#-- Input seeding for handling invoking different passes through the entrance --]
[#assign ENTRANCE_PASS_INPUT_SEEDER = "entrancepass" ]

[@registerInputSeeder
    id=ENTRANCE_PASS_INPUT_SEEDER
    description="Input handling for passes through the entrance"
/]

[@addSeederToConfigPipeline
    stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
    seeder=ENTRANCE_PASS_INPUT_SEEDER
/]

[#-- The entrance passes are defined during the generation contract process --]
[#-- If a contract stage is passed to the engine then we treat those as the entrance passes required --]
[#if ! ((getCommandLineOptions().Contract.Stage)!{})?has_content ]

    [#-- Configure the pass as a generation contract --]
    [#assign generationContractPass =
        {
            "Type" : "process_template_pass",
            "Parameters" : {
                "outputType" : "contract",
                "outputFormat" : "",
                "outputConversion" : "",
                "outputFileName" : getCommandLineOptions().Output.FileName,
                "pass" : "generationcontract",
                "deploymentUnitSubset" : "generationcontract",
                "passAlternative" : ""
            }
        }
    ]

    [#assign entranceStatus = invokeEntrancePass(generationContractPass)]
    [#if entranceStatus == ENTRANCE_PASS_STATUS_FAILED ]
        [#assign exitResult = setExitStatus("110")]
    [/#if]

[#else]

    [#assign stageEntrancePasses = (getCommandLineOptions().Contract.Stage.Steps)?filter( x -> x.Type == "process_template_pass" && x.Status == "available" ) ]
    [#list stageEntrancePasses as stageEntrancePass ]
        [@addEntrancePass
            contractStep=stageEntrancePass
        /]
    [/#list]

[/#if]

[#list entrancePasses as entrancePass ]

    [#assign entranceStatus = invokeEntrancePass(entrancePass)]

    [#if entranceStatus == "failed" ]
        [#assign exitResult = setExitStatus("110")]
        [#break]
    [/#if]
[/#list]


[#-- ### Utility Functions #### --]
[#macro addEntrancePass contractStep ]
    [#if ! (entrancePasses?map(x -> x.Id )?seq_contains(contractStep.Id)) ]
        [#assign entrancePasses = combineEntities(entrancePasses, asArray(contractStep), APPEND_COMBINE_BEHAVIOUR) ]]
    [/#if]
[/#macro]

[#function invokeEntrancePass entrancePass ]

    [#-- set this globally to allow input seeding to access the pass during input refresh --]
    [#assign activePass = entrancePass]

    [#-- The entrance pass seeder uses the active pass to modify state --]
    [#-- we refresh it on each pass --]
    [@scheduleInputStateRefresh /]

    [#-- Write a general message about this entrance invoke --]
    [@writeStarterMessage
        writers=getCommandLineOptions().Logging.Writers
    /]

    [#-- Find and invoke the Entrance Macro --]
    [#-- Entrances provided by explicit providers are preferred over the shared provider --]
    [@invokeEntranceMacro
        type=entranceType
    /]

    [#-- Write generated logs out to loggers --]
    [@writeLogs
        writers=getCommandLineOptions().Logging.Writers
    /]

    [#-- Find the logs for any that match the stop level or above --]
    [#-- Set the exit code if they are found --]
    [#local status=ENTRANCE_PASS_STATUS_COMPLETED ]

    [#if logsAreFatal() ]
        [#local status=ENTRANCE_PASS_STATUS_FAILED ]
    [/#if]

    [#-- Clear outputs for next pass --]
    [@resetLogMessages /]
    [@clearOutputs /]

    [#return status ]
[/#function]

[#-- Seeds config based on the entrance pass  --]
[#function entrancepass_configseeder_commandlineoptions filter state]

    [#return
        addToConfigPipelineClass(
            state,
            COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS,
            {
                "Deployment" : {
                    "Output" : {
                        "Type" : (activePass.Parameters.outputType)!"",
                        "Format" : (activePass.Parameters.outputFormat)!"",
                        "Conversion" : (activePass.Parameters.outputConversion)!""
                    },
                    "Unit" : {
                        "Subset" : (activePass.Parameters.deploymentUnitSubset)!"",
                        "Alternative" : (activePass.Parameters.passAlternative)!""
                    }
                },
                "Output" : {
                    "Pass" : (activePass.Parameters.pass)!""
                } +
                attributeIfContent(
                    "FileName",
                    (activePass.Parameters.outputFileName)!""
                )
            }
        )
    ]

[/#function]
