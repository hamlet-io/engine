[#ftl]

[#-- Get stack output --]
[#macro awstest_scenario_lb ]

    [#-- HTTPS Load Balancer --]
    [@addScenario
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
                    "OutputSuffix" : "template.json",
                    "Structural" : {
                        "CFN" : {
                            "Resource" : {
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
                            "Output" : [
                                "securityGroupXlistenerXelbXhttpslbXhttps",
                                "listenerRuleXelbXhttpslbXhttpsX500",
                                "tgXdefaultXelbXhttpslbXhttps"
                            ]
                        },
                        "JSON" : {
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
                "validation" : {
                    "OutputSuffix" : "template.json",
                    "Tools" : {
                        "CFNLint" : true,
                        "CFNNag" : true
                    }
                }
            },
            "TestProfiles" : {
                "Component" : {
                    "lb" : {
                        "TestCases" : [ "httpslb", "validation" ]
                    }
                }
            }
        }
    /]
[/#macro]
