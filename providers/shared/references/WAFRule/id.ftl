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
            "Description" : "User defined WAF conditions which will be used to either enforce the rule or scope it",
            "Types" : ARRAY_OF_OBJECT_TYPE,
            "Children" : [
                {
                    "Names" : "Condition",
                    "Description" : "The name of the WAFCondition reference object to use",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Negated",
                    "Description" : "Should the result of the rule be negated",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : false
                }
            ]
        },
        {
            "Names" : "Engine",
            "Description" : "The engine of the rule that will be used to evaluate the traffic",
            "Values" : [ "Conditional", "RateLimit", "VendorManaged" ],
            "Types": STRING_TYPE,
            "Default" : "Conditional"
        },
        {
            "Names" : "Engine:RateLimit",
            "Description": "Measures request rate based on client IP and applies an action when it hits the rate limit",
            "Children": [
                {
                    "Names" : "IPAddressSource",
                    "Description" : "The source of the IP address to apply rate limiting to - Client IP: TCP connection address, HTTPHeader: use a header with the IP listed",
                    "Types": STRING_TYPE,
                    "Values" : [ "ClientIP", "HTTPHeader" ],
                    "Default": "ClientIP"
                },
                {
                    "Names": "IPAddressSource:HTTPHeader",
                    "Description" : "HTTP Header Specific IP Address Source Config",
                    "Children": [
                        {
                            "Names": "HeaderName",
                            "Description": "The name of the HTTP header to get the client IP from",
                            "Types": STRING_TYPE,
                            "Default": "X-Forwarded-For"
                        },
                        {
                            "Names": "ApplyLimitWhenMissing",
                            "Description": "When the header is missing apply the rate limit",
                            "Types": BOOLEAN_TYPE,
                            "Default": false
                        }
                    ]
                },
                {
                    "Names": "Limit",
                    "Description": "The limit to activate the rule in, measured in requests / 5 mins",
                    "Types": NUMBER_TYPE
                }
            ]
        },
        {
            "Names": "Engine:VendorManaged",
            "Description": "Use a Vendor managed rule to apply dynamic controls",
            "Children" : [
                {
                    "Names" : "Vendor",
                    "Description" : "The name of the vendor the managed rule belongs to",
                    "Types" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names": "RuleName",
                    "Description" : "The name of the rule to use",
                    "Types": STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names": "RuleVersion",
                    "Description" : "The version of the rule to use",
                    "Types" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "Parameters",
                    "Description" : "Rule specific parameters used to apply additional configuration",
                    "Types" : ANY_TYPE,
                    "Default" : {}
                },
                {
                    "Names" : "DisabledRules",
                    "Description" : "A list of rules within the managed rule which should be disabled",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "ActionOverrides",
                    "Subobjects": true,
                    "Children" : [
                        {
                            "Names" : "Name",
                            "Description": "The name of the rule inside the vendor ruleset - uses the child id if not set",
                            "Types" : STRING_TYPE
                        },
                        {
                            "Names": "Action",
                            "Description" : "The action to perform when the rule is matched",
                            "Types" : STRING_TYPE,
                            "Values": [ "BLOCK", "ALLOW", "COUNT"]
                        }
                    ]
                }
            ]
        }
    ]
/]
