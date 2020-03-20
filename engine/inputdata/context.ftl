[#ftl]

[#-----------------------------
-- Inputs context management --
-------------------------------]

[#assign PLACEMENT_INPUTS_CONTEXT = "placement"]
[#assign PRODUCT_INPUTS_CONTEXT = "product"]

[#macro initialiseInputsContext ]
    [#-- Inputs context stacks --]
    [#assign inputsPlacementStack = initialiseStack() ]
    [#assign inputsProductStack = initialiseStack() ]

    [#-- Inputs state caches --]
    [#assign inputsPlacementDictionary = initialiseDictionary() ]
    [#assign inputsProductDictionary = initialiseDictionary() ]

    [#-- The current inputs contexts --]
    [#assign inputsPlacementContext = {} ]
    [#assign inputsProductContext = {} ]

    [#-- The current inputs state --]
    [#assign inputsPlacementState = {} ]
    [#assign inputsProductState = {} ]

    [#-- Effective State --]
    [#assign inputsDictionary = initialiseDictionary() ]
    [#assign inputsState = {} ]
[/#macro]

[#macro pushInputsPlacementContext context={} ]
    [@internalPushInputsContext PLACEMENT_INPUTS_CONTEXT context /]
[/#macro]

[#macro pushInputsProductContext context={} ]
    [@internalPushInputsContext PRODUCT_INPUTS_CONTEXT context /]
[/#macro]

[#macro conditionalPushInputsPlacementContext context={} ]
    [@internalConditionalPushInputsContext PLACEMENT_INPUTS_CONTEXT context /]
[/#macro]

[#macro conditionalPushInputsProductContext context={} ]
    [@internalConditionalPushInputsContext PRODUCT_INPUTS_CONTEXT context /]
[/#macro]

[#macro popInputsPlacementContext context={} ]
    [@internalPopInputsContext PLACEMENT_INPUTS_CONTEXT context /]
[/#macro]

[#macro popInputsProductContext context={} ]
    [@internalPopInputsContext PRODUCT_INPUTS_CONTEXT context /]
[/#macro]

[#macro conditionalPopInputsPlacementContext context={} ]
    [@internalConditionalPopInputsContext PLACEMENT_INPUTS_CONTEXT context /]
[/#macro]

[#macro conditionalPopInputsProductContext context={} ]
    [@internalConditionalPopInputsContext PRODUCT_INPUTS_CONTEXT context /]
[/#macro]

[#-- Product helper functions --]
[#function getTenantInputsContext]
    [#return inputsProductContext.Tenant!""]
[/#function]

[#function getProductInputsContext]
    [#return inputsProductContext.Product!""]
[/#function]

[#function getEnvironmentInputsContext]
    [#return inputsProductContext.Environment!""]
[/#function]

[#function getSegmentInputsContext]
    [#return inputsProductContext.Segment!""]
[/#function]

[#-- Placement helper functions --]
[#function getAccountInputsContext]
    [#return inputsPlacementContext.Account!""]
[/#function]

[#function getRegionInputsContext]
    [#return inputsPlacementContext.Region!""]
[/#function]

[#-----------------------------------------------------------
-- Internal support functions for input context processing --
-------------------------------------------------------------]

[#-- Determine the inputs --]
[#function internalGetInputsState inputTypes]
    [#local state = {} ]
    [#list asArray(inputTypes) as inputType]
        [#-- TODO(mfl): replace with loading of providers and seeding of inputs --]
        [#local state += {inputType : {} }]
    [/#list]
    [#return state]
[/#function]

[#-- Get the combined state of placement and product   --]
[#-- Qualify the results based on the current contexts --]
[#function internalGetEffectiveState]
    [#local state = {} ]
    [#local keys = getUniqueArrayElements(inputsPlacementState?keys, inputsProductState?keys)]
    [#list keys as key]
        [#-- Determine the expected base type --]
        [#switch getBaseType(inputsPlacementState[key]!inputsProductState[key])]
            [#case ARRAY_TYPE]
                [#local missingValue = [] ]
                [#break]
            [#default]
                [#local missingValue = {} ]
                [#break]
        [/#switch]
        [#local state +=
            {
                key :
                    combineEntities(
                        inputsPlacementState[key]!missingValue,
                        inputsProductState[key]!missingValue,
                        APPEND_COMBINE_BEHAVIOUR
                    )
            }
        ]
    [/#list]

    [#-- TODO(mfl): Add qualification --]

    [#return state]
[/#function]

[#-- Seed on the basis of the inputs context --]
[#macro internalSeedInputsState type ]

    [#-- First determine the dictionary index --]
    [#switch type]
        [#case PLACEMENT_INPUTS_CONTEXT]
            [#local context = inputsPlacementContext]
            [#break]
        [#default]
            [#local context = inputsProductContext]
            [#break]
    [/#switch]
    [#local dictionaryIndex = [] ]
    [#list context?keys?sort as key]
        [#local dictionaryIndex += [ context[key] ] ]
    [/#list]

    [#-- Check for an already calculated state --]
    [#switch type]
        [#case PLACEMENT_INPUTS_CONTEXT]
            [#assign inputsPlacementState = getDictionaryEntry(inputsPlacementDictionary, dictionaryIndex)]
            [#local state = inputsPlacementState]
            [#break]
        [#default]
            [#assign inputsProductState = getDictionaryEntry(inputsProductDictionary, dictionaryIndex)]
            [#local state = inputsProductState]
            [#break]
    [/#switch]

    [#if !state?has_content]
        [#-- Calculate inputs state --]
        [#switch type]
            [#case PLACEMENT_INPUTS_CONTEXT]
                [#assign inputsPlacementState =
                    internalGetInputsState(
                        [
                            "MasterData",
                            "Blueprint",
                            "References",
                            "Settings",
                            "StackOutputs"
                        ]
                    )
                ]
                [#assign inputsPlacementDictionary = addDictionaryEntry(inputsPlacementDictionary, dictionaryIndex, inputsPlacementState) ]
                [#break]
        [#default]
                [#assign inputsProductState =
                    internalGetInputsState(
                        [
                            "Blueprint",
                            "References",
                            "Settings",
                            "StackOutputs",
                            "Definitions"
                        ]
                    )
                ]
                [#assign inputsProductDictionary = addDictionaryEntry(inputsProductDictionary, dictionaryIndex, inputsProductState) ]
                [#break]
        [/#switch]
    [/#if]

    [#-- Calculate the effective state --]
    [#local dictionaryIndex = getUniqueArrayElements(inputsPlacementContext?keys, inputsProductContext?keys)?sort]
    [#assign inputsState = getDictionaryEntry(inputsDictionary, dictionaryIndex) ]
    [#if !inputsState?has_content]
        [#assign inputsState = internalGetEffectiveState() ]
        [#assign inputsDictionary = addDictionaryEntry(inputsDictionary, dictionaryIndex, inputsState) ]
    [/#if]
[/#macro]

[#-- Determine whether a "new" context will actually change the current one --]
[#function internalIsNewInputsContext type context ]
    [#switch type]
        [#case PLACEMENT_INPUTS_CONTEXT]
            [#local currentContext = inputsPlacementContext]
            [#break]
        [#default]
            [#local currentContext = inputsProductContext]
            [#break]
    [/#switch]

    [#list context as key,value]
        [#if !currentContext[key]??]
            [#return true]
        [/#if]
        [#if currentContext[key] != value]
            [#return true]
        [/#if]
    [/#list]

    [#return false]
[/#function]

[#macro internalPushInputsContext type context ]
    [#switch type]
        [#case PLACEMENT_INPUTS_CONTEXT]
            [#-- Remember previous context --]
            [#assign inputsPlacementStack = pushOnStack(inputsPlacementStack, context) ]

            [#-- Update inputs context --]
            [#assign inputsPlacementContext += context ]
            [#break]
        [#default]
            [#-- Remember previous context --]
            [#assign inputsProductStack = pushOnStack(inputsProductStack, context) ]

            [#-- Update inputs context --]
            [#assign inputsProductContext += context ]
            [#break]
        [/#switch]

    [#-- Update inputs state --]
    [@internalSeedInputsState type /]
[/#macro]

[#macro internalConditionalPushInputsContext type context={} ]
    [#-- First ensure we need to create a new context --]
    [#if !internalIsNewInputsContext(type, context) ]
        [#-- No change --]
        [#return]
    [/#if]

    [#-- Create the new context --]
    [@internalPushInputsContext type context /]
[/#macro]

[#macro internalPopInputsContext type]
    [#switch type]
        [#case PLACEMENT_INPUTS_CONTEXT]
            [#-- Restore previous context --]
            [#assign inputsPlacementContext = getTopOfStack(inputsPlacementStack) ]
            [#assign inputsPlacementStack = popOffStack(inputsPlacementStack) ]
            [#break]
        [#default]
            [#-- Restore previous context --]
            [#assign inputsProductContext = getTopOfStack(inputsProductStack) ]
            [#assign inputsProductStack = popOffStack(inputsProductStack) ]
            [#break]
    [/#switch]

    [#-- Update inputs state --]
    [@internalSeedInputsState type /]
[/#macro]

[#-- Only use if paired with internalConditionalPushInputsContext --]
[#macro internalConditionalPopInputsContext type context ]
    [#if !internalIsNewInputsContext(type, context)]
        [#return]
    [/#if]

    [#-- Need to pop the stack --]
    [@internalPopInputsContext type /]
[/#macro]

