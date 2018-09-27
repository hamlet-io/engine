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
                    "Type" : STRING_TYPE,
                    "Default" : "100"
                },
                {
                    "Name" : "Credentials",
                    "Children" : [
                        {
                            "Name" : "EncryptionScheme",
                            "Type" : STRING_TYPE,
                            "Values" : ["base64"],
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
                "Name" : "Engine",
                "Type" : STRING_TYPE
            },
            {
                "Name" : "SuccessSampleRate",
                "Type" : STRING_TYPE
            },
            {
                "Name" : "Credentials",
                "Children" : [
                    {
                        "Name" : "EncryptionScheme",
                        "Type" : STRING_TYPE,
                        "Values" : ["base64"]
                    }
                ]
            },
            { 
                "Name" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Name" : "LogWatchers",
                "Subobjects" : true,
                "Children" : logWatcherChildrenConfiguration
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
    [#local name = core.FullName ]
    [#local topicPrefix = core.ShortFullName]
    [#local engine = solution.Engine!core.SubComponent.Name?upper_case  ]

    [#local lgNameComponents = 
        [
            "sns",
            { "Ref" : "AWS::Region" },
            { "Ref" : "AWS::AccountId" }
        ]]

    [#if engine != "SMS" ] 
        [#local lgNameComponents += [
            "app",
            engine,
            name
        ]]

    [#else]
        [#local lgNameComponents += [
            "DirectPublishToPhoneNumber"
        ]]
    [/#if]

    [#local lgName = 
        {
            "Fn::Join" : [
                "/",
                lgNameComponents
            ]
        }
    ]

    [#local lgFailureName = 
        {
            "Fn::Join" : [
                "/",
                lgNameComponents + [ "Failure" ]
            ]
        }
    ]

    [#local result =
        {
            "Resources" : {
                "platformapplication" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "Engine" : engine,
                    "Type" : AWS_SNS_PLATFORMAPPLICATION_RESOURCE_TYPE 
                },
                "lg" : {
                    "Id" : formatLogGroupId(core.Id),
                    "Name" : lgName,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                },
                "lgfailure" : {
                    "Id" : formatLogGroupId(core.Id, "failure"),
                    "Name" : lgFailureName,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "ARN" : (engine == "SMS")?then(
                            formatArn(
                                regionObject.Partition,
                                "sns", 
                                regionId,
                                accountObject.AWSId,
                                "smsPlaceHolder"
                            ),
                            getExistingReference(id, ARN_ATTRIBUTE_TYPE)
                ),
                "ENGINE" : engine,
                "TOPIC_PREFIX" : topicPrefix
            },
            "Roles" : {
                "Inbound" : {
                    "logwatch" : {
                        "Principal" : "logs." + regionId + "amazonaws.com",
                        "SourceArn" : [
                            formatCloudWatchLogArn(lgName),
                            formatCloudWatchLogArn(lgFailureName)
                        ]
                    }
                },
                "Outbound" : {
                    "default" : "publish",
                    "publish" : (engine == "SMS")?then(
                        snsSMSPermission(),
                        snsPublishPlatformApplication(name, engine, topicPrefix)
                    )
                }
            }
        }
    ]
    [#return result ]
[/#function]