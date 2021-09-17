[#ftl]

[@addComponent
    type=MTA_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Message Transfer Agent for sending or receiving emails"
            }
        ]
    attributes=
        [
            {
                "Names" : "Direction",
                "Types" : STRING_TYPE,
                "Values" : ["send", "receive"],
                "Default" : "send",
                "Mandatory" : true
            },
            {
                "Names" : [ "Certificate", "Hostname" ],
                "Description" : "Configure the domain(s) associated with this MTA",
                "Children" : certificateChildConfiguration
            },
            {
                "Names" : "IPAddressGroups",
                "Description" : "Allowed IP addresses. If any group is provided, all unmatching traffic will be blocked",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            }
        ]
/]

[@addComponentDeployment
    type=MTA_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addChildComponent
    type=MTA_RULE_COMPONENT_TYPE
    parent=MTA_COMPONENT_TYPE
    childAttribute="Rules"
    linkAttributes="Rule"
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A rule applied by a Message Transfer Agent"
            }
        ]
    attributes=
        [
            {
                "Names" : "Enabled",
                "Description" : "Permit the rule to be considered",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Order",
                "Description" : "The order in which rules are checked. Lower is checked earlier",
                "Types" : NUMBER_TYPE,
                "Default" : 100
            },
            {
                "Names" : "Conditions",
                "Description" : "Conditions that must be met for the rule to fire. Conditions are ANDed together",
                "Children" : [
                    {
                        "Names" : "Recipients",
                        "Description" : "Expected To addresses",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    }
                ]
            },
            {
                "Names" : "Action",
                "Types" : STRING_TYPE,
                "Values" : ["forward", "drop"],
                "Mandatory" : true
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            }
        ]
/]
