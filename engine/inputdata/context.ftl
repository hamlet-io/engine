[#ftl]

[#-----------------------------
-- Inputs context management --
-------------------------------]

[#-- Inputs context stack --]
[#assign inputsStack = initialiseStack() ]

[#-- Inputs state cache --]
[#assign inputsDictionary = initialiseDictionary() ]

[#-- The current inputs context and state --]
[#assign inputsContext = {} ]
[#assign inputsState = {} ]

[#-- Seed on the basis of the inputs context --]
[#macro seedInputsState]
    [#local keys = inputsContext?keys?sort]
    [#assign inputsState = getDictionaryEntry(inputsDictionary, keys)]
    [#if !inputsState?has_content]
        [#-- Calculate inputs state --]
        [#local inputs = {} ]
        [#list ["MasterData", "Blueprint", "References", "Settings", "StackOutputs", "Definitions"] as input]
            [#-- TODO(mfl): replace with loading of providers and seeding of inputs --]
            [#local inputs += {input : {} }]
        [/#list]
        [#assign inputsDictionary = addDictionaryEntry(inputsDictionary, keys, inputs) ]
    [/#if]
[/#macro]

[#-- Determine whether a "new" context will actually change the current one --]
[#function isNewInputsContext context={} ]
    [#list context as key,value]
        [#if !inputsContext[key]?? ]
            [#return true]
        [/#if]
        [#if inputsContext[key] != value]
            [#return true]
        [/#if]
    [/#list]

    [#return false]
[/#function]

[#macro pushInputsContext context={} ]
    [#-- Remember previous context --]
    [#assign inputsStack = pushOnStack(inputsStack, inputsContext) ]

    [#-- Update inputs context --]
    [#assign inputsContext += context ]

    [#-- Update inputs state --]
    [@seedInputsState /]
[/#macro]

[#function conditionalPushInputsContext context={} ]
    [#-- First ensure we need to create a new context --]
    [#if !isNewInputsContext(context) ]
        [#-- No change --]
        [#return inputsContext]
    [/#if]

    [#-- Create the new context --]
    [@pushInputsContext context /]

    [#-- New context created --]
    [#return inputsContext]
[/#function]

[#macro popInputsContext ]
    [#-- Restore previous context --]
    [#if isStackNotEmpty(inputsStack) ]
        [#assign inputsContext = getTopOfStack(inputsStack) ]
        [#assign inputsStack = popOffStack(inputsStack) ]
    [#else]
        [@fatal message="Attempt to pop empty inputs stack" /]
        [#assign inputsContext = {} ]
    [/#if]

    [#-- Update inputs state --]
    [@seedInputsState /]
[/#macro]

[#-- Only use if paired with conditionalPushInputsContext --]
[#macro conditionalPopInputsContext context ]
    [#if !isNewInputsContext(context)]
        [#return]
    [/#if]

    [#-- Restore previous context --]
    [#if isStackNotEmpty(inputsStack) ]
        [#assign inputsContext = getTopOfStack(inputsStack) ]
        [#assign inputsStack = popOffStack(inputsStack) ]
    [#else]
        [@fatal message="Attempt to pop empty inputs stack" /]
        [#assign inputsContext = {} ]
    [/#if]

    [#-- Update inputs state --]
    [@seedInputsState /]
[/#macro]

[#function getinputsContext]
    [#return inputsContext ]
[/#function]

[#-- Helper functions --]
[#function getTenantInputsContext]
    [#return inputsContext.Tenant!""]
[/#function]

[#function getAccountInputsContext]
    [#return inputsContext.Account!""]
[/#function]

[#function getRegionInputsContext]
    [#return inputsContext.Region!""]
[/#function]

[#function getProductInputsContext]
    [#return inputsContext.Product!""]
[/#function]

[#function getEnvironmentInputsContext]
    [#return inputsContext.Environment!""]
[/#function]

[#function getSegmentInputsContext]
    [#return inputsContext.Segment!""]
[/#function]

[#-----------------------------------------------------------
-- Internal support functions for input context processing --
-------------------------------------------------------------]
