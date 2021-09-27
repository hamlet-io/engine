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
[#macro addDistrict type layers properties=[]  ]
    [#local configuration =
        {
            "Type" : type,
            "Properties" : asArray(properties),
            "Layers" : asArray(layers)
        }
    ]

    [#-- Ensure the provided layers are configured --]
    [#list configuration.Layers as layer]
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
                type : configuration
            }
        )
    ]
[/#macro]

[#-- Validate the district info in a link  --]
[#-- Either returns an empty object or the --]
[#-- validated and normalised district     --]
[#function getLinkDistrict link logErrors=true]
    [#-- Validate the district configuration --]
    [#return internalGetLinkDistrict(link, logErrors) ]
[/#function]

[#macro pushDistrict link district={} ]

    [#local stackEntry = district ]
    [#if ! district?has_content]
        [#local stackEntry = internalGetLinkDistrict(link, logErrors) ]
    [/#if]

    [#-- Check if the district has changed --]
    [#if isStackEmpty(districtStack) || (!filterMatch(getTopOfStack(districtStack), link, EXACTLY_ONETOONE_FILTER_MATCH_BEHAVIOUR)) ]
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

[#------------------------------------------------------
-- Internal support functions for district processing --
--------------------------------------------------------]

[#-- Construct a district stack entry --]
[#function internalGetLinkDistrict link logErrors=true]

    [#-- Handle "self" district --]
    [#if (link.District!"") == SELF_DISTRICT_TYPE]
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
    [#local layers = (districtConfiguration[link.District!""].Layers)![] ]
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
                            message='"${attribute}" attribute is required by a district type of "${link.District}"'
                            context=link
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
            result + { "District" : link.District!"" },
            result
        )
    ]
[/#function]
