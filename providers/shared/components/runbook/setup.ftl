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

    [#local dynamicInputs =  {
            "inputs": runBookInputs,
            "stepIds": (occurrence.Occurrences![])?filter(
                x -> x.Configuration.Solution.Enabled && x.Core.Type == RUNBOOK_STEP_COMPONENT_TYPE
            )?map(x -> x.Core.SubComponent.RawId ),
            "occurrence" : occurrence
        }]

    [@contractProperties
        properties=runBookInputs
    /]

    [#list (occurrence.Occurrences![])?filter(
                x -> x.Configuration.Solution.Enabled )?map(
                    x -> resolveDynamicValues(x, dynamicInputs)) as subOccurrence]

        [#local core = subOccurrence.Core ]
        [#local solution = subOccurrence.Configuration.Solution ]

        [#local stageId = core.SubComponent.RawName]

        [#local contextLinks = getLinkTargets(subOccurrence) ]
        [#local _context =
            {
                "DefaultEnvironment" : defaultEnvironment(subOccurrence, contextLinks),
                "Environment" : {},
                "Links" : contextLinks,
                "TaskParameters" : solution.Task.Parameters,
                "Conditions" : solution.Conditions,
                "Inputs": runBookInputs
            }
        ]
        [#local _context = invokeExtensions(subOccurrence, _context, {}, [], false, "runbook")]

        [@contractStage
            id=stageId
            executionMode=CONTRACT_EXECUTION_MODE_SERIAL
            priority=solution.Priority
            mandatory=true
        /]

        [#list _context.Conditions as id, condition]
            [@contractStep
                id=formatName("condition", core.SubComponent.RawId, id)
                stageId=stageId
                taskType=CONDITIONAL_STAGE_SKIP_TASK_TYPE
                parameters=
                    resolveDynamicValues(
                        {
                            "Test" : (condition.Test)!"",
                            "Condition" : condition.Match,
                            "Value" : condition.Value
                        },
                        runBookInputs
                    )
                priority=10
                mandatory=true
                status="skip_stage_if_failure"
            /]
        [/#list]

        [#local taskParameters = {}]
        [#list _context.TaskParameters as id, parameter ]
            [#local taskParameters = mergeObjects(
                taskParameters,
                { id : parameter?is_hash?then(parameter.Value, parameter) }
            )]
        [/#list]

        [@contractStep
            id=core.SubComponent.RawId
            stageId=stageId
            taskType=solution.Task.Type
            parameters=resolveDynamicValues(taskParameters, dynamicInputs)
            priority=100
            mandatory=true
            status="available"
        /]
    [/#list]
[/#macro]

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

    [#list (occurrence.Occurrences![])?filter(x -> x.Configuration.Solution.Enabled ) as subOccurrence]

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
