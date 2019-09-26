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
            "Type" : ARRAY_OF_OBJECT_TYPE
        },
        {
            "Names" : "DefaultAction",
            "Type" : STRING_TYPE,
            "Values" : [ "ALLOW", "BLOCK"]
        }
    ]
/]