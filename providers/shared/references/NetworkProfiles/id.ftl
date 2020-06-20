[#ftl]

[@addReference
    type=NETWORKPROFILE_REFERENCE_TYPE
    pluralType="NetworkProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A profile to desribe network level controls"
            }
        ]
    attributes=[
        {
            "Names" : "BaseSecurityGroup",
            "Children" : [
                {
                    "Names" : "Links",
                    "Description" : "Apply network security rules based on links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Outbound",
                    "Description" : "Network level Rules to apply",
                    "Children" : networkRuleChildConfiguration
                }
            ]
        }
    ]
/]
