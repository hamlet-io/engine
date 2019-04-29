[#-- Web Application Firewall --]

[#-- Regional resource types replicate global ones --]
[#function formatWAFResourceType baseResourceType regional ]
    [#return "AWS::" + regional?then("WAFRegional::","WAF::") + baseResourceType ]
[/#function]

[#-- Condition types --]
[#assign AWS_WAF_BYTE_MATCH_CONDITION_TYPE = "ByteMatch" ]
[#assign AWS_WAF_GEO_MATCH_CONDITION_TYPE = "GeoMatch" ]
[#assign AWS_WAF_IP_MATCH_CONDITION_TYPE = "IPMatch" ]
[#assign AWS_WAF_REGEX_MATCH_CONDITION_TYPE = "RegexMatch" ]
[#assign AWS_WAF_SIZE_CONSTRAINT_CONDITION_TYPE = "SizeConstraint" ]
[#assign AWS_WAF_SQL_INJECTION_MATCH_CONDITION_TYPE = "SqlInjectionMatch" ]
[#assign AWS_WAF_XSS_MATCH_CONDITION_TYPE = "XssMatch" ]

[#-- Capture the variability between the various conditions --]
[#assign WAFConditions = {
    AWS_WAF_BYTE_MATCH_CONDITION_TYPE : {
        "ResourceType" : "ByteMatchSet",
        "TuplesAttributeKey" : "ByteMatchTuples"
    },
    AWS_WAF_GEO_MATCH_CONDITION_TYPE : {},
    AWS_WAF_IP_MATCH_CONDITION_TYPE : {
        "ResourceType" : "IPSet",
        "TuplesAttributeKey" : "IPSetDescriptors"
    },
    AWS_WAF_REGEX_MATCH_CONDITION_TYPE : {},
    AWS_WAF_SIZE_CONSTRAINT_CONDITION_TYPE : {
        "ResourceType" : "SizeConstraintSet",
        "TuplesAttributeKey" : "SizeConstraints"
    },
    AWS_WAF_SQL_INJECTION_MATCH_CONDITION_TYPE : {
        "ResourceType" : "SqlInjectionMatchSet",
        "TuplesAttributeKey" : "SqlInjectionMatchTuples"
    },
    AWS_WAF_XSS_MATCH_CONDITION_TYPE : {
        "ResourceType" : "XssMatchSet",
        "TuplesAttributeKey" : "XssMatchTuples"
    }
}]

[#-- Format used by multiple condition types --]
[#function formatWAFFieldToMatch filter]
    [#return
        {
            "FieldToMatch" : {
                "Type" : filter.FieldType?upper_case
            } +
            attributeIfTrue(
                "Data",
                ["HEADER", "SINGLE_QUERY_ARG"]?seq_contains(filter.FieldType?upper_case),
                filter.FieldData!""
            )
        } ]
[/#function]

[#function formatWAFByteMatchTuple filter={} ]
    [#return
        formatWAFFieldToMatch(filter) +
        {
            "TargetString" : filter.Target,
            "TextTransformation" : filter.Transformation?upper_case,
            "PositionalConstraint" : filter.Constraint?upper_case
        } ]
[/#function]

[#function formatWAFIPMatchTuple filter="" ]
    [#local analyzedCIDR = analyzeCIDR(filter) ]
    [#return
        valueIfContent(
        {
            "Type" : analyzedCIDR.Type,
            "Value" : filter
        },
        analyzedCIDR) ]
[/#function]

[#function formatWAFSizeConstraintTuple filter={} ]
    [#return
        formatWAFFieldToMatch(filter) +
        {
            "ComparisonOperator" : filter.Operator?upper_case,
            "Size" : filter.Size?c,
            "TextTransformation" : filter.Transformation?upper_case
        } ]
[/#function]

[#function formatWAFSqlInjectionMatchTuple filter={} ]
    [#return
        formatWAFFieldToMatch(filter) +
        {
            "TextTransformation" : filter.Transformation?upper_case
        } ]
[/#function]

[#function formatWAFXssMatchTuple filter={} ]
    [#return
        formatWAFFieldToMatch(filter) +
        {
            "TextTransformation" : filter.Transformation?upper_case
        } ]
[/#function]


[#-- Capture similarity between conditions --]
[#macro createWAFCondition mode id name type filters=[] regional=false]
    [#if (WAFConditions[type].ResourceType)?has_content]
        [#local result = [] ]
        [#list asArray(filters) as filter]
            [#switch type]
                [#case AWS_WAF_BYTE_MATCH_CONDITION_TYPE]
                    [#local result += [formatWAFByteMatchTuple(filter)] ]
                    [#break]
                [#case AWS_WAF_IP_MATCH_CONDITION_TYPE]
                    [#local result += [formatWAFIPMatchTuple(filter)] ]
                    [#break]
                [#case AWS_WAF_SIZE_CONSTRAINT_CONDITION_TYPE]
                    [#local result += [formatWAFSizeConstraintTuple(filter)] ]
                    [#break]
                [#case AWS_WAF_SQL_INJECTION_MATCH_CONDITION_TYPE]
                    [#local result += [formatWAFSqlInjectionMatchTuple(filter)] ]
                    [#break]
                [#case AWS_WAF_XSS_MATCH_CONDITION_TYPE]
                    [#local result += [formatWAFXssMatchTuple(filter)] ]
                    [#break]
            [/#switch]
        [/#list]

        [@cfResource
            mode=mode
            id=id
            type=formatWAFResourceType(WAFConditions[type].ResourceType, regional)
            properties=
                {
                    "Name": name,
                    WAFConditions[type].TuplesAttributeKey : result
                }
        /]
    [/#if]
[/#macro]

[#macro createWAFByteMatchSetCondition mode id name matches=[] regional=false]
    [@createWAFCondition
        mode=mode
        id=id
        name=name
        type=AWS_WAF_BYTE_MATCH_CONDITION_TYPE
        filters=matches
        regional=regional /]
[/#macro]

[#macro createWAFIPSetCondition mode id name cidr=[] regional=false]
    [@createWAFCondition
        mode=mode
        id=id
        name=name
        type=AWS_WAF_IP_MATCH_CONDITION_TYPE
        filters=cidr
        regional=regional /]
[/#macro]

[#macro createWAFSizeConstraintCondition mode id name constraints=[] regional=false]
    [@createWAFCondition
        mode=mode
        id=id
        name=name
        type=AWS_WAF_SIZE_CONSTRAINT_CONDITION_TYPE
        filters=constraints
        regional=regional /]
[/#macro]

[#macro createWAFSqlInjectionMatchSetCondition mode id name matches=[] regional=false]
    [@createWAFCondition
        mode=mode
        id=id
        name=name
        type=AWS_WAF_SQL_INJECTION_MATCH_CONDITION_TYPE
        filters=matches
        regional=regional /]
[/#macro]

[#macro createWAFXssMatchSetCondition mode id name matches=[] regional=false]
    [@createWAFCondition
        mode=mode
        id=id
        name=name
        type=AWS_WAF_XSS_MATCH_CONDITION_TYPE
        filters=matches
        regional=regional /]
[/#macro]

[#macro createWAFRule mode id name metric conditions=[] regional=false]
    [#local predicates = [] ]
    [#list asArray(conditions) as condition]
        [#local conditionId = condition.Id!""]
        [#local conditionName = condition.Name!conditionId]
        [#-- Generate id/name from rule equivalents if not provided --]
        [#if !conditionId?has_content]
            [#local conditionId = formatDependentWAFConditionId(condition.Type, id, condition?counter)]
        [/#if]
        [#if !conditionName?has_content]
            [#local conditionName = formatName(name,condition.Type,condition?counter)]
        [/#if]
        [#if condition.Filters?has_content]
            [#-- Condition to be created with the rule --]
            [@createWAFCondition
                mode=mode
                id=conditionId
                name=conditionName
                type=condition.Type
                filters=condition.Filters
                regional=regional /]
        [/#if]
        [#local predicates +=
            [
                {
                    "DataId" : getReference(conditionId),
                    "Negated" : (condition.Negate)!false,
                    "Type" : condition.Type
                }
            ]
        ]
    [/#list]

    [@cfResource
        mode=mode
        id=id
        type=formatWAFResourceType("Rule", regional)
        properties=
            {
                "MetricName" : metric?replace("-","X"),
                "Name": name,
                "Predicates" : predicates
            }
    /]
[/#macro]

[#-- Rules are grouped into bands. Bands are sorted into ascending alphabetic  --]
[#-- order, with rules withing a band ordered based on occurrence in the rules --]
[#-- array. Rules without a band are put into the first band to be considered  --]
[#-- which the rules are provided to derive the priority.                      --]
[#-- Rules without a band fall into the highest band                           --]
[#macro createWAFAcl mode id name metric actionDefault rules=[] regional=false bandDefault="default" ]
    [#-- Determine the bands --]
    [#local bands = [] ]
    [#list asArray(rules) as rule]
        [#local bands += [rule.Band!bandDefault] ]
    [/#list]
    [#local bands = getUniqueArrayElements(bands)?sort]

    [#-- Priorities based on band order --]
    [#local aclRules = [] ]
    [#local nextRulePriority = 1]
    [#list bands as band]
        [#list asArray(rules) as rule]
            [#local ruleBand = rule.Band!bandDefault]
            [#if ruleBand != band]
                [#continue]
            [/#if]
            [#local ruleId = rule.Id!""]
            [#local ruleName = rule.Name!ruleId]
            [#local ruleMetric = rule.Metric!ruleName]
            [#-- Rule to be created with the acl --]
            [#-- Generate id/name/metric from acl equivalents if not provided --]
            [#if !ruleId?has_content]
                [#local ruleId = formatDependentWAFRuleId(id,"rule",rule?counter)]
            [/#if]
            [#if !ruleName?has_content]
                [#local ruleName = formatName(name,"rule",rule?counter)]
            [/#if]
            [#if !ruleMetric?has_content]
                [#local ruleName = formatName(metric,"rule",rule?counter)]
            [/#if]
            [#if rule.Conditions?has_content]
                [@createWAFRule
                    mode=mode
                    id=ruleId
                    name=ruleName
                    metric=ruleMetric
                    conditions=rule.Conditions
                    regional=regional /]
            [/#if]
            [#local aclRules +=
                [
                    {
                        "RuleId" : getReference(ruleId),
                        "Priority" : nextRulePriority,
                        "Action" : {
                        "Type" : rule.Action
                        }
                    }
                ]
            ]
            [#local nextRulePriority += 1]
        [/#list]
    [/#list]

    [@cfResource
        mode=mode
        id=id
        type=formatWAFResourceType("WebACL", regional)
        properties=
            {
                "DefaultAction" : {
                    "Type" : actionDefault
                },
                "MetricName" : metric?replace("-","X"),
                "Name": name,
                "Rules" : aclRules
            }
    /]
[/#macro]

