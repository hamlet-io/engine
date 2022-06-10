[#ftl]

[@addModule
    name="internaltest"
    description="Internal testing for hamlet using fake component"
    provider=SHAREDTEST_PROVIDER
    properties=[]
/]

[#macro sharedtest_module_internaltest ]

    [@loadModule
        blueprint={
            "Tiers" : {
                "app" : {
                    "Components" : {
                        "internaltestbase" : {
                            "internaltest" : {
                                "Instances" : {
                                    "default" : {
                                        "deployment:Unit" : "shared-internaltest"
                                    }
                                },
                                "Profiles" : {
                                    "Testing" : [ "internaltestbase" ],
                                    "Placement" : "internal"
                                }
                            }
                        },
                        "contextpath" : {
                            "internaltest" : {
                                "Instances" : {
                                    "default" : {
                                        "deployment:Unit" : "shared-contextpath"
                                    }
                                },
                                "Extensions" : [ "_contextpath_content" ],
                                "Profiles" : {
                                    "Testing" : [ "contextpath" ],
                                    "Placement" : "internal"
                                }
                            }
                        }
                    }
                }
            },
            "TestProfiles" : {
                "internaltestbase" : {
                    "internaltest" : {
                        "TestCases" : [ "internaltestbase_core" ]
                    }
                },
                "contextpath" : {
                    "internaltest" : {
                        "TestCases" : [ "contextpath" ]
                    }
                }
            },
            "TestCases" : {
                "internaltestbase_core" : {
                    "OutputSuffix" : "config.json",
                    "Structural" : {
                        "JSON" : {
                            "Match" : {
                                "id" : {
                                    "Path" : "Occurrence.Core.Id",
                                    "Value" : "appXinternaltestbase"
                                },
                                "name" : {
                                    "Path" : "Occurrence.Core.Name",
                                    "Value" : "application-internaltestbase"
                                },
                                "fullName" : {
                                    "Path" : "Occurrence.Core.FullName",
                                    "Value" : "mockedup-integration-application-internaltestbase"
                                },
                                "relativePath" : {
                                    "Path" : "Occurrence.Core.RelativePath",
                                    "Value" : "application/internaltestbase"
                                },
                                "fullAbsolutePath" : {
                                    "Path" : "Occurrence.Core.FullAbsolutePath",
                                    "Value" : "/mockedup/integration/application/internaltestbase"
                                }
                            }
                        }
                    }
                },
                "contextpath" : {
                    "OutputSuffix" : "config.json",
                    "Structural" : {
                        "JSON" : {
                            "Match" : {
                                "defaultPath" : {
                                    "Path" : "Occurrence.State.Attributes.DEFAULT_CONTEXTPATH_OUTPUT",
                                    "Value" : "mockedup-default"
                                },
                                "defaultPath" : {
                                    "Path" : "Occurrence.State.Attributes.ALLINCLUDES_CONTEXTPATH_OUTPUT",
                                    "Value" : "mockacct-0123456789-mockedup-integration-default-application-contextpath-allincludes"
                                }
                            }
                        }
                    }
                }
            }
        }
    /]
[/#macro]
