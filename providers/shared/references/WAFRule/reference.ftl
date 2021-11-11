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

[#function formatWAFByteMatchTuples filter={} valueSet={} ]
    [#local result = [] ]
    [#list getWAFValueList(filter.FieldsToMatch, valueSet) as field]
        [#list getWAFValueList(filter.Targets, valueSet) as target]
            [#list getWAFValueList(filter.Constraints, valueSet) as constraint]
                [#list getWAFValueList(filter.Transformations, valueSet) as transformation]
                    [#local result += [
                            formatWAFFieldToMatch(field) +
                            {
                                "TargetString" : target,
                                "PositionalConstraint" : constraint?upper_case,
                                "TextTransformation" : transformation?upper_case
                            }
                        ] ]
                [/#list]
            [/#list]
        [/#list]
    [/#list]
    [#return result]
[/#function]

[#-- TODO(mfl) Make this work for IPv6 as well --]
[#-- For now always assume IPv4                --]
[#function formatWAFIPMatchTuples filter={} valueSet={} version="V1" ]
    [#local result= [] ]
    [#list getWAFValueList(filter.Targets, valueSet) as target]
        [#switch version]
            [#case "V1"]
                [#local result += [
                        {
                            "Type" : "IPV4",
                            "Value" : target
                        }
                    ]
                ]
            [#break]
            [#case "V2"]
                [#local result += [ target ] ]
            [#break]
        [/#switch]
    [/#list]
    [#return result]
[/#function]

[#function formatWAFGeoMatchTuples filter={} valueSet={} ]
    [#local result= [] ]
    [#list getWAFValueList(filter.Targets, valueSet) as target]
        [#local result += [
                {
                    "Type" : "Country",
                    "Value" : target
                }
            ]
        ]
    [/#list]
    [#return result]
[/#function]

[#function formatWAFSizeConstraintTuples filter={} valueSet={} ]
    [#local result = [] ]
    [#list getWAFValueList(filter.FieldsToMatch, valueSet) as field]
        [#list getWAFValueList(filter.Operators, valueSet) as operator]
            [#list getWAFValueList(filter.Sizes, valueSet) as size]
                [#list getWAFValueList(filter.Transformations, valueSet) as transformation]
                    [#local result += [
                            formatWAFFieldToMatch(field) +
                            {
                                "ComparisonOperator" : operator?upper_case,
                                "Size" : size?c,
                                "TextTransformation" : transformation?upper_case
                            }
                        ] ]
                [/#list]
            [/#list]
        [/#list]
    [/#list]
    [#return result]
[/#function]

[#function formatWAFSqlInjectionMatchTuples filter={} valueSet={} ]
    [#local result = [] ]
    [#list getWAFValueList(filter.FieldsToMatch, valueSet) as field]
        [#list getWAFValueList(filter.Transformations, valueSet) as transformation]
            [#local result += [
                    formatWAFFieldToMatch(field) +
                    {
                        "TextTransformation" : transformation?upper_case
                    }
                ] ]
        [/#list]
    [/#list]
    [#return result]
[/#function]

[#function formatWAFXssMatchTuples filter={} valueSet={} ]
    [#local result = [] ]
    [#list getWAFValueList(filter.FieldsToMatch, valueSet) as field]
        [#list getWAFValueList(filter.Transformations, valueSet) as transformation]
            [#local result += [
                    formatWAFFieldToMatch(field) +
                    {
                        "TextTransformation" : transformation?upper_case
                    }
                ] ]
        [/#list]
    [/#list]
    [#return result]
[/#function]