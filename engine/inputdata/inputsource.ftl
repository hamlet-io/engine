[#ftl]

[#--
An input source provides state to the engine. It relies on one
or more stages to provide content. Stages are dynamically ordered
based on priority so it is possible to insert new stages into
the existing order.

One stage can be added to multiple input sources.

The command line option stage is always the first stage of any
input source.
--]
[#assign inputSources = {} ]

[#macro addInputSource id description]
    [#assign inputSources =
        mergeObjects(
            inputSources,
            {
                id : {
                    "Description" : description,
                    "Stages" : [
                        {
                            "Id" : COMMANDLINEOPTIONS_SHARED_INPUT_STAGE,
                            "Priority" : 0
                        }
                    ]
                }
            }
        )
    ]
[/#macro]

[#assign inputStages = {} ]

[#macro addInputStage id description]
    [#assign inputStages =
        mergeObjects(
            inputStages,
            {
                id : {
                    "Description" : description
                }
            }
        )
    ]
[/#macro]

[#assign DEFAULT_INPUT_PRIORITY_INCREMENT = 100]
[#macro addStageToInputSource inputSource inputStage priority="" ]
    [#if inputSources[inputSource]?? && inputStages[inputStage]??]

        [#local lastStage = inputSources[inputSource].Stages?sort_by("Priority")?last ]

        [#assign inputSources =
            combineEntities(
                inputSources,
                {
                    inputSource : {
                        "Stages" : [
                            {
                                "Id" : inputStage,
                                "Priority" :
                                    valueIfTrue(
                                        priority,
                                        priority?is_number,
                                        lastStage.Priority + DEFAULT_INPUT_PRIORITY_INCREMENT
                                    )
                            }
                        ]
                    }
                },
                APPEND_COMBINE_BEHAVIOUR
            )]
    [/#if]
[/#macro]

[#-- Assign implicit stage priorities --]
[#macro addStagesToInputSource inputSource inputStages=[] ]
    [#list asArray(inputStages) as inputStage ]
        [@addStageToInputSource
            inputSource=inputSource
            inputStage= inputStage
        /]
    [/#list]
[/#macro]

[#-- Always process command line options first --]
[#function getInputStages inputSource]
    [#return
        ((inputSources[inputSource].Stages)![])?sort_by("Priority")
    ]
[/#function]

[#--
Input seeders provide content to stages. Like stages in an input source,
seeders within an input stage are dynamically ordered so additional
seeders can be dynamically added to an existing input stage.
--]
[#assign inputSeeders = {} ]

[#macro addInputSeeder id description]

    [#assign inputSeeders =
        mergeObjects(
            inputSeeders,
            {
                id : {
                    "Description" : description
                }
            }
        )
    ]
[/#macro]

[#--
Seeders can control whether they apply to any input source or specific input sources, and
their order relative to other seeders.

In general a seeder should not control the priority so that provider loading order
controls the ordering of the seeders but the flexibility is there should a use case emerge.
--]

[#macro addSeederToInputStage inputStage inputSeeder priority="" inputSources="*" ]
    [#if inputSeeders[inputSeeder]??]
        [#local lastSeeder = (inputStages[inputStage].Seeders?sort_by("Priority")?last)!{"Priority" : 0} ]
        [#assign inputStages =
            combineEntities(
                inputStages,
                {
                    inputStage : {
                        "Seeders" : [
                            {
                                "Id" : inputSeeder,
                                "Priority" :
                                    valueIfTrue(
                                        priority,
                                        priority?is_number,
                                        lastSeeder.Priority + DEFAULT_INPUT_PRIORITY_INCREMENT
                                    ),
                                "Sources" : asArray(inputSources)
                            }
                        ]
                    }
                },
                APPEND_COMBINE_BEHAVIOUR
            )
        ]
    [/#if]
[/#macro]

[#function getInputSeeders inputStage]
    [#return
        ((inputStages[inputStage].Seeders)![])?sort_by("Priority")
    ]
[/#function]

[#--
Set the current input source
--]
[#assign currentInputSource ="" ]
[#macro setInputSource inputSource]
    [#assign currentInputSource = inputSource ]
[/#macro]

[#--
Set the current input filter
--]
[#assign currentInputFilter = {} ]
[#macro setInputFilter inputFilter]
    [#assign currentInputFilter = inputFilter ]
[/#macro]

[#--
Get the state for the current input source and filter
--]
[#function getInputState inputSource="" inputFilter="" ]
    [#local state = {} ]

    [#-- Default to the current input source and filter - overrides mainly for testing --]
    [#local activeInputSource = contentIfContent(inputSource, currentInputSource) ]
    [#local activeInputFilter = contentIfContent(inputFilter, currentInputFilter) ]

    [#-- Get the ordered list of stages to invoke --]
    [#list getInputStages(activeInputSource) as inputStage]
        [#-- Get the ordered list of seeders to invoke --]
        [#list getInputSeeders(inputStage.Id) as inputSeeder]
            [#-- Ensure seeder is registered for the input source --]
            [#if inputSeeder.Sources?seq_contains(activeInputSource) || inputSeeder.Sources?seq_contains("*")]

                [#-- Support various level of seeder specificity --]
                [#local seederFunctionOptions =
                    [
                        [ inputSeeder.Id, "input", inputStage.Id, activeInputSource, "seeder" ],
                        [ inputSeeder.Id, "input", inputStage.Id, "seeder" ],
                        [ inputSeeder.Id, "input", "seeder" ]
                    ]
                ]

                [#local seederFunction = getFirstDefinedDirective(seederFunctionOptions)]

                [#if (.vars[seederFunction]!"")?is_directive]
                    [#local state = (.vars[seederFunction])(activeInputFilter, state) ]
                [#else]
                    [@debug
                        message="Unable to invoke any of the input seeder function options"
                        context=seederFunctionOptions
                        enabled=false
                    /]
                [/#if]
            [/#if]
        [/#list]
    [/#list]

    [#return state]
[/#function]

