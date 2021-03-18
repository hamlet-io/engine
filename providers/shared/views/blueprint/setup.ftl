[#ftl]

[#function getTenantBlueprint]
    [#local result=
        {
            "Metadata" : {
                "Prepared" : .now?iso_utc,
                "RequestReference" : getRequestReference(),
                "ConfigurationReference" : getConfigurationReference(),
                "RunId" : getRunId()
            },
            "Tenants" : [
                {
                    "Id" : tenantObject.Id,
                    "Name" : (tenantObject.Name)!tenantObject.Id,
                    "Configuration" : tenantObject,
                    "Domains" : domains,
                    "Products" : getProductBlueprint()
                }
            ]
        } +
        attributeIfContent("HamletMessages", logMessages)]
    [#return result]
[/#function]

[#function getProductBlueprint]
    [#local result= [
        {
            "Id" : productObject.Id,
            "Name" : (productObject.Name)!productObject.Id,
            "Configuration" : productObject,
            "Environments" : getEnvironmentBlueprint()
        }
    ]]
    [#return result ]
[/#function]

[#function getEnvironmentBlueprint]
    [#local result= [
        {
            "Id" : environmentObject.Id,
            "Name" : (environmentObject.Name)!environmentObject.Id,
            "Configuration" : environmentObject,
            "Segments" : getSegmentBlueprint()
        }
    ]]
    [#return result ]
[/#function]

[#function getSegmentBlueprint ]
    [#local result=[
        {
            "Id" : segmentObject.Id,
            "Name" : (segmentObject.Name)!segmentObject.Id,
            "Configuration" : segmentObject,
            "Account" : accountObject,
            "Solution" : solutionObject,
            "Tiers" : getTierBlueprint()
        }
    ]]
    [#return result ]
[/#function]

[#function getTierBlueprint ]
    [#local result=[] ]
    [#list tiers as tier]
        [#local result += [
            {
                "Id" : tier.Id,
                "Name" : (tier.Name)!tier.Id,
                "Configuration" : {
                "Id": tier.Id,
                "Name": (tier.Name)!"",
                "Title": (tier.Title)!"",
                "Description": (tier.Description)!"",
                "Network": tier.Network
                },
                "Components" :  getComponentBlueprint(tier)
            }]]
    [/#list]
    [#return result ]
[/#function]

[#function getComponentBlueprint tier]
    [#local result=[] ]
    [#list tier.Components!{} as id, value]
        [#local component =
            {
                "Id" : id,
                "Name" : (value.Name)!id
            } + value ]

        [#if component?is_hash]

        [#local componentType = getComponentType(component)]

        [#-- Only include deployed Occurrences --]
        [#local occurrences = getOccurrences(tier, component) ]

        [#local result += [
            component + {
            "Type" : componentType,
            "Occurrences" : occurrences
            } ] ]

        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#macro shared_view_default_blueprint_generationcontract  ]
    [@addDefaultGenerationContract subsets="config" /]
[/#macro]

[#macro shared_view_default_blueprint_config ]
    [@addToDefaultJsonOutput
        content=mergeObjects(getTenantBlueprint(), logMessages)
    /]
[/#macro]
