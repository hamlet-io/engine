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
                        "CFNResource" : [
                            "AWS::ElasticLoadBalancingV2::LoadBalancer",
                            "AWS::ElasticLoadBalancingV2::ListenerRule",
                            "AWS::ElasticLoadBalancingV2::Listener",
                            "AWS::ElasticLoadBalancingV2::TargetGroup",
                            "AWS::EC2::SecurityGroup"
                        ],
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
