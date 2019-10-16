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
                                        "DeploymentUnits" : ["https-lb"]
                                    }
                                },
                                "Engine" : "application",
                                "Logs" : true,
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
            }
        }
    /]
[/#macro]
