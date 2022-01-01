[#ftl]
[#macro shared_runbook_default_runbook_generationcontract occurrence ]
    [@addDefaultGenerationContract
        subsets=[ "contract" ]
    /]
[/#macro]

[#macro shared_runbook_default_runbook occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#if getCommandLineOptions()["RunBook"] != core.TypedRawName ]
        [#return]
    [/#if]

    [#local runBookInputAttributes = []]
    [#list solution.Inputs as name, input ]
        [#local runBookInputAttributes = combineEntities(
            runBookInputAttributes,
            normaliseCompositeConfiguration(
                [ mergeObjects({ "Names" : name }, input) ]
            ),
            APPEND_COMBINE_BEHAVIOUR
        )]
    [/#list]

    [#local runBookInputs = getCompositeObject(runBookInputAttributes, getCommandLineOptions()["RunBookInputs"] )]

    [@contractProperties
        properties=runBookInputs
    /]

    [#list (occurrence.Occurrences)![] as subOccurrence ]

        [#local core = subOccurrence.Core ]
        [#local solution = subOccurrence.Configuration.Solution ]

        [#local stageId = core.SubComponent.RawName]

        [#local contextLinks = getLinkTargets(subOccurrence) ]
        [#local _context =
            {
                "DefaultEnvironment" : defaultEnvironment(subOccurrence, contextLinks),
                "Environment" : {},
                "Links" : contextLinks,
                "TaskParameters" : {}
            }
        ]
        [#local _context = invokeExtensions(subOccurrence, _context, {}, [], false, "runbook")]

        [@contractStage
            id=stageId
            executionMode=CONTRACT_EXECUTION_MODE_SERIAL
            priority=solution.Priority
            mandatory=true
        /]

        [#list solution.Conditions as id, condition]
            [@contractStep
                id=formatName("condition", core.SubComponent.RawId)
                stageId=stageId
                taskType=CONDITIONAL_STAGE_SKIP_TASK_TYPE
                parameters={
                    "Test" : condition.Test,
                    "Condition" : condition.Match,
                    "Value" : getRunBookValue(condition.Value, runBookInputs, subOccurrence, occurrence)
                }
                priority=10
                mandatory=true
                status="skip_stage_if_failure"
            /]
        [/#list]

        [#-- Add Task run Step --]
        [#local taskParameters = {}]
        [#list solution.Task.Parameters as id, parameter ]
            [#local taskParameters = mergeObjects(
                taskParameters,
                { id : getRunBookValue(parameter, runBookInputs, subOccurrence, occurrence)}
            )]
        [/#list]

        [#local taskParameters = mergeObjects(taskParameters, _context.TaskParameters )]

        [@contractStep
            id=core.SubComponent.RawId
            stageId=stageId
            taskType=solution.Task.Type
            parameters=taskParameters
            priority=100
            mandatory=true
            status="available"
        /]
    [/#list]
[/#macro]

[#-- Resolves the different inputs to contract values that engines can process --]
[#function getRunBookValue value inputs occurrence parentOccurrence ]
    [#local result = ""]
    [#switch value.Source ]
        [#case "Setting" ]
            [#local settingName = (value["source:Setting"].Name)!"" ]
            [#local collectedSettings = {}]

            [#list (occurrence.Configuration.Settings)?values?filter(x -> x?has_content) as settingGroup ]
                [#list settingGroup as key, value]
                    [#local collectedSettings = mergeObjects(collectedSettings, { key : value } )]
                [/#list]
            [/#list]
            [#local result = (collectedSettings[settingName].Value)!"" ]
            [#break]


        [#case "Attribute"]
            [#local linkId = (value["source:Attribute"].LinkId)!"" ]
            [#local attributeName = (value["source:Attribute"].Name)!"" ]

            [#local link = (occurrence.Configuration.Solution.Links[linkId])!{}]
            [#local linkTarget = getLinkTarget(occurrence, link)]

            [#if ! linkTarget?has_content ]
                [@fatal
                    message="Link could not be found for attribute"
                    context={
                        "Step"  : occurrence.Core.Component.RawId,
                        "LinkId" : linkId,
                        "Links" : occurrence.Configuration.Solution.Links
                    }
                /]
            [/#if]

            [#local result = (linkTarget.State.Attributes[attributeName?upper_case])!"" ]
            [#break]

        [#case "Input"]
            [#local inputId = (value["source:Input"].Id)!"" ]

            [#if ! inputs?keys?seq_contains(inputId)?has_content ]
                [@fatal
                    message="Input Id could not be found"
                    context={
                        "Step" : occurrence.Core.Component.RawId,
                        "Input" : inputId
                    }
                /]
            [/#if]
            [#local result = ":property:${inputId}" ]
            [#break]

        [#case "Output"]
            [#local stepId = (value["source:Output"].StepId)!""]
            [#local outputName = (value["source:Output"].Name)!"" ]

            [#if ! ((parentOccurrence.Occurrences)![])?map( x -> x.Core.SubComponent.RawId)?seq_contains(stepId) ]
                [@fatal
                    message="Step could not be found for output condition"
                    context={
                        "Step" : occurrence.Core.Component.RawId,
                        "Output" :{
                            "StepId" : stepId,
                            "Output" : outputName
                        }
                    }
                /]
            [/#if]

            [#local result = ":output:${stepId}:${outputName}" ]
            [#break]

        [#case "Fixed"]
            [#local result = (value["source:Fixed"].Value)!"" ]
            [#break]
    [/#switch]
    [#return result]
[/#function]

[#-- Provides information on the format of the runbook and what it does --]
[#macro shared_runbook_default_runbookinfo_generationcontract occurrence ]
    [@addDefaultGenerationContract
        subsets=[ "config" ]
    /]
[/#macro]


[#macro shared_runbook_default_runbookinfo occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#local runbookDetails = {
        "Name" : core.TypedRawName,
        "Description" : solution.Description,
        "Engine" : solution.Engine,
        "Inputs" : solution.Inputs
    }]

    [#local runBookSteps = []]

    [#list (occurrence.Occurrences)![] as subOccurrence ]

        [#if subOccurrence.Core.Type != RUNBOOK_STEP_COMPONENT_TYPE ]
            [#continue]
        [/#if]

        [#local core = subOccurrence.Core ]
        [#local solution = subOccurrence.Configuration.Solution ]

        [#local taskConfig = getTaskConfig(solution.Task.Type)]

        [#local runBookSteps = combineEntities(
            runBookSteps,
            [
                {
                    "Name" : core.SubComponent.RawName,
                    "Priority" : solution.Priority,
                    "Conditions" : solution.Conditions,
                    "Parameters" : solution.Task.Parameters,
                    "Links" : solution.Links,
                    "Task" : {
                        "Type" : solution.Task.Type,
                        "Details" : taskConfig.Properties,
                        "Attributes" : taskConfig.Attributes
                    }
                }
            ],
            APPEND_COMBINE_BEHAVIOUR
        )]
    [/#list]

    [#local runbookDetails = mergeObjects(runbookDetails, { "Steps" : runBookSteps?sort_by("Priority")})]

    [@addToDefaultJsonOutput
        content={
            "RunBooks" :
                combineEntities(
                    (getOutputContent(JSON_DEFAULT_OUTPUT_TYPE)["RunBooks"])![]
                    runbookDetails,
                    APPEND_COMBINE_BEHAVIOUR
                )
        }
    /]
[/#macro]
