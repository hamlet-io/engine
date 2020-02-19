[#ftl]

[@addReference
    type=ALERTRULE_REFERENCE_TYPE
    pluralType="AlertRules"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A alert filtering rule to forward alerts based on their severity"
            }
        ]
    attributes=[
        {
            "Names" : "Severity",
            "Type" : STRING_TYPE,
            "Values" : [ "debug", "info", "warn", "error", "fatal"],
            "Mandatory" : true
        },
        {
            "Names" : "Destinations",
            "Children" : [
                {
                    "Names" : "Links",
                    "SubObjects" : true,
                    "Children" : linkChildrenConfiguration
                }
            ]
        }
    ]
/]