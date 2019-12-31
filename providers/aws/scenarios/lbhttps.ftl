[#ftl]

[#-- Get stack output --]
[#macro aws_scenario_lbhttps ]
    [@addScenario
        id="lbhttps"
        blueprint={
            "Tiers" : {
                "elb" : {
                    "Components" : {
                        "httpslb" : {
                            "LB" : {
                                "Instances" : {
                                    "default" : {
                                        "DeploymentUnits" : ["aws-lb-app-https"]
                                    }
                                },
                                "Engine" : "application",
                                "Logs" : true,
                                "Profiles" : {
                                    "Testing" : [ "Component" ]
                                },
                                "PortMappings" : {
                                    "https" : {
                                        "IPAddressGroups" : ["_global"],
                                        "Priority" : 500,
                                        "HostFilter" : true,
                                        "Certificate" : {
                                            "IncludeInHost" : {
                                                "Product" : false,
                                                "Environment" : true,
                                                "Segment" : false,
                                                "Tier" : false,
                                                "Component" : false,
                                                "Instance" : true,
                                                "Version" : false,
                                                "Host" : true
                                            },
                                            "Host" : "test"
                                        }
                                    },
                                    "httpredirect" : {
                                        "IPAddressGroups" : ["_global"],
                                        "Redirect" : {}
                                    }
                                }
                            }
                        }
                    }
                }
            },
            "TestCases" : {
                "httpslb" : {
                    "OutputSuffix" : "template",
                    "Structural" : {
                        "CFNResource" : {
                            "httpListenerRule" : {
                                "Name" : "listenerRuleXelbXhttpslbXhttpX100",
                                "Type" : "AWS::ElasticLoadBalancingV2::ListenerRule"
                            },
                            "httpListener" : {
                                "Name" : "listenerXelbXhttpslbXhttps",
                                "Type" : "AWS::ElasticLoadBalancingV2::Listener"
                            },
                            "loadBalancer" : {
                                "Name" : "albXelbXhttpslb",
                                "Type" : "AWS::ElasticLoadBalancingV2::LoadBalancer"
                            }
                        },
                        "Match" : {
                            "LBName" : {
                                "Path"  : "Resources.albXelbXhttpslb.Properties.Name",
                                "Value" : "mockedup-int-elb-httpslb"
                            },
                            "HTTPAction" : {
                                "Path" : "Resources.listenerRuleXelbXhttpslbXhttpX100.Properties.Actions[0].Type",
                                "Value" : "redirect"
                            },
                            "HTTPSAction" : {
                                "Path" : "Resources.listenerRuleXelbXhttpslbXhttpsX500.Properties.Actions[0].Type",
                                "Value" : "forward"
                            }
                        }
                    }
                }
            },
            "TestProfiles" : {
                "Component" : {
                    "lb" : {
                        "TestCases" : [ "httpslb" ]
                    }
                }
            }
        }
    /]
[/#macro]
