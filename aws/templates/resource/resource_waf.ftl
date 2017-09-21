[#-- Web Application Firewall --]

[#assign WAF_IPSET_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        NAME_ATTRIBUTE_TYPE : { 
            "Attribute" : "QueueName"
        },
        ARN_ATTRIBUTE_TYPE : { 
            "Attribute" : "Arn"
        },
        URL_ATTRIBUTE_TYPE : { 
            "UseRef" : true
        }
    }
]
[#assign outputMappings +=
    {
        SQS_RESOURCE_TYPE : SQS_OUTPUT_MAPPINGS
    }
]

[#macro createWAFIPSet mode id name cidr]
    [#local ipSetDescriptors = [] ]
    [#list cidr as entry]
        [#local ipSetDescriptors += 
            [
                {
                    "Type" : "IPV4",
                    "Value" : entry
                }
            ]
        ]
    [/#list]
    
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::WAF::IPSet"
        properties=
            {
                "Name": name,
                "IPSetDescriptors": ipSetDescriptors
            }
    /]
[/#macro]

[#macro createWAFRule mode id name metric conditions]
    [#local predicates = [] ]
    [#list conditions as condition]
        [#local predicates += 
            [
                {
                    "DataId" : getReference(condition.Id),
                    "Negated" : (condition.Negate)!false,
                    "Type" : condition.Type
                }
            ]
        ]
    [/#list]

    [@cfTemplate
        mode=mode
        id=id
        type="AWS::WAF::Rule"
        properties=
            {
                "MetricName" : metric?replace("-","X"),
                "Name": name,
                "Predicates" : predicates
            }
    /]
[/#macro]

[#macro createWAFAcl mode id name metric default rules]
    [#local aclRules = [] ]
    [#list rules as rule]
        [#local aclRules += 
            [
                {
                    "RuleId" : getReference(rule.Id),
                    "Priority" : rule?counter,
                    "Action" : {
                      "Type" : rule.Action
                    }
                }
            ]
        ]
    [/#list]
    
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::WAF::WebACL"
        properties=
            {
                "DefaultAction" : {
                    "Type" : default
                },
                "MetricName" : metric?replace("-","X"),
                "Name": name,
                "Rules" : aclRules
            }
    /]
[/#macro]

