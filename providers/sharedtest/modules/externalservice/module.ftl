[#ftl]

[@addModule
    name="externalservice"
    description="Testing module for the externalservice component"
    provider=SHAREDTEST_PROVIDER
    properties=[]
/]

[#macro sharedtest_module_externalservice ]

    [@loadModule
        blueprint={
            "Tiers" : {
                "app" : {
                    "Components" : {
                        "externalservicebase" : {
                            "externalservice" : {
                                "Instances" : {
                                    "default" : {
                                        "deployment:Unit" : "shared-externalservice-base"
                                    }
                                },
                                "Profiles" : {
                                    "Testing" : [ "externalservicebase" ],
                                    "Placement" : "external"
                                }
                            }
                        }
                    }
                }
            },
            "TestProfiles" : {
                "externalservicebase" : {
                    "externalservice" : {
                        "TestCases" : [ "externalservicebase_core" ]
                    }
                }
            },
            "TestCases" : {
                "externalservicebase_core" : {
                    "OutputSuffix" : "config.json",
                    "Structural" : {
                        "JSON" : {
                            "Match" : {
                                "id" : {
                                    "Path" : "Occurrence.Core.Id",
                                    "Value" : "appXexternalservicebase"
                                },
                                "name" : {
                                    "Path" : "Occurrence.Core.Name",
                                    "Value" : "application-externalservicebase"
                                },
                                "fullName" : {
                                    "Path" : "Occurrence.Core.FullName",
                                    "Value" : "mockedup-integration-application-externalservicebase"
                                },
                                "relativePath" : {
                                    "Path" : "Occurrence.Core.RelativePath",
                                    "Value" : "application/externalservicebase"
                                },
                                "fullAbsolutePath" : {
                                    "Path" : "Occurrence.Core.FullAbsolutePath",
                                    "Value" : "/mockedup/integration/application/externalservicebase"
                                }
                            }
                        }
                    }
                }
            }
        }
    /]
[/#macro]
