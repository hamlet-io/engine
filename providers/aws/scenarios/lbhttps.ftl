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
                        "Exists" : [
                            "Outputs.securityGroupXlistenerXelbXhttpslbXhttps"
                        ],
                        "Match" : {
                            "LBName" : {
                                "Path"  : "Resources.albXelbXhttpslb.Properties.Name",
                                "Value" : "mockedup-int-elb-httpslb"
                            },
                            "HTTPAction" : {
                                "Path" : "Resources.listenerRuleXelbXhttpslbXhttpX100.Properties.Actions[0]",
                                "Value" : {
                                    "Type": "redirect",
                                    "RedirectConfig": {
                                        "Protocol": "HTTPS",
                                        "Port": "443",
                                        "Host": "#\{host}",
                                        "Path": "/#\{path}",
                                        "Query": "#\{query}",
                                        "StatusCode": "HTTP_301"
                                    }
                                }
                            },
                            "HTTPSAction" : {
                                "Path" : "Resources.listenerRuleXelbXhttpslbXhttpsX500.Properties.Actions[0].Type",
                                "Value" : "forward"
                            }
                        },
                        "Length" : {
                            "listenerActions" : {
                                "Path" : "Resources.listenerRuleXelbXhttpslbXhttpX100.Properties.Actions",
                                "Count" : 1
                            }
                        },
                        "NotEmpty" : [
                            "Resources.listenerRuleXelbXhttpslbXhttpX100.Properties.Priority"
                        ]
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
