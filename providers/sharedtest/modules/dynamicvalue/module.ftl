[#ftl]

[@addModule
    name="dynamicvalue"
    description="Internal testing for hamlet using fake component"
    provider=SHAREDTEST_PROVIDER
    properties=[]
/]

[#macro sharedtest_module_dynamicvalue ]

    [@loadModule
        blueprint={
            "Tiers" : {
                "app" : {
                    "Components" : {
                        "dynamicvalue" : {
                            "Type" : "internaltest",
                            "deployment:Unit" : "shared-dynamicvalue",
                            "Settings" : {
                                "ComponentSetting" : {
                                    "Value" : "ComponentSettingValue"
                                }
                            },
                            "Tags" : {
                                "Additional" : {
                                    "ComponentSettingTag" : {
                                        "Value" : "__setting:ComponentSetting__"
                                    },
                                    "AttributeTag": {
                                        "Value" : "__attribute:dynamicvalue_link:NAME__"
                                    },
                                    "CombinedValueTag" : {
                                        "Value" : "link:__attribute:dynamicvalue_link:NAME__:setting:__setting:ComponentSetting__"
                                    }
                                }
                            },
                            "Profiles" : {
                                "Testing" : [ "dynamicvalue" ],
                                "Placement" : "internal"
                            },
                            "Links" : {
                                "dynamicvalue_link" : {
                                    "Tier" : "app",
                                    "Component" : "dynamicvalue_link"
                                }
                            }
                        },
                        "dynamicvalue_link" : {
                            "Type" : "externalservice",
                            "Properties" : {
                                "name" : {
                                    "Key" : "NAME",
                                    "Value" : "dyanmicvalue-link-attribute-name"
                                }
                            },
                            "Profiles" : {
                                "Placement" : "shared"
                            }
                        }
                    }
                }
            },
            "TestProfiles" : {
                "dynamicvalue" : {
                    "internaltest" : {
                        "TestCases" : [ "dynamicvalue" ]
                    }
                }
            },
            "TestCases" : {
                "dynamicvalue" : {
                    "OutputSuffix" : "config.json",
                    "Structural" : {
                        "JSON" : {
                            "Match" : {
                                "resolvedComponentSettingTag" : {
                                    "Path" : "Occurrence.Configuration.Solution.Tags.Additional.ComponentSettingTag.Value",
                                    "Value" : "ComponentSettingValue"
                                },
                                "resolvedLinkAttributeTag" : {
                                    "Path" : "Occurrence.Configuration.Solution.Tags.Additional.AttributeTag.Value",
                                    "Value": "dyanmicvalue-link-attribute-name"
                                },
                                "combinedValueTag" : {
                                    "Path" : "Occurrence.Configuration.Solution.Tags.Additional.CombinedValueTag.Value",
                                    "Value": "link:dyanmicvalue-link-attribute-name:setting:ComponentSettingValue"
                                }
                            }
                        }
                    }
                }
            }
        }
    /]
[/#macro]
