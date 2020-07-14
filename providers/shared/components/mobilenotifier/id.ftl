[#ftl]

[#-- Engines --]
[#assign MOBILENOTIFIER_SMS_ENGINE = "SMS" ]

[@addComponent
    type=MOBILENOTIFIER_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A managed mobile notification proxy"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
            }
        ]
    attributes=
        [
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "SuccessSampleRate",
                "Type" : STRING_TYPE,
                "Default" : "100"
            },
            {
                "Names" : "Credentials",
                "Children" : [
                    {
                        "Names" : "EncryptionScheme",
                        "Type" : STRING_TYPE,
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
                        "Type" : STRING_TYPE,
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
                "Type" : STRING_TYPE
            },
            {
                "Names" : "SuccessSampleRate",
                "Type" : STRING_TYPE
            },
            {
                "Names" : "Credentials",
                "Children" : [
                    {
                        "Names" : "EncryptionScheme",
                        "Type" : STRING_TYPE,
                        "Values" : ["base64"]
                    }
                ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "LogMetrics",
                "Subobjects" : true,
                "Children" : logMetricChildrenConfiguration
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Alert",
                        "Type" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Logging",
                        "Type" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            }
        ]
    parent=MOBILENOTIFIER_COMPONENT_TYPE
    childAttribute="Platforms"
    linkAttributes="Platform"
/]
