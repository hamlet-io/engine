[#ftl]

[#---------------------------------------------
-- Public functions for Solution processing --
-----------------------------------------------]
[#assign solutionData = {}]

[#macro includeSolutionData blueprint ]
    [#local configuration = getSolutionConfiguration()]

    [#-- Get the blueprint base Tiers object to include as a Segment solution --]
    [#if isLayerActive(SEGMENT_LAYER_TYPE)]

        [#local segmentObject = getActiveLayer(SEGMENT_LAYER_TYPE) ]

        [#local tiers = {}]
        [#list (blueprint.Tiers)!{} as id, tier ]
            [#local indexedTier = mergeObjects(tier, { "Index": (segmentObject.Network.Tiers.Order![])?seq_index_of(id) })]
            [#local tiers = mergeObjects( tiers, { id : indexedTier })]
        [/#list]

        [#local baseSegmentSolutionData = {
            "Priority" : 900,
            "District" : {
                "Type" : "segment",
                "Layers" : {
                    "all_segments" : {
                        "Type" : SEGMENT_LAYER_TYPE,
                        "Id" : "*"
                    }
                }
            },
            "Tiers" : tiers
        }]
        [#assign solutionData = mergeObjects(solutionData, { "_baseSegmentTiers" : getCompositeObject(configuration, baseSegmentSolutionData)})]
    [/#if]

    [#list (blueprint.Solutions)!{} as id, solution]
        [#assign solutionData = mergeObjects(solutionData, { id: getCompositeObject(configuration, solution)})]
    [/#list]
[/#macro]

[#function getSolutions ]
    [#return solutionData]
[/#function]

[#function getActiveSolution ]
    [#local result = {}]

    [#local activeLayers = getActiveLayers()]

    [#list getSolutions()?values?filter(
            x-> x.District.Type == getCommandLineOptions()["Input"]["Filter"]["DistrictType"]
        )?sort_by("Priority")?reverse as solution ]

        [#list (solution.District.Layers)?values as layerFilter ]
            [#if activeLayers[layerFilter.Type]?? && ( layerFilter.Id == "*" || layerFilter.Id == activeLayers[layerFilter.Type].Id ) ]
                [#local result = mergeObjects(result, solution)]
            [/#if]
        [/#list]
    [/#list]

    [#return result]
[/#function]

[#-- Active tiers --]
[#function getTiers]
    [#local result = [] ]

    [#local solutionTiers = ((getActiveSolution().Tiers)!{})?values?filter(x -> (x.Index)?is_number && x.Index > 0) ]
    [#local tierIndexes = solutionTiers?map(x -> x.Index) ]
    [#list tierIndexes as i ]
        [#if tierIndexes?seq_index_of(i) != tierIndexes?seq_last_index_of(i) ]
            [@fatal
                message="Duplicate tier index found"
                detail="All tiers must have a unique index to ensure network placement"
                context={
                    "Tiers" : solutionTiers?values,
                    "TierIndexes" : tierIndexes
                }
            /]
        [/#if]
    [/#list]

    [#list solutionTiers?sort_by("Index") as tier ]
        [#if tier.Components?has_content]
            [#local result = combineEntities(
                result,
                [
                    mergeObjects(
                        tier,
                        {
                            "Active" : true
                        }
                    )
                ]
            )]
        [/#if]
    [/#list]

    [#return result]
[/#function]
