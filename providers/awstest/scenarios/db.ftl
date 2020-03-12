[#ftl]

[#-- Get stack output --]
[#macro awstest_scenario_db ]

    [#-- Base database setup --]
    [@addScenario
        settingSets=[
            {
                "Type" : "Settings",
                "Scope" : "Products",
                "Namespace" : "mockedup-integration-aws-db-postgres-base",
                "Settings" : {
                    "MASTER_USERNAME" : "testUser",
                    "MASTER_PASSWORD" : "testPassword"
                }
            }
        ]
        blueprint={
            "Tiers" : {
                "db" : {
                    "Components" : {
                        "postgresdbbase" : {
                            "db" : {
                                "Instances" : {
                                    "default" : {
                                        "DeploymentUnits" : ["aws-db-postgres-base"]
                                    }
                                },
                                "Engine" : "postgres",
                                "EngineVersion" : "11",
                                "Profiles" : {
                                    "Testing" : [ "postgresdbbase" ]
                                }
                            }
                        }
                    }
                }
            },
            "TestCases" : {
                "postgresdbbase" : {
                    "OutputSuffix" : "template.json",
                    "Structural" : {
                        "CFN" : {
                            "Resource" : {
                                "rdsInstance" : {
                                    "Name" : "rdsXdbXpostgresdbbase",
                                    "Type" : "AWS::RDS::DBInstance"
                                },
                                "rdsOptionGroup" : {
                                    "Name" : "rdsOptionGroupXdbXpostgresdbbaseXpostgres11",
                                    "Type" : "AWS::RDS::OptionGroup"
                                },
                                "rdsParameterGroup" : {
                                    "Name" : "rdsParameterGroupXdbXpostgresdbbaseXpostgres11",
                                    "Type" : "AWS::RDS::DBParameterGroup"
                                }
                            },
                            "Output" : [
                                "rdsXdbXpostgresdbbaseXdns",
                                "rdsXdbXpostgresdbbaseXport",
                                "securityGroupXdbXpostgresdbbase"
                            ]
                        },
                        "JSON" : {
                            "Match" : {
                                "RDSEngine" : {
                                    "Path"  : "Resources.rdsXdbXpostgresdbbase.Properties.Engine",
                                    "Value" : "postgres"
                                },
                                "RDSEngineVersion" : {
                                    "Path"  : "Resources.rdsXdbXpostgresdbbase.Properties.EngineVersion",
                                    "Value" : "11"
                                },
                                "OptionGroupVersion" : {
                                    "Path" : "Resources.rdsOptionGroupXdbXpostgresdbbaseXpostgres11.Properties.MajorEngineVersion",
                                    "Value" : "11"
                                },
                                "ParameterGroupVersion" : {
                                    "Path" : "Resources.rdsParameterGroupXdbXpostgresdbbaseXpostgres11.Properties.Family",
                                    "Value" : "postgres11"
                                }
                            },
                            "NotEmpty" : [
                                "Resources.rdsXdbXpostgresdbbase.Properties.DBInstanceClass"
                            ]
                        }
                    }
                }
            },
            "TestProfiles" : {
                "postgresdbbase" : {
                    "db" : {
                        "TestCases" : [ "postgresdbbase" ]
                    }
                }
            }
        }
    /]


    [#-- Generated creds --]
    [@addScenario
        blueprint={
            "Tiers" : {
                "db" : {
                    "Components" : {
                        "postgresdbgenerated" : {
                            "db" : {
                                "Instances" : {
                                    "default" : {
                                        "DeploymentUnits" : ["aws-db-postgres-generated"]
                                    }
                                },
                                "Engine" : "postgres",
                                "EngineVersion" : "11",
                                "Profiles" : {
                                    "Testing" : [ "postgresdbgenerated" ]
                                },
                                "GenerateCredentials" : {
                                    "Enabled" : true,
                                    "EncryptionScheme" : "kms"
                                }
                            }
                        }
                    }
                }
            },
            "TestCases" : {
                "postgresdbgenerated" : {
                    "OutputSuffix" : "template.json",
                    "Structural" : {
                        "CFN" : {
                            "Resource" : {
                                "rdsInstance" : {
                                    "Name" : "rdsXdbXpostgresdbgenerated",
                                    "Type" : "AWS::RDS::DBInstance"
                                }
                            },
                            "Output" : [
                                "rdsXdbXpostgresdbgeneratedXdns",
                                "rdsXdbXpostgresdbgeneratedXport"
                            ]
                        }
                    }
                }
            },
            "TestProfiles" : {
                "postgresdbgenerated" : {
                    "db" : {
                        "TestCases" : [ "postgresdbgenerated" ]
                    }
                }
            }
        }
    /]
[/#macro]
