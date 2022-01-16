[#ftl]

[@addAttributeSet
    type=NETWORKRULE_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Network Access rule configuration"
        }]
    attributes=[
        {
            "Names" : "Ports",
            "Description" : "A list of port ids from the Ports reference",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "IPAddressGroups",
            "Description" : "A list of IP Address groups ids from the IPAddressGroups reference",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "SecurityGroups",
            "Description" : "A list of security groups or ids - for internal use only",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "Description",
            "Description" : "A description that will be applied to the rule",
            "Types" : STRING_TYPE,
            "Default" : ""
        }
     ]
/]
