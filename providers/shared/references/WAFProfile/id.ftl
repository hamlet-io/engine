[#ftl]

[@addReference
    type=WAFPROFILE_REFERENCE_TYPE
    pluralType="WAFProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Web Application Firewall Profile"
            }
        ]
    attributes=[
        {
            "Names" : "Rules",
            "Types" : ARRAY_OF_OBJECT_TYPE,
            "Children" : [
                {
                    "Names" : "Rule",
                    "Description": "The name of rule from the WAFRules reference data",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "RuleGroup",
                    "Description": "The name of rule from the WAFRuleGroups reference data",
                    "Types" : STRING_TYPE
                },
                {
                    "Names": "Action",
                    "Description" : "The action to perform when the rule is matched",
                    "Types" : STRING_TYPE,
                    "Values": [ "BLOCK", "ALLOW"]
                },
                {
                    "Names": "Action:BLOCK",
                    "Description": "Additional configuration when using the BLOCK action",
                    "Children": [
                        {
                            "Names" : "CustomResponse",
                            "Description" : "Return a custom HTTP response when the rule blocks a request",
                            "Children": [
                                {
                                    "Names" : "Enabled",
                                    "Description" : "Enable custom response",
                                    "Types" : BOOLEAN_TYPE,
                                    "Default": false
                                },
                                {
                                    "Names": "StatusCode",
                                    "Description" : "The HTTP Status code to return",
                                    "Types": NUMBER_TYPE,
                                    "Default" : 403
                                },
                                {
                                    "Names": "Headers",
                                    "Description": "HTTP headers to include in the response",
                                    "SubObjects": true,
                                    "Children": [
                                        {
                                            "Names": "Key",
                                            "Description": "The Key of the header uses the id if not provided",
                                            "Types" : STRING_TYPE
                                        },
                                        {
                                            "Names": "Value",
                                            "Description" : "The value of the header",
                                            "Types": STRING_TYPE,
                                            "Mandatory": true
                                        }
                                    ]
                                },
                                {
                                    "Names" : "Body",
                                    "Description" : "The HTTP body to return in the response",
                                    "Children" : [
                                        {
                                            "Names" : "Content",
                                            "Description" : "The content of the Body",
                                            "Types" : STRING_TYPE,
                                            "Mandatory": true
                                        },
                                        {
                                            "Names" : "ContentType",
                                            "Description" : "The type of content",
                                            "Types" : STRING_TYPE,
                                            "Values": [
                                                "application/json",
                                                "text/html",
                                                "text/plain"
                                            ],
                                            "Default": "text/html"
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "DefaultAction",
            "Types" : STRING_TYPE,
            "Values" : [ "ALLOW", "BLOCK"]
        }
    ]
/]
