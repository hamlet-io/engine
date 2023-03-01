[#ftl]

[@addAttributeSet
    type=WAF_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "The Web Application Firewall Policy to apply"
        }]
    attributes=[
        {
            "Names" : "Enabled",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "IPAddressGroups",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "CountryGroups",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "OWASP",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "Logging",
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                }
            ]
        },
        {
            "Names" : "Profiles",
            "Children" : [
                {
                    "Names" : "Logging",
                    "Description" : "Logging profile to process WAF Logs that are stored in the OpsData DataBucket.",
                    "Types"  : STRING_TYPE,
                    "Default" : "waf"
                }
            ]
        },
        {
            "Names" : "RateLimits",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "IPAddressGroups",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Limit",
                    "Types" : NUMBER_TYPE,
                    "Mandatory" : true
                }
            ]
        }
     ]
/]
