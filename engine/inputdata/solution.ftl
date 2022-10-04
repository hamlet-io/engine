[#ftl]

[#---------------------------------------------
-- Public functions for Solution processing --
-----------------------------------------------]
[#assign solutionData = {}]

[#macro includeSolutionData blueprint ]
    [#local configuration = getSolutionConfiguration()]
    [#local result = {}]

    [#-- Get the blueprint base Tiers object to include as a Segment solution --]
    [#if isLayerActive(SEGMENT_LAYER_TYPE)]

        [#local segmentObject = getActiveLayer(SEGMENT_LAYER_TYPE) ]

        [#local tiers = {}]
        [#list (blueprint.Tiers)!{} as id, tier ]

            [#-- Need to handle the different possibilities of the index --]
            [#local index = 40 - tier?index]
            [#if (segmentObject.Network.Tiers.Order![])?seq_contains(id)]
                [#local index = (segmentObject.Network.Tiers.Order![])?seq_index_of(id)]
            [#elseif (segmentObject.Tiers.Order![])?seq_contains(id) ]
                [#local index = 30 - (segmentObject.Tiers.Order![])?seq_index_of(id)]
            [/#if]

            [#local indexedTier = mergeObjects(
                {
                    "Index": index
                },
                tier
            )]
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
        [#local result = mergeObjects(result, { "_baseSegmentTiers" : getCompositeObject(configuration, baseSegmentSolutionData)})]
    [/#if]

    [#list (blueprint.Solutions)!{} as id, solution]
        [#local result = mergeObjects(result, { id: solution})]
    [/#list]

    [#list result as id, solution]
        [#local tierIndexes = ((solution.Tiers)!{})?values?map(x -> x.Index) ]
        [#list tierIndexes as i ]
            [#if tierIndexes?seq_index_of(i) != tierIndexes?seq_last_index_of(i) ]
                [@fatal
                    message="Duplicate tier index found"
                    detail="All tiers must have a unique index to ensure network placement"
                    context={
                        "Solution" : id,
                        "Tiers" : ((solution.Tiers)!{})?values?filter(x -> x.Index == i )?map(x -> { "Id": x.Id, "Name": x.Name, "Index": x.Index}),
                        "TierIndexes" : tierIndexes
                    }
                /]
            [/#if]
        [/#list]
    [/#list]

    [#assign solutionData = getCompositeObject(mergeObjects(solutionData, result))]
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

    [#local solutionTiers = ((getActiveSolution().Tiers)!{})?values ]
    [#list (getActiveSolution().Tiers)!{} as id, tier ]
        [#if tier.Components?has_content]
            [#local result = combineEntities(
                result,
                [
                    mergeObjects(
                        addIdNameToObject(tier, id),
                        {
                            "Active" : true
                        }
                    )
                ],
                APPEND_COMBINE_BEHAVIOUR
            )]
        [/#if]
    [/#list]

    [#return result]
[/#function]
