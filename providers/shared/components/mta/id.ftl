[#ftl]

[@addComponentDeployment
    type=MTA_COMPONENT_TYPE
    defaultGroup="solution"
/]

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
                "Type" : STRING_TYPE,
                "Values" : ["send", "receive"],
                "Default" : "send",
                "Mandatory" : true
            },
            {
                "Names" : "Certificate",
                "Description" : "Configure the domain(s) associated with this MTA",
                "Children" : certificateChildConfiguration
            },
            {
                "Names" : "IPAddressGroups",
                "Description" : "Allowed IP addresses. If any group is provided, all unmatching traffic will be blocked",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            }
        ]
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
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Order",
                "Description" : "The order in which rules are checked. Lower is checked earlier",
                "Type" : NUMBER_TYPE,
                "Default" : 100
            },
            {
                "Names" : "Conditions",
                "Description" : "Conditions that must be met for the rule to fire. Conditions are ANDed together",
                "Children" : [
                    {
                        "Names" : "Recipients",
                        "Description" : "Expected To addresses",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    }
                ]
            },
            {
                "Names" : "Action",
                "Type" : STRING_TYPE,
                "Values" : ["forward", "drop"],
                "Mandatory" : true
            },
            {
                "Names" : "Links",
                "Description" : "Target/role determines implementation of action",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
/]
