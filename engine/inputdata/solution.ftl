[#ftl]

[#function getSolution ]
    [#local result = {}]



    [#return {}]
[/#function]


[#-- Active tiers --]
[#function getTiers]
    [#local result = [] ]

    [#if isLayerActive(SEGMENT_LAYER_TYPE) ]
        [#local blueprintTiers = getBlueprint().Tiers!{} ]
        [#local segmentObject = getActiveLayer(SEGMENT_LAYER_TYPE) ]

        [#list segmentObject.Tiers.Order as tierId]
            [#local blueprintTier = (blueprintTiers[tierId])!{} ]
            [#if ! (blueprintTier?has_content) ]
                [#continue]
            [/#if]
            [#local tierNetwork =
                {
                    "Enabled" : false
                } ]

            [#if blueprintTier.Components?has_content || ((blueprintTier.Required)!false)]
                [#if (blueprintTier.Network.Enabled)!false ]
                    [#list segmentObject.Network.Tiers.Order![] as networkTier]
                        [#if networkTier == tierId]
                            [#local tierNetwork =
                                blueprintTier.Network +
                                {
                                    "Index" : networkTier?index,
                                    "Link" : addIdNameToObject(blueprintTier.Network.Link, "network")
                                } ]
                            [#break]
                        [/#if]
                    [/#list]
                [/#if]
                [#local result +=
                    [
                        addIdNameToObject(blueprintTier, tierId) +
                        { "Network" : tierNetwork }
                    ] ]
            [/#if]
        [/#list]
    [/#if]

    [#return result]
[/#function]
