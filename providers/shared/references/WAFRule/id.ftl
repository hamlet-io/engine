[#ftl]

[@addReference
    type=WAFRULE_REFERENCE_TYPE
    pluralType="WAFRules"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Web Application Firewall Rule"
            }
        ]
    attributes=[
        {
            "Names" : "NameSuffix",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Conditions",
            "Types" : ARRAY_OF_OBJECT_TYPE,
            "Children" : [
                {
                    "Names" : "Condition",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Negated",
                    "Types" : BOOLEAN_TYPE
                }
            ]
        }
    ]
/]

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
    AWS_WAF_GEO_MATCH_CONDITION_TYPE : {
        "ResourceType" : "GeoMatchSet",
        "TuplesAttributeKey" : "GeoMatchConstraints"
    },
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