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
                "Names" : [ "Hostname", "Certificate" ],
                "Description" : "Configure the domain(s) associated with this MTA",
                "AttributeSet" : CERTIFICATE_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "IPAddressGroups",
                "Description" : "Allowed IP addresses. If any group is provided, all unmatching traffic will be blocked",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_global" ]
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
                        "Description" : "The recipient of the email to match on",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    },
                    {
                        "Names" : "Senders",
                        "Description" : "The senders of the email to match on",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    }
                ]
            },
            {
                "Names" : "Action",
                "Types" : STRING_TYPE,
                "Values" : [
                    "forward",
                    "receive-bounce",
                    "drop",
                    "log"
                ],
                "Mandatory" : true
            },
            {
                "Names": "StopAfterMatch",
                "Type": BOOLEAN_TYPE,
                "Description" : "If this rule is matched don't apply any other rules after this one",
                "Default" : false
            },
            {
                "Names" : "EventTypes",
                "Description" : "Expected events to log (send only)",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [
                    "reject",
                    "bounce",
                    "complaint"
                ],
                "Values" : [
                    "click",
                    "bounce",
                    "send",
                    "open",
                    "complaint",
                    "delivery",
                    "renderingFailure",
                    "reject"
                ]
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Action:receive-bounce",
                "Description" : "Specific configuration for using the receive-bounce action",
                "Children" : [
                    {
                        "Names": "BounceType",
                        "Description" : "The type of bounce to return to the sender - _custom lets you define it",
                        "Values" : [ "no_address_found", "unauthorised", "custom" ],
                        "Default" : "no_address_found"
                    },
                    {
                        "Names": "BounceType:custom",
                        "Description" : "Custom configuration to define the bounce details",
                        "Children" : [
                            {
                                "Names": "Message",
                                "Description": "The human readable message to return",
                                "Types": STRING_TYPE,
                                "Default" : ""
                            },
                            {
                                "Names" : "SmtpReplyCode",
                                "Description": "The RFC 5321 code to return",
                                "Types" : STRING_TYPE,
                                "Default" : "550"
                            },
                            {
                                "Names": "SmtpStatusCode",
                                "Description": "The RFC 3463 enhanced status code to return",
                                "Types" : STRING_TYPE,
                                "Default" : "0.0.0"
                            }
                        ]
                    }
                ]
            }
        ]
/]
