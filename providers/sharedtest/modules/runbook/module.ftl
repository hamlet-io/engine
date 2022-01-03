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
                                    "Conditions" : {
                                        "linkTest" : {
                                            "Test" : "linkAttr1",
                                            "Match" : "Equals",
                                            "Value" : "__attribute:linktest:ATTR1__"
                                        }
                                    },
                                    "Task" : {
                                        "Type" : "rename_file",
                                        "Parameters" : {
                                            "currentFileName" : {
                                                "Value" : "__input:input1__"
                                            },
                                            "newFileName" : {
                                                "Value" : "__setting:ENVIRONMENT__"
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
                                        "Type" : "start_ssh_shell",
                                        "Parameters" : {
                                            "Username" : {
                                                "Value" : "admin"
                                            },
                                            "Host" : {
                                                "Value" : "host.local"
                                            },
                                            "Command" : {
                                                "Value" : "/bin/bash"
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
                                    "Key" : "ATTR1",
                                    "Value" : "linkAttr1"
                                }
                            },
                            "Profiles" : {
                                "Placement" : "shared"
                            }
                        }
                    }
                }
            }
        }
    /]
[/#macro]
