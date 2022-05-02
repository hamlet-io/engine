[#ftl]

[#-----------------------------------------------
-- Public functions for district configuration --
-------------------------------------------------]

[#assign SELF_DISTRICT_TYPE = "self" ]

[#macro initialiseDistrictProcessing ]

    [#-- Stack of districts --]
    [#assign districtStack = initialiseStack() ]

[/#macro]

[#assign districtConfiguration = {} ]

[#-- Macros to assemble the district configuration --]
[#macro addDistrictType type configuration properties=[]  ]

    [#local config =
        {
            "Type" : type,
            "Properties" : asArray(properties),
            "Configuration" :
                getCompositeObject(
                    [
                        {
                            "Names" : "Layers",
                            "AttributeSet" : DISTRICT_ATTRIBUTESET_TYPE
                        }
                    ],
                    configuration
                )
        }
    ]

    [#-- Ensure the provided layers are configured --]
    [#list (config.Configuration.Layers.InstanceOrder)![] as layer]
        [#if ! isLayerConfigured(layer)]
            [@fatal
                message="Unknown layer in " + type + " district configuration"
                context=configuration
                detail=layer
            /]
        [/#if]
    [/#list]

    [#assign districtConfiguration =
        mergeObjects(
            districtConfiguration,
            {
                type : config
            }
        )
    ]
[/#macro]

[#-- Validate the district info in a link  --]
[#-- Either returns an empty object or the --]
[#-- validated and normalised district     --]
[#function getLinkDistrict link logErrors=true]
    [#-- Validate the district configuration --]
    [#return internalGetLinkDistrict(link, .caller_template_name, logErrors) ]
[/#function]

[#macro pushDistrict link district={} ]

    [#local stackEntry = district ]
    [#if ! district?has_content]
        [#local stackEntry = internalGetLinkDistrict(link, .caller_template_name) ]
    [/#if]

    [#-- Check if the district has changed --]
    [#if isStackEmpty(districtStack) || (!filterMatch(getTopOfStack(districtStack), stackEntry, EXACTLY_ONETOONE_FILTER_MATCH_BEHAVIOUR)) ]
        [#-- Update the input state with the new district --]
        [@pushInputFilter inputFilter=link /]
    [/#if]

    [#-- Remember the request for when we pop the stack --]
    [#assign districtStack = pushOnStack( districtStack, stackEntry ) ]

[/#macro]

[#-- Needs to be paired with pushDistrict --]
[#macro popDistrict]

    [#local previousDistrict = getTopOfStack(districtStack) ]

    [#-- Revert to previous district --]
    [#assign districtStack = popOffStack(districtStack) ]

    [#if !filterMatch(getTopOfStack(districtStack), previousDistrict, EXACTLY_ONETOONE_FILTER_MATCH_BEHAVIOUR) ]
        [#-- Restore previous input state --]
        [@popInputState /]
    [/#if]

[/#macro]

[#-- Get the ordering of layers for a district --]
[#function getDistrictLayerOrder district]
    [#return (districtConfiguration[district.DistrictType!""].Configuration.Layers.InstanceOrder)![] ]
[/#function]

[#-- Collect the name parts for the district --]
[#function getDistrictNameParts link short=false]

    [#-- First get the district instance --]
    [#local district = internalGetLinkDistrict(link, .caller_template_name) ]

    [#-- Now get the config for the district --]
    [#local config = (districtConfiguration[district.DistrictType!""].Configuration)!{} ]

    [#-- Determine the order of the name parts --]
    [#local partsOrder = (config.Layers.NamePartOrder)!(config.Layers.InstanceOrder)![] ]

    [#-- Determine the layer data to include in the name --]
    [#local activeLayers = getActiveLayers() ]

    [#-- Process the name parts - note that fixed parts don't have to correspond to a known layer --]
    [#local nameParts = [] ]
    [#list partsOrder as part]
        [#local partConfig = (config.Layers.NameParts[part])!{} ]
        [#if partConfig.Enabled!true]

            [#-- Fixed string --]
            [#if (partConfig.Fixed!"")?has_content]
                [#local nameParts += [partConfig.Fixed] ]
                [#continue]
            [/#if]

            [#-- Value based on layer --]
            [#local layer = activeLayers[part]!{} ]
            [#if layer?has_content]
                [#local namePart = short?then(layer.Id,layer.Name) ]
                [#-- Check for any values to be ignored (mainly to support legacy handling of "default") --]
                [#if ! asArray(partConfig.Ignore![])?seq_contains(namePart) ]
                    [#local nameParts += [ namePart ] ]
                [/#if]
            [/#if]
        [/#if]
    [/#list]

    [#return nameParts ]

[/#function]

[#function getDistrictFullNameParts link ]
    [#return getDistrictNameParts(link, false)]
[/#function]
[#function getDistrictShortNameParts link ]
    [#return getDistrictNameParts(link, true)]
[/#function]


[#------------------------------------------------------
-- Internal support functions for district processing --
--------------------------------------------------------]

[#-- Construct a district stack entry --]
[#function internalGetLinkDistrict link caller logErrors=true ]

    [#-- Handle "self" district --]
    [#if (link.DistrictType!"") == SELF_DISTRICT_TYPE]
        [#if isStackEmpty(districtStack) ]
            [#if logErrors]
                [@fatal
                    message='Attempt to use a district of "self" when no previous districts has been seen'
                /]
            [/#if]
            [#return {} ]
        [#else]
            [#return getTopOfStack(districtStack) ]
        [/#if]
    [/#if]

    [#local result = {} ]

    [#-- Get the expected layers --]
    [#local layers = (districtConfiguration[link.DistrictType!""].Configuration.Layers.InstanceOrder)![] ]
    [#if layers?has_content]
        [#list layers as layer]
            [#-- Check for input filter attributes --]
            [#list getLayerInputFilterAttributes(layer) as attribute]
                [#if link[attribute]?? ]
                    [#local result += { attribute : link[attribute] } ]
                [#else]
                    [#-- Something is missing --]
                    [#if logErrors]
                        [@fatal
                            message='"${attribute}" attribute is required by a district type of "${link.DistrictType}"'
                            context={
                                "Caller" : caller,
                                "Link": link
                            }
                        /]
                    [/#if]
                    [#local result = {} ]
                    [#break]
                [/#if]
            [/#list]
        [/#list]
    [#else]
        [#if logErrors]
            [@fatal
                message='Unknown or missing district type'
                context=link
            /]
        [/#if]
    [/#if]

    [#return
        valueIfContent(
            result + { "DistrictType" : link.DistrictType!"" },
            result
        )
    ]
[/#function]
