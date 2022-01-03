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

    [#local runBookInputs = {}]
    [#list getCompositeObject(runBookInputAttributes, getCommandLineOptions()["RunBookInputs"]) as k,v ]
        [#local runBookInputs = mergeObjects(runBookInputs, {k?ensure_starts_with("input:") : v })]
    [/#list]

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

        [#local taskParameters = {}]
        [#list mergeObjects(solution.Task.Parameters, _context.TaskParameters) as id, parameter ]
            [#local taskParameters = mergeObjects(
                taskParameters,
                { id : getRunBookValue(parameter, runBookInputs, subOccurrence, occurrence)}
            )]
        [/#list]

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
    [#if value?is_hash ]
        [#local value = value.Value]
    [/#if]

    [#if ( value?is_string && ! value?contains("__") ) || ! value?is_string ]
        [#return value ]
    [/#if]

    [#local substitutions = value?split("__")]
    [#local replacements = {}]

    [#list substitutions as substitution ]
        [#if substitution?matches('^([a-zA-Z0-9_-]*:){1,2}.*')]
            [#local lookups = substitution?split(":") ]
            [#local source = lookups[0] ]

            [#switch source?lower_case ]
                [#case "setting" ]
                    [#local settingName = lookups[1] ]

                    [#local collectedSettings = {}]
                    [#list (occurrence.Configuration.Settings)?values?filter(x -> x?has_content) as settingGroup ]
                        [#list settingGroup as key, value]
                            [#local collectedSettings = mergeObjects(collectedSettings, { key : value } )]
                        [/#list]
                    [/#list]
                    [#local replacements = mergeObjects(replacements, { "__${substitution}__" : (collectedSettings[settingName].Value)!"HamletFatal: substituion failed __${substitution}__" }) ]
                    [#break]


                [#case "attribute"]
                    [#local linkId = lookups[1] ]
                    [#local attributeName = lookups[2] ]

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

                    [#local replacements = mergeObjects(replacements, { "__${substitution}__" : (linkTarget.State.Attributes[attributeName])!"HamletFatal: substituion failed __${substitution}__" }) ]
                    [#break]

                [#case "input"]
                    [#if inputs?has_content]
                        [#local inputId = lookups[1] ]

                        [#if ! inputs?keys?seq_contains(inputId)?has_content ]
                            [@fatal
                                message="Input Id could not be found"
                                context={
                                    "Step" : occurrence.Core.Component.RawId,
                                    "Input" : inputId
                                }
                            /]
                        [/#if]
                        [#local replacements = mergeObjects(replacements, { "__${substitution}__" : "__Properties:${substitution}__" }) ]
                    [/#if]
                    [#break]

                [#case "output"]
                    [#if parentOccurrence?has_content ]
                        [#local stepId = lookups[1]]
                        [#local output = lookups[2]]

                        [#if ! ((parentOccurrence.Occurrences)![])?map( x -> x.Core.SubComponent.RawId)?seq_contains(stepId) ]
                            [@fatal
                                message="Step could not be found for output condition"
                                context={
                                    "Step" : occurrence.Core.Component.RawId,
                                    "Output" :{
                                        "StepId" : stepId,
                                        "Output" : output
                                    }
                                }
                            /]
                        [/#if]

                        [#local replacements = mergeObjects(replacements, { "__${substitution}__" : "__Properties:${substitution}__" }) ]
                    [/#if]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]

    [#list replacements as original, new ]
        [#local value = value?replace(original, new)]
    [/#list]

    [#return value]
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
                        "Details" : (taskConfig.Properties)!{},
                        "Attributes" : (taskConfig.Attributes)!{}
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
