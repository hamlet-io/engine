[#-- MOBILENOTIFIER --]

[#-- Components --]
[#assign MOBILENOTIFIER_COMPONENT_TYPE = "mobilenotifier" ]
[#assign MOBILENOTIFIER_PLATFORM_COMPONENT_TYPE = "mobilenotiferplatform" ]

[#assign componentConfiguration +=
    {
        MOBILENOTIFIER_COMPONENT_TYPE : {
            "Attributes" : [
                { 
                    "Name" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Name" : "SuccessSampleRate",
                    "Default" : "100"
                },
                {
                    "Name" : "Credentials",
                    "Children" : [
                        {
                            "Name" : "EncryptionScheme",
                            "Default" : "base64"
                        }
                    ]
                }
            ],
            "Components" : [
                {
                    "Type" : MOBILENOTIFIER_PLATFORM_COMPONENT_TYPE,
                    "Component" : "Platforms",
                    "Link" : [ "Platform" ]
                }
            ]
        },
        MOBILENOTIFIER_PLATFORM_COMPONENT_TYPE : [
            {
                "Name" : "Engine"
            },
            {
                "Name" : "SuccessSampleRate"
            },
            {
                    "Name" : "Credentials",
                    "Children" : [
                        {
                            "Name" : "EncryptionScheme"
                        }
                    ]
                }
            { 
                "Name" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
    }]

[#function getMobileNotifierState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local result =
        {
            "Resources" : {
                "role" : {
                    "Id" : formatDependentRoleId( core.Id ),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                }
            },
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
    [#return result ]
[/#function]

[#function getMobileNotifierPlatformState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(AWS_SNS_PLATFORMAPPLICATION_RESOURCE_TYPE, core.Id) ]
    [#local engine = solution.Engine!core.SubComponent.Name?upper_case  ]

    [#local result =
        {
            "Resources" : {
                "platformapplication" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "Engine" : engine,
                    "Type" : AWS_SNS_PLATFORMAPPLICATION_RESOURCE_TYPE 
                }
            },
            "Attributes" : {
                "ARN" : getExistingReference(id, ARN_ATTRIBUTE_TYPE),
                "ENGINE" : engine,
                "TOPIC_PREFIX" : core.ShortFullName
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {
                    "default" : "publish",
                    "publish" : snsPublishPlatformApplication(id)
                }
            }
        }
    ]
    [#return result ]
[/#function]