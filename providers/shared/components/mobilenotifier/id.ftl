[#ftl]

[#-- Engines --]
[#assign MOBILENOTIFIER_SMS_ENGINE = "SMS" ]

[@addComponentDeployment
    type=MOBILENOTIFIER_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=MOBILENOTIFIER_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A managed mobile notification proxy"
            }
        ]
    attributes=
        [
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "SuccessSampleRate",
                "Types" : STRING_TYPE,
                "Default" : "100"
            },
            {
                "Names" : "Credentials",
                "Children" : [
                    {
                        "Names" : "EncryptionScheme",
                        "Types" : STRING_TYPE,
                        "Values" : ["base64"],
                        "Default" : "base64"
                    }
                ]
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Logging",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            }
        ]
/]

[@addChildComponent
    type=MOBILENOTIFIER_PLATFORM_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A specific mobile platform notification proxy"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
            },
            {
                "Type" : "Note",
                "Value" : "SMS Engine requires account level configuration for AWS provider",
                "Severity" : "warning"
            },
            {
                "Type" : "Note",
                "Value" : "Platform specific credentials are required and must be provided as credentials",
                "Severity" : "info"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "SuccessSampleRate",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "Credentials",
                "Children" : [
                    {
                        "Names" : "EncryptionScheme",
                        "Types" : STRING_TYPE,
                        "Values" : ["base64"]
                    }
                ]
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            }
            {
                "Names" : "LogMetrics",
                "SubObjects" : true,
                "Children" : logMetricChildrenConfiguration
            },
            {
                "Names" : "Alerts",
                "SubObjects" : true,
                "Children" : alertChildrenConfiguration
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Alert",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Logging",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            }
        ]
    parent=MOBILENOTIFIER_COMPONENT_TYPE
    childAttribute="Platforms"
    linkAttributes="Platform"
/]
