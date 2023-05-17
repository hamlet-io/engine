[#ftl]

[#-- Generate effective list from value sets --]
[#function getWAFValueList valueSetEntries=[] valueSet={} ]
    [#local result = [] ]
    [#list asArray(valueSetEntries) as valueSetEntry]
        [#if valueSetEntry?is_string && valueSet[valueSetEntry]??]
            [#local result += asArray(valueSet[valueSetEntry]) ]
        [#else]
            [#local result += [valueSetEntry] ]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#-- Generic processing for fields to match --]
[#function formatWAFFieldToMatch field ]
    [#local result = [] ]
    [#return
        {
            "FieldToMatch" : {
                "Type" : field.Type?upper_case
            } +
            attributeIfTrue(
                "Data",
                ["HEADER", "SINGLE_QUERY_ARG"]?seq_contains(field.Type?upper_case),
                field.Data!""
            )
        } ]
    [#return result]
[/#function]
