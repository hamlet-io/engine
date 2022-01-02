[#ftl]

[@addModule
    name="runbook"
    description="Hamlet engine runbook testing"
    provider=SHAREDTEST_PROVIDER
    properties=[]
/]

[#macro sharedtest_module_runbook ]

    [@loadModule
        blueprint={
            "Tiers" : {
                "app" : {
                    "Components" : {
                        "runbookbase" : {
                            "Type" : "runbook",
                            "Engine" : "hamlet",
                            "Inputs" : {
                                "input1" : {
                                    "Types" : [ "string" ],
                                    "Default" : "value1"
                                }
                            },
                            "Profiles" : {
                                "Placement" : "shared"
                            },
                            "Steps" : {
                                "step1" : {
                                    "Priority" : 10,
                                    "Host" : {
                                        "Engine" : "Local"
                                    },
                                    "Conditions" : {
                                        "linkTest" : {
                                            "Test" : "linkAttr1",
                                            "Match" : "Equals",
                                            "Value" : {
                                                "Source" : "Attribute",
                                                "source:Attribute" : {
                                                    "LinkId" : "linktest",
                                                    "Name" : "attr1"
                                                }
                                            }
                                        }
                                    },
                                    "Task" : {
                                        "Name" : "rename_file",
                                        "Properties" : {
                                            "currentFileName" : {
                                                "Source" : "Input",
                                                "source:Input" : {
                                                    "Id" : "input1"
                                                }
                                            },
                                            "newFileName" : {
                                                "Source" : "Setting",
                                                "source:Setting" : {
                                                    "Name" : "ENVIRONMENT"
                                                }
                                            }
                                        }
                                    },
                                    "Links" : {
                                        "linktest" : {
                                            "Tier" : "app",
                                            "Component" : "runbookbase_linktest"
                                        }
                                    }
                                },
                                "step2" : {
                                    "Priority" : 20,
                                    "Task" : {
                                        "Name" : "run_ssh_shell_command",
                                        "Properties" : {
                                            "Username" : {
                                                "Source" : "Fixed",
                                                "source:Fixed" : {
                                                    "Value" : "admin"
                                                }
                                            },
                                            "Host" : {
                                                "Source" : "Fixed",
                                                "source:Fixed" : {
                                                    "Value" : "host.local"
                                                }
                                            },
                                            "Command" : {
                                                "Source" : "Fixed",
                                                "source:Fixed" : {
                                                    "Value" : "/bin/bash"
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        "runbookbase_linktest" : {
                            "Type" : "externalservice",
                            "Properties" : {
                                "attr1" : {
                                    "Key" : "attr1",
                                    "Value" : "linkAttr1"
                                }
                            },
                            "Profiles" : {
                                "Placement" : "external"
                            }
                        }
                    }
                }
            }
        }
    /]
[/#macro]
