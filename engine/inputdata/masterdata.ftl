[#ftl]

[#-- Master data --]
[#-- This is temporary until we can natively load the data as a json file --]
[#assign masterData = {} ]
[#assign masterDataCache = {} ]

[#macro addMasterData provider data={} ]
    [#assign masterData +=
        {
            provider : data
        } ]
[/#macro]

[#function getMasterData provider]
    [#local index = provider]
    [#if masterDataCache[index]??]
        [#return masterDataCache[index]]
    [/#if]
    [#local data =
        mergeObjects(
            masterData[SHARED_PROVIDER]!{},
            masterData[provider]!{}) ]
    [#assign masterDataCache +=
        {
            index : data
        } ]
    [#return data]
[/#function]
