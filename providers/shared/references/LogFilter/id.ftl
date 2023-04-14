[#ftl]

[@addReference
    type=LOGFILTER_REFERENCE_TYPE
    pluralType="LogFilters"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A filter to apply when searching log files"
            }
        ]
    attributes=[
        {
            "Names" : "Pattern",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

[#function getLogFilterPattern logFilterId ]
    [#return (getReferenceData(LOGFILTER_REFERENCE_TYPE)[logFilterId].Pattern)!"" ]
[/#function]
