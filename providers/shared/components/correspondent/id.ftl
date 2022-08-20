[#ftl]

[@addComponent
    type=CORRESPONDENT_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "An outbound and inbound marketing communications service such as AWS Pinpoint"
            }
        ]
    attributes=
        [
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            }
        ]
/]

[@addComponentDeployment
    type=CORRESPONDENT_COMPONENT_TYPE
    defaultGroup="solution"
    defaultPriority=70
/]


[@addChildComponent
    type=CORRESPONDENT_CHANNEL_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A channel used to send correspondence"
            }
        ]
    attributes=
        [
            {
                "Names" : "Enabled",
                "Types": BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Engine",
                "Description": "The service used to send correspondence",
                "Types" : STRING_TYPE,
                "Values" : [ "apns", "apns_sandbox", "firebase" ],
                "Mandatory" : true
            },
            {
                "Names" : "engine:Firebase",
                "Description" : "Specific channel configuration for Firebase/Google notification services",
                "Children" : [
                    {
                        "Names" : "APIKey",
                        "Description" : "The setting or link name to use for the API Key - setting:_setting name_ - link: _link name_",
                        "Types" : STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "engine:APNS",
                "Description" : "Specific channel configuration for Apple Notification Services",
                "Children" : [
                    {
                        "Names": "Certificate",
                        "Description" : "The push notification public certificate",
                        "Types" : STRING_TYPE
                    },
                    {
                        "Names" : "PrivateKey",
                        "Description" : "The push notification private key",
                        "Types" : STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "engine:APNSSandbox",
                "Description" : "Specific channel configuration for Apple Sandbox Notification Services",
                "Children" : [
                    {
                        "Names": "Certificate",
                        "Description" : "The push notification public certificate",
                        "Types" : STRING_TYPE
                    },
                    {
                        "Names" : "PrivateKey",
                        "Description" : "The push notification private key",
                        "Types" : STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            }
        ]
    parent=CORRESPONDENT_COMPONENT_TYPE
    childAttribute="Channels"
    linkAttributes=["Channel"]
/]
