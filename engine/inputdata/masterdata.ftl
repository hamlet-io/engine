[#ftl]

[#-- Master data --]
[#-- This is temporary until we can natively load the data as a json file --]
[#assign masterData = {} ]

[#macro addMasterData data={} ]
    [#assign masterData = mergeObjects(masterData, data )]
[/#macro]

[#function getMasterData ]
    [#return masterData ]
[/#function]
