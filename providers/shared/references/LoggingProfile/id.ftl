[#ftl]

[@addReference
    type=LOGGINGPROFILE_REFERENCE_TYPE
    pluralType="LoggingProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A profile to describe logging rules for a component"
            }
        ]
    attributes=[
        {
            "Names" : "ForwardingRules",
            "Description" : "Controls the forwarding of logs after they have landed in their initial logging location",
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "Filter",
                    "Description" : "The name of a Logfilter to apply to the forwarding rule",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                }
                {
                    "Names" : "Links",
                    "Description" : "The links of components which will accept fowarded logs",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                }
            ]
        }
    ]
/]
