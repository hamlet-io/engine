[#ftl]

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
[#function formatWAFIPMatchTuples filter={} valueSet={} ]
    [#local result= [] ]
    [#list getWAFValueList(filter.Targets, valueSet) as target]
        [#local result += [
                {
                    "Type" : "IPV4",
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


[#-- Capture similarity between conditions --]
[#macro createWAFCondition id name type filters=[] valueSet={} regional=false]
    [#if (WAFConditions[type].ResourceType)?has_content]
        [#local result = [] ]
        [#list asArray(filters) as filter]
            [#switch type]
                [#case AWS_WAF_BYTE_MATCH_CONDITION_TYPE]
                    [#local result += formatWAFByteMatchTuples(filter, valueSet) ]
                    [#break]
                [#case AWS_WAF_IP_MATCH_CONDITION_TYPE]
                    [#local result += formatWAFIPMatchTuples(filter, valueSet) ]
                    [#break]
                [#case AWS_WAF_SIZE_CONSTRAINT_CONDITION_TYPE]
                    [#local result += formatWAFSizeConstraintTuples(filter, valueSet) ]
                    [#break]
                [#case AWS_WAF_SQL_INJECTION_MATCH_CONDITION_TYPE]
                    [#local result += formatWAFSqlInjectionMatchTuples(filter, valueSet) ]
                    [#break]
                [#case AWS_WAF_XSS_MATCH_CONDITION_TYPE]
                    [#local result += formatWAFXssMatchTuples(filter, valueSet) ]
                    [#break]
            [/#switch]
        [/#list]

        [@cfResource
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

[#macro createWAFByteMatchSetCondition id name matches=[] valueSet={} regional=false]
    [@createWAFCondition
        id=id
        name=name
        type=AWS_WAF_BYTE_MATCH_CONDITION_TYPE
        filters=matches
        valueSet=valueSet
        regional=regional /]
[/#macro]

[#macro createWAFIPSetCondition id name cidr=[] regional=false]
    [#local filters = [{"Targets" : "ips"}] ]
    [#local valueSet = {"ips" : asFlattenedArray(cidr) } ]
    [@createWAFCondition
        id=id
        name=name
        type=AWS_WAF_IP_MATCH_CONDITION_TYPE
        filters=filters
        valueSet=valueSet
        regional=regional /]
[/#macro]

[#macro createWAFSizeConstraintCondition id name constraints=[] valueSet={} regional=false]
    [@createWAFCondition
        id=id
        name=name
        type=AWS_WAF_SIZE_CONSTRAINT_CONDITION_TYPE
        filters=constraints
        valueSet=valueSet
        regional=regional /]
[/#macro]

[#macro createWAFSqlInjectionMatchSetCondition id name matches=[] valueSet={} regional=false]
    [@createWAFCondition
        id=id
        name=name
        type=AWS_WAF_SQL_INJECTION_MATCH_CONDITION_TYPE
        filters=matches
        valueSet=valueSet
        regional=regional /]
[/#macro]

[#macro createWAFXssMatchSetCondition id name matches=[] valueSet={} regional=false]
    [@createWAFCondition
        id=id
        name=name
        type=AWS_WAF_XSS_MATCH_CONDITION_TYPE
        filters=matches
        valueSet=valueSet
        regional=regional /]
[/#macro]

[#macro createWAFRule id name metric conditions=[] valueSet={} regional=false]
    [#local predicates = [] ]
    [#list asArray(conditions) as condition]
        [#local conditionId = condition.Id!""]
        [#local conditionName = condition.Name!conditionId]
        [#-- Generate id/name from rule equivalents if not provided --]
        [#if !conditionId?has_content]
            [#local conditionId = formatDependentWAFConditionId(condition.Type, id, "c" + condition?counter?c)]
        [/#if]
        [#if !conditionName?has_content]
            [#local conditionName = formatName(name,"c" + condition?counter?c,condition.Type)]
        [/#if]
        [#if condition.Filters?has_content]
            [#-- Condition to be created with the rule --]
            [@createWAFCondition
                id=conditionId
                name=conditionName
                type=condition.Type
                filters=condition.Filters
                valueSet=valueSet
                regional=regional /]
        [/#if]
        [#local predicates +=
            [
                {
                    "DataId" : getReference(conditionId),
                    "Negated" : (condition.Negated)!false,
                    "Type" : condition.Type
                }
            ]
        ]
    [/#list]

    [@cfResource
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

[#-- Rules are grouped into bands. Bands are sorted into ascending alphabetic --]
[#-- order, with rules within a band ordered based on occurrence in the rules --]
[#-- array. Rules without a band are put into the default band.               --]
[#macro createWAFAcl id name metric defaultAction rules=[] valueSet={} regional=false bandDefault="default" ]
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
                [#local ruleId = formatDependentWAFRuleId(id,"r" + rule?counter?c)]
            [/#if]
            [#if !ruleName?has_content]
                [#local ruleName = formatName(name,"r" + rule?counter?c,rule.NameSuffix!"")]
            [/#if]
            [#if !ruleMetric?has_content]
                [#local ruleMetric = formatId(metric,"r" + rule?counter?c)]
            [/#if]
            [#if rule.Conditions?has_content]
                [@createWAFRule
                    id=ruleId
                    name=ruleName
                    metric=ruleMetric
                    conditions=rule.Conditions
                    valueSet=valueSet
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
        id=id
        type=formatWAFResourceType("WebACL", regional)
        properties=
            {
                "DefaultAction" : {
                    "Type" : defaultAction
                },
                "MetricName" : metric?replace("-","X"),
                "Name": name,
                "Rules" : aclRules
            }
    /]
[/#macro]

[#macro createWAFAclFromSecurityProfile id name metric wafSolution securityProfile occurrence={} regional=false]
    [#if wafSolution.OWASP]
        [#local wafProfile = blueprintObject.WAFProfiles[securityProfile.WAFProfile!""]!{} ]
    [#else]
        [#local wafProfile = {"Rules" : [], "DefaultAction" : "ALLOW"} ]
    [/#if]
    [#local wafValueSet = blueprintObject.WAFValueSets[securityProfile.WAFValueSet!""]!{} ]

    [#if getGroupCIDRs(wafSolution.IPAddressGroups, true, occurrence, true) ]
        [#local wafValueSet += {
                "whitelistedips" : getGroupCIDRs(wafSolution.IPAddressGroups, true, occurrence)
            } ]
        [#local wafProfile += {
                "Rules" :
                    wafProfile.Rules +
                    [
                        {
                        "Rule" : "whitelist",
                        "Action" : "ALLOW"
                        }
                    ],
                "DefaultAction" : "BLOCK"
            } ]
    [/#if]

    [#local rules=getWAFProfileRules(wafProfile, blueprintObject.WAFRuleGroups, blueprintObject.WAFRules, blueprintObject.WAFConditions) ]
    [@createWAFAcl
        id=id
        name=name
        metric=metric
        defaultAction=wafProfile.DefaultAction
        rules=rules
        valueSet=wafValueSet
        regional=regional
        bandDefault=wafProfile.BandDefault!"default" /]
[/#macro]

[#-- Associations are only relevant for regional endpoints --]
[#macro createWAFAclAssociation id wafaclId endpointId ]
    [@cfResource
        id=id
        type=formatWAFResourceType("WebACLAssociation", true)
        properties=
            {
                "ResourceArn" : getArn(endpointId),
                "WebACLId" : getReference(wafaclId)
            }
    /]
[/#macro]