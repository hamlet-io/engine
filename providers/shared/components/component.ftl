[#ftl]

[#-- Legacy type mappings --]
[#assign legacyTypeMapping = {} ]

[#-- Provides generic component macros --]
[#assign SHARED_COMPONENT_TYPE = "shared" ]

[#-- Known component types --]
[#assign ADAPTOR_COMPONENT_TYPE = "adaptor"]

[#assign APIGATEWAY_COMPONENT_TYPE = "apigateway"]
[#assign APIGATEWAY_USAGEPLAN_COMPONENT_TYPE = "apiusageplan"]
[#assign APIGATEWAY_COMPONENT_DOCS_EXTENSION = "docs"]

[#assign BASELINE_COMPONENT_TYPE = "baseline" ]
[#assign BASELINE_DATA_COMPONENT_TYPE = "baselinedata" ]
[#assign BASELINE_KEY_COMPONENT_TYPE = "baselinekey" ]

[#assign BASTION_COMPONENT_TYPE = "bastion" ]

[#assign CACHE_COMPONENT_TYPE = "cache" ]

[#assign CDN_COMPONENT_TYPE = "cdn"]
[#assign CDN_ROUTE_COMPONENT_TYPE = "cdnroute" ]

[#assign COMPUTECLUSTER_COMPONENT_TYPE = "computecluster"]

[#assign CONFIGSTORE_COMPONENT_TYPE = "configstore" ]
[#assign CONFIGSTORE_BRANCH_COMPONENT_TYPE = "configbranch"]

[#assign CONTAINERHOST_COMPONENT_TYPE="containerhost"]
[#assign CONTAINERSERVICE_COMPONENT_TYPE="containerservice"]
[#assign CONTAINERTASK_COMPONENT_TYPE="containertask"]

[#assign CONTENTHUB_HUB_COMPONENT_TYPE = "contenthub"]
[#assign CONTENTHUB_NODE_COMPONENT_TYPE = "contentnode"]

[#assign DATAFEED_COMPONENT_TYPE = "datafeed" ]

[#assign DATAPIPELINE_COMPONENT_TYPE = "datapipeline"]

[#assign DATASET_COMPONENT_TYPE = "dataset"]

[#assign DATAVOLUME_COMPONENT_TYPE = "datavolume" ]

[#assign DB_COMPONENT_TYPE = "db" ]
[#assign DB_LEGACY_COMPONENT_TYPE = "rds" ]
[#assign legacyTypeMapping += { DB_LEGACY_COMPONENT_TYPE : DB_COMPONENT_TYPE } ]

[#assign EC2_COMPONENT_TYPE = "ec2"]

[#assign ECS_COMPONENT_TYPE = "ecs" ]
[#assign ECS_SERVICE_COMPONENT_TYPE = "service" ]
[#assign ECS_TASK_COMPONENT_TYPE = "task" ]

[#assign EFS_COMPONENT_TYPE = "efs" ]
[#assign EFS_MOUNT_COMPONENT_TYPE = "efsmount"]

[#assign ES_COMPONENT_TYPE = "es"]
[#assign ES_LEGACY_COMPONENT_TYPE = "elasticsearch"]
[#assign legacyTypeMapping += { ES_LEGACY_COMPONENT_TYPE : ES_COMPONENT_TYPE } ]

[#assign EXTERNALNETWORK_COMPONENT_TYPE = "externalnetwork" ]
[#assign EXTERNALNETWORK_CONNECTION_COMPONENT_TYPE = "externalnetworkconnection" ]

[#assign EXTERNALSERVICE_COMPONENT_TYPE = "externalservice" ]
[#assign EXTERNALSERVICE_ENDPOINT_COMPONENT_TYPE = "externalserviceendpoint" ]

[#assign FEDERATEDROLE_COMPONENT_TYPE = "federatedrole" ]
[#assign FEDERATEDROLE_ASSIGNMENT_COMPONENT_TYPE = "federatedroleassignment" ]

[#assign FILETRANSFER_COMPONENT_TYPE = "filetransfer"]

[#assign GLOBALDB_COMPONENT_TYPE = "globaldb" ]

[#assign LAMBDA_COMPONENT_TYPE = "lambda"]
[#assign LAMBDA_FUNCTION_COMPONENT_TYPE = "function"]

[#assign LB_COMPONENT_TYPE = "lb" ]
[#assign LB_PORT_COMPONENT_TYPE = "lbport" ]
[#assign LB_LEGACY_COMPONENT_TYPE = "alb" ]
[#assign legacyTypeMapping += { LB_LEGACY_COMPONENT_TYPE : LB_COMPONENT_TYPE } ]

[#assign MOBILEAPP_COMPONENT_TYPE = "mobileapp"]

[#assign MOBILENOTIFIER_COMPONENT_TYPE = "mobilenotifier" ]
[#assign MOBILENOTIFIER_PLATFORM_COMPONENT_TYPE = "mobilenotifierplatform" ]

[#assign MTA_COMPONENT_TYPE = "mta"]
[#assign MTA_RULE_COMPONENT_TYPE = "mtarule" ]

[#assign NETWORK_ACL_COMPONENT_TYPE = "networkacl"]
[#assign NETWORK_COMPONENT_TYPE = "network" ]

[#assign NETWORK_GATEWAY_COMPONENT_TYPE = "gateway"]
[#assign NETWORK_GATEWAY_DESTINATION_COMPONENT_TYPE = "gatewaydestination"]

[#assign NETWORK_ROUTE_TABLE_COMPONENT_TYPE = "networkroute"]

[#assign NETWORK_ROUTER_COMPONENT_TYPE = "router"]
[#assign NETWORK_ROUTER_STATIC_ROUTE_COMPONENT_TYPE = "routerstaticroute" ]

[#assign OBJECTSQL_COMPONENT_TYPE = "objectsql"]

[#assign PRIVATE_SERVICE_COMPONENT_TYPE = "privateservice" ]

[#assign QUEUEHOST_COMPONENT_TYPE = "queuehost" ]

[#assign S3_COMPONENT_TYPE = "s3" ]

[#assign SECRETSTORE_COMPONENT_TYPE = "secretstore" ]
[#assign SECRETSTORE_SECRET_COMPONENT_TYPE = "secret" ]

[#assign SERVICE_REGISTRY_COMPONENT_TYPE = "serviceregistry" ]
[#assign SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE = "serviceregistryservice" ]

[#assign SPA_COMPONENT_TYPE = "spa"]

[#assign SQS_COMPONENT_TYPE = "sqs"]

[#assign TEMPLATE_COMPONENT_TYPE = "template"]

[#assign TOPIC_COMPONENT_TYPE = "topic"]
[#assign TOPIC_SUBSCRIPTION_COMPONENT_TYPE = "topicsubscription" ]

[#assign USER_COMPONENT_TYPE = "user" ]

[#assign USERPOOL_COMPONENT_TYPE = "userpool"]
[#assign USERPOOL_CLIENT_COMPONENT_TYPE = "userpoolclient" ]
[#assign USERPOOL_AUTHPROVIDER_COMPONENT_TYPE = "userpoolauthprovider" ]
[#assign USERPOOL_RESOURCE_COMPONENT_TYPE = "userpoolresource" ]

[#assign
    filterChildrenConfiguration = [
        {
            "Names" : "Any",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Tenant",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Product",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Environment",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Segment",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Tier",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Component",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : ["Function"],
            "Type" : STRING_TYPE
        },
        {
            "Names" : ["Service"],
            "Type" : STRING_TYPE
        },
        {
            "Names" : ["Task"],
            "Type" : STRING_TYPE
        },
        {
            "Names" : ["PortMapping", "Port"],
            "Type" : STRING_TYPE
        },
        {
            "Names" : ["Mount"],
            "Type" : STRING_TYPE
        },
        {
            "Names" : ["Platform"],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "RouteTable" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "NetworkACL" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "DataBucket" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Key" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Branch" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Client" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Connection" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "AuthProvider" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Resource" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "DataFeed" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "RegistryService" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Assignment" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Route" ],
            "Type"  : STRING_TYPE
        },
        {
            "Names" : [ "Endpoint" ],
            "Type"  : STRING_TYPE
        },
        {
            "Names" : "Instance",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Version",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Secret",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Rule",
            "Type" : STRING_TYPE
        }
    ]
]

[#assign
    linkChildrenConfiguration =
        filterChildrenConfiguration +
        [
            {
                "Names" : "Role",
                "Type" : STRING_TYPE
            },
            {
                "Names" : "Direction",
                "Type" : STRING_TYPE
            },
            {
                "Names" : "Type",
                "Type" : STRING_TYPE
            },
            {
                "Names" : "Enabled",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "IncludeInContext",
                "Type" : ARRAY_OF_STRING_TYPE
            }
        ]
]

[#assign
    logWatcherChildrenConfiguration = [
        {
            "Names" : "LogFilter",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Links",
            "Subobjects" : true,
            "Children" : linkChildrenConfiguration
        }
    ]
]

[#assign logMetricChildrenConfiguration = [
        {
            "Names" : "LogFilter",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
]

[#assign alertChildrenConfiguration =
    [
        {
            "Names" : "Namespace",
            "Type" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "DimensionSource",
            "Description" : "The source of the alert dimensions - resource lookup or explicit configuration",
            "Type" : STRING_TYPE,
            "Values" : [ "Resource", "Configured" ],
            "Default" : "Resource"
        },
        {
            "Names" : "Resource",
            "Description" : "Provide a component resource to determine the dimensions of the metric",
            "Children" : [
                {
                    "Names" : "Id",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Type",
                    "Type" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Dimensions",
            "Description" : "Explicit configured dimensions",
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "Key",
                    "Description" : "The Key of the dimension",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Value",
                    "Description" : "The value of the dimension to match",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "SettingEnvName",
                    "Description" : "A setting name as env that will provide the dimension value",
                    "Type": STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Metric",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Statistic",
            "Type" : STRING_TYPE,
            "Default" : "Sum"
        },
        {
            "Names" : "Description",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Name",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Threshold",
            "Type" : NUMBER_TYPE,
            "Default" : 1
        },
        {
            "Names" : "Severity",
            "Type" : STRING_TYPE,
            "Values" : [ "debug", "info", "warn", "error", "fatal"],
            "Default" : "info"
        },
        {
            "Names" : "Comparison",
            "Type" : STRING_TYPE,
            "Default" : "Threshold"
        },
        {
            "Names" : "Operator",
            "Type" : STRING_TYPE,
            "Default" : "GreaterThanOrEqualToThreshold"
        },
        {
            "Names" : "Time",
            "Type" : NUMBER_TYPE,
            "Default" : 300
        },
        {
            "Names" : "Periods",
            "Type" : NUMBER_TYPE,
            "Default" : 1
        },
        {
            "Names" : "ReportOk",
            "Type" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "MissingData",
            "Type" : STRING_TYPE,
            "Default" : "notBreaching"
        },
        {
            "Names" : "Unit",
            "Type" : STRING_TYPE,
            "Default" : "Count"
        }
    ]
]

[#assign scalingPolicyChildrenConfiguration =
    [
        {
            "Names" : "Type",
            "Type" : STRING_TYPE,
            "Values" : [ "Stepped", "Tracked", "Scheduled" ],
            "Default" : "Stepped"
        },
        {
            "Names" : "Cooldown",
            "Description" : "Cooldown time ( seconds ) after a scaling event has occurred before another event can be triggered",
            "Children" : [
                {
                    "Names" : "ScaleIn",
                    "Type" : NUMBER_TYPE,
                    "Default" : 300
                },
                {
                    "Names" : "ScaleOut",
                    "Type" : NUMBER_TYPE,
                    "Default" : 600
                }
            ]
        },
        {
            "Names" : "TrackingResource",
            "Description" : "The resource metric used to trigger scaling",
            "Children" : [
                {
                    "Names" : "Link",
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "MetricTrigger",
                    "Children" : alertChildrenConfiguration
                }
            ]
        },
        {
            "Names" : "Stepped",
            "Children" : [
                {
                    "Names" : "MetricAggregation",
                    "Description" : "The method used to agregate the cloudwatch metric",
                    "Type" : STRING_TYPE,
                    "Values" : [ "Average", "Minimum", "Maximum" ],
                    "Default" : "Average"
                },
                {
                    "Names" : "CapacityAdjustment",
                    "Description" : "How to scale when the policy is triggered",
                    "Type" : STRING_TYPE,
                    "Values" : [ "Change", "Exact", "Percentage" ],
                    "Default" : "Change"
                },
                {
                    "Names" : "MinAdjustment",
                    "Description" : "When minimum scale adjustment value to apply when triggered",
                    "Type" : NUMBER_TYPE,
                    "Default" : -1
                },
                {
                    "Names" : "Adjustments",
                    "Description" : "The adjustments to apply at each step",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "LowerBound",
                            "Description" : "The lower bound for the difference between the alarm threshold and the metric",
                            "Type" : NUMBER_TYPE
                        },
                        {
                            "Names" : "UpperBound",
                            "Description" : "The upper bound for the difference between the alarm threshold and the metric",
                            "Type" : NUMBER_TYPE
                        },
                        {
                            "Names" : "AdjustmentValue",
                            "Description" : "The value to apply when the adjustment step is triggered",
                            "Type" : NUMBER_TYPE,
                            "Default" : 1
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "Tracked",
            "Children" : [
                {
                    "Names" : "TargetValue",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "ScaleInEnabled",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "RecommendedMetric",
                    "Description" : "Use a recommended (predefined) metric for scaling",
                    "Type" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Scheduled",
            "Children" : [
                {
                    "Names" : "ProcessorProfile",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Schedule",
                    "Type" : STRING_TYPE
                }
            ]
        }
    ]
]

[#assign lbChildConfiguration = [
        {
            "Names" : "Tier",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Component",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "LinkName",
            "Type" : STRING_TYPE,
            "Default" : "lb"
        },
        {
            "Names" : "Instance",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Version",
            "Type" : STRING_TYPE
        },
        {
            "Names" : ["PortMapping", "Port"],
            "Type" : STRING_TYPE,
            "Default" : ""
        }
    ]
]

[#assign srvRegChildConfiguration = [
        {
            "Names" : "Tier",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Component",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "LinkName",
            "Type" : STRING_TYPE,
            "Default" : "srvreg"
        },
        {
            "Names" : "Instance",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Version",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "RegistryService",
            "Type" : STRING_TYPE
        }
    ]
]

[#assign wafChildConfiguration = [
        {
            "Names" : "IPAddressGroups",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "CountryGroups",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "OWASP",
            "Type" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "Logging",
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                }
            ]
        },
        {
            "Names" : "Profiles",
            "Children" : [
                {
                    "Names" : "Logging",
                    "Description" : "Logging profile to process WAF Logs that are stored in the OpsData DataBucket.",
                    "Type"  : STRING_TYPE,
                    "Default" : "waf"
                }
            ]
        },
        {
            "Names" : "RateLimits",
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "IPAddressGroups",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Limit",
                    "Type" : NUMBER_TYPE,
                    "Mandatory" : true
                }
            ]
        }
    ]
]

[#assign settingsChildConfiguration = [
        {
            "Names" : "AsFile",
            "Type" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "Json",
            "Children" : [
                {
                    "Names" : "Escaped",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Prefix",
                    "Type" : STRING_TYPE,
                    "Values" : ["json", ""],
                    "Default" : "json"
                }
            ]
        }
    ]
]

[#assign autoScalingChildConfiguration = [
    {
        "Names" : "DetailedMetrics",
        "Type" : BOOLEAN_TYPE,
        "Default" : true,
        "Description" : "Enable the collection of autoscale group detailed metrics"
    },
    {
        "Names" : "WaitForSignal",
        "Type" : BOOLEAN_TYPE,
        "Default" : true,
        "Description" : "Wait for a cfn-signal before treating the instances as alive"
    },
    {
        "Names" : "MinUpdateInstances",
        "Type" : NUMBER_TYPE,
        "Default" : 1,
        "Description" : "The minimum number of instances which must be available during an update"
    },
    {
        "Names" : "MinSuccessInstances",
        "Type" : NUMBER_TYPE,
        "Description" : "The minimum percantage of instances that must sucessfully update",
        "Default" : 75
    },
    {
        "Names" : "ReplaceCluster",
        "Type" : BOOLEAN_TYPE,
        "Default" : false,
        "Description" : "When set to true a brand new cluster will be built, if false the instances in the current cluster will be replaced"
    },
    {
        "Names" : "UpdatePauseTime",
        "Type" : STRING_TYPE,
        "Default" : "10M",
        "Description" : "How long to pause betweeen updates of instances"
    },
    {
        "Names" : "StartupTimeout",
        "Type" : STRING_TYPE,
        "Default" : "15M",
        "Description" : "How long to wait for a cfn-signal to be received from a host"
    },
    {
        "Names" : "AlwaysReplaceOnUpdate",
        "Type" : BOOLEAN_TYPE,
        "Default" : false,
        "Description" : "Replace instances on every update action"
    },
    {
        "Names" : "ActivityCooldown",
        "Type" : NUMBER_TYPE,
        "Default" : 30
    }
]]

[#assign domainNameChildConfiguration = [
    {
        "Names" : "Qualifiers",
        "Type" : OBJECT_TYPE
    },
    {
        "Names" : "Domain",
        "Type" : STRING_TYPE
    },
    {
        "Names" : "IncludeInDomain",
        "Children" : [
            {
                "Names" : "Product",
                "Type" : BOOLEAN_TYPE
            },
            {
                "Names" : "Environment",
                "Type" : BOOLEAN_TYPE
            },
            {
                "Names" : "Segment",
                "Type" : BOOLEAN_TYPE
            }
        ]
    }
]]

[#assign hostNameChildConfiguration = [
    {
        "Names" : "Host",
        "Type" : STRING_TYPE
    },
    {
        "Names" : "HostParts",
        "Type" : ARRAY_OF_STRING_TYPE
    },
    {
        "Names" : "IncludeInHost",
        "Children" : [
            {
                "Names" : "Product",
                "Type" : BOOLEAN_TYPE
            },
            {
                "Names" : "Environment",
                "Type" : BOOLEAN_TYPE
            },
            {
                "Names" : "Segment",
                "Type" : BOOLEAN_TYPE
            },
            {
                "Names" : "Tier",
                "Type" : BOOLEAN_TYPE
            },
            {
                "Names" : "Component",
                "Type" : BOOLEAN_TYPE
            },
            {
                "Names" : "Instance",
                "Type" : BOOLEAN_TYPE
            },
            {
                "Names" : "Version",
                "Type" : BOOLEAN_TYPE
            },
            {
                "Names" : "Host",
                "Type" : BOOLEAN_TYPE
            }
        ]
    }
]]

[#assign certificateChildConfiguration =
    domainNameChildConfiguration +
    hostNameChildConfiguration +
    [
        {
            "Names" : "Qualifiers",
            "Type" : OBJECT_TYPE
        },
        {
            "Names" : "External",
            "Type" : BOOLEAN_TYPE
        },
        {
            "Names" : "Wildcard",
            "Type" : BOOLEAN_TYPE
        }
    ]
]

[#assign pathChildConfiguration = [
    {
        "Names" : "Host",
        "Type" : STRING_TYPE,
        "Default" : ""
    },
    {
        "Names" : "Style",
        "Type" : STRING_TYPE,
        "Default" : "single"
    },
    {
        "Names" : "IncludeInPath",
        "Children" : [

            {
                "Names" : "Product",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Environment",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Solution",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Segment",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Tier",
                "Type" : BOOLEAN_TYPE,
                "Default": false
            },
            {
                "Names" : "Component",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Instance",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Version",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Host",
                "Type" : BOOLEAN_TYPE,
                "Default": false
            }
        ]
    }

]]

[#assign s3NotificationChildConfiguration = [
    {
        "Names" : "Links",
        "Subobjects" : true,
        "Children" : linkChildrenConfiguration
    },
    {
        "Names" : "Prefix",
        "Type" : STRING_TYPE
    },
    {
        "Names" : "Suffix",
        "Type" : STRING_TYPE
    },
    {
        "Names" : "Events",
        "Type" : ARRAY_OF_STRING_TYPE,
        "Default" : [ "create" ],
        "Values" : [ "create", "delete", "restore", "reducedredundancy" ]
    },
    {
        "Names" : "aws:QueuePermissionMigration",
        "Description" : "Deprecation alert: set to true once policy updated for queue",
        "Type" : BOOLEAN_TYPE,
        "Default" : false
    }
]]

[#assign s3EncryptionChildConfiguration = [
    {
        "Names" : "Enabled",
        "Description" : "Enable at rest encryption",
        "Type" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "EncryptionSource",
        "Type" : STRING_TYPE,
        "Description" : "The encryption service to use - LocalService = S3, EncryptionService = native encryption service (kms)",
        "Values" : [ "EncryptionService", "LocalService" ],
        "Default" : "EncryptionService"
    }
]]

[#assign dynamoDbTableChildConfiguration = [
    {
        "Names" : "Billing",
        "Description" : "The billing mode for the table",
        "Type"  : STRING_TYPE,
        "Values" : [ "provisioned", "per-request" ],
        "Default" : "provisioned"
    },
    {
        "Names" : "Encrypted",
        "Description" : "Enable at rest encryption",
        "Type" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "Capacity",
        "Children" : [
            {
                "Names" : "Read",
                "Description" : "When using provisioned billing the maximum RCU of the table",
                "Type" : NUMBER_TYPE,
                "Default" : 1
            },
            {
                "Names" : "Write",
                "Description" : "When using provisioned billing the maximum WCU of the table",
                "Type" : NUMBER_TYPE,
                "Default" : 1
            }
        ]
    },
    {
        "Names" : "Backup",
        "Children" : [
            {
                "Names" : "Enabled",
                "Description" : "Enables point in time recovery on the table",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            }
        ]
    },
    {
        "Names" : "Stream",
        "Children" : [
            {
                "Names" : "Enabled",
                "Description" : "Enables dynamodb event stream",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "ViewType",
                "Type" : STRING_TYPE,
                "Values" : [ "KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES" ],
                "Default" : "NEW_IMAGE"
            }
        ]
    }
]]


[#assign secretTemplateConfiguration = [
    {
        "Names" : "Generated",
        "Children" : [
            {
                "Names" : "Content",
                "Description" : "A JSON object which contains the nonsensitve parts of the secret",
                "Type" : OBJECT_TYPE,
                "Default" : {
                    "username" : "admin"
                }
            },
            {
                "Names" : "SecretKey",
                "Description" : "The key in the JSON secret to set the generated secret to",
                "Type" : STRING_TYPE,
                "Default" : "password"
            }
        ]
    }
]]

[#assign secretRotationConfiguration = [
    {
        "Names" : "Lifecycle",
        "Description" : "The lifecycle for a given Secret.",
        "Children" : [
            {
                "Names" : "Rotation",
                "Description" : "The Secret rotation schedule, in number of days - accepts rate() or cron() formats.",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Description" : "Enable Secret rotation.",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : false
                    }
                ]
            }
        ]
    }
]]

[#assign secretConfiguration = [
    {
        "Names" : "Source",
        "Type" : STRING_TYPE,
        "Values" : [ "user", "generated" ],
        "Default" : "user"
    },
    {
        "Names" : "Requirements",
        "Description" : "Format requirements for the Secret",
        "Children" : [
            {
                "Names" : "MinLength",
                "Description" : "The minimum character length",
                "Type" : NUMBER_TYPE,
                "Default" : 20
            },
            {
                "Names" : "MaxLength",
                "Description" : "The maximum character length",
                "Type" : NUMBER_TYPE,
                "Default" : 30
            },
            {
                "Names" : "IncludeUpper",
                "Description" : "Include upper-case characters",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "IncludeLower",
                "Description" : "Include lower-case characters",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "IncludeSpecial",
                "Description" : "Include special characters",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "IncludeNumber",
                "Description" : "Include numbers characters",
                "Type" : BOOLEAN_TYPE,
                "Default": true
            },
            {
                "Names" : "ExcludedCharacters",
                "Description" : "Characters that must be excluded",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : [ r'"', r"'", r'$', r'@', r'/', r'\' ]
            },
            {
                "Names" : "RequireAllIncludedTypes",
                "Description" : "Require at least one of each included type",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            }
        ]
    }
    ]
]

[#assign networkRuleChildConfiguration = [
    {
        "Names" : "Ports",
        "Description" : "A list of port ids from the Ports reference",
        "Type" : ARRAY_OF_STRING_TYPE,
        "Default" : []
    },
    {
        "Names" : "IPAddressGroups",
        "Description" : "A list of IP Address groups ids from the IPAddressGroups reference",
        "Type" : ARRAY_OF_STRING_TYPE,
        "Default" : []
    },
    {
        "Names" : "SecurityGroups",
        "Description" : "A list of security groups or ids - for internal use only",
        "Type" : ARRAY_OF_STRING_TYPE,
        "Default" : []
    },
    {
        "Names" : "Description",
        "Description" : "A description that will be applied to the rule",
        "Type" : STRING_TYPE,
        "Default" : ""
    }
]]

[#assign containerChildrenConfiguration = [
    {
        "Names" : [ "Extensions", "Fragment", "Container" ],
        "Description" : "Extensions to invoke as part of component processing",
        "Type" : ARRAY_OF_STRING_TYPE,
        "Default" : []
    },
    {
        "Names" : "Cpu",
        "Type" : NUMBER_TYPE,
        "Default" : ""
    },
    {
        "Names" : "Links",
        "Subobjects" : true,
        "Children" : linkChildrenConfiguration
    },
    {
        "Names" : "LocalLogging",
        "Type" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "LogDriver",
        "Type" : STRING_TYPE,
        "Values" : ["awslogs", "json-file", "fluentd"],
        "Default" : "awslogs"
    },
    {
        "Names" : "LogMetrics",
        "Subobjects" : true,
        "Children" : logMetricChildrenConfiguration
    },
    {
        "Names" : "Alerts",
        "Subobjects" : true,
        "Children" : alertChildrenConfiguration
    },
    {
        "Names" : "ContainerLogGroup",
        "Type" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "RunCapabilities",
        "Type" : ARRAY_OF_STRING_TYPE,
        "Default" : []
    },
    {
        "Names" : "Privileged",
        "Type" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : ["MaximumMemory", "MemoryMaximum", "MaxMemory"],
        "Types" : NUMBER_TYPE,
        "Description" : "Set to 0 to not set a maximum"
    },
    {
        "Names" : ["MemoryReservation", "Memory", "ReservedMemory"],
        "Type" : NUMBER_TYPE,
        "Mandatory" : true
    },
    {
        "Names" : "Ports",
        "Subobjects" : true,
        "Children" : [
            "Container",
            {
                "Names" : "DynamicHostPort",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "LB",
                "Children" : lbChildConfiguration
            },
            {
                "Names" : "Registry",
                "Children" : srvRegChildConfiguration
            },
            {
                "Names" : "IPAddressGroups",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            }
        ]
    },
    {
        "Names" : "Image",
        "Description" : "Set the source of the components image",
        "Children" : [
            {
                "Names" : "Source",
                "Description" : "The source of the image",
                "Type" : STRING_TYPE,
                "Mandatory" : true,
                "Values" : [ "registry", "containerregistry" ],
                "Default" : "Registry"
            },
            {
                "Names" : "Source:containerregistry",
                "Description" : "A docker container registry to source the image from",
                "Children" : [
                    {
                        "Names" : "Image",
                        "Description" : "The docker image that you want to use",
                        "Type" : STRING_TYPE
                    }
                ]
            }
        ]
    },
    {
        "Names" : "Version",
        "Type" : STRING_TYPE,
        "Description" : "Override the version from the deployment unit",
        "Default" : ""
    },
    {
        "Names" : "ContainerNetworkLinks",
        "Type" : ARRAY_OF_STRING_TYPE,
        "Default" : []
    }
    {
        "Names" : "Profiles",
        "Children" :
            [
                {
                    "Names" : "Alert",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                }
            ]
    },
    {
        "Names" : "RunMode",
        "Description" : "A per container setting which can be used by the app to determine run mode for a container in a task - defaults to the second half of a dash separated id",
        "Type" : STRING_TYPE,
        "Default" : ""
    },
    {
        "Names" : "Ulimits",
        "Description" : "Linux OS based limits for the container",
        "Subobjects" : true,
        "Children" : [
            {
                "Names" : "Name",
                "Description" : "The name of the ulimit to apply",
                "Type" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "HardLimit",
                "Description" : "The OS level hard limit to apply",
                "Type" : NUMBER_TYPE,
                "Default" : 1024
            },
            {
                "Names" : "SoftLimit",
                "Description" : "The User level limit to apply",
                "Type" : NUMBER_TYPE,
                "Default" : 1024
            }
        ]
    }
]]

[#assign containerHostAttributes = [
    {
        "Names" : [ "Extensions", "Fragment", "Container" ],
        "Description" : "Extensions to invoke as part of component processing",
        "Type" : ARRAY_OF_STRING_TYPE,
        "Default" : []
    },
    {
        "Names" : "FixedIP",
        "Type" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "LogDriver",
        "Type" : STRING_TYPE,
        "Values" : ["awslogs", "json-file", "fluentd"],
        "Default" : "awslogs"
    },
    {
        "Names" : "VolumeDrivers",
        "Type" : ARRAY_OF_STRING_TYPE,
        "Values" : [ "ebs" ],
        "Default" : []
    },
    {
        "Names" : "ClusterLogGroup",
        "Type" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "Links",
        "Subobjects" : true,
        "Children" : linkChildrenConfiguration
    },
    {
        "Names" : "Profiles",
        "Children" :
            [
                {
                    "Names" : "ComputeProvider",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Processor",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Alert",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Network",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Logging",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                }
            ]
    },
    {
        "Names" : "AutoScaling",
        "Children" : autoScalingChildConfiguration
    },
    {
        "Names" : "HostScalingPolicies",
        "Subobjects" : true,
        "Children" : [
            {
                "Names" : "Type",
                "Type" : STRING_TYPE,
                "Values" : [ "Stepped", "Tracked", "Scheduled", "ComputeProvider" ],
                "Default" : "ComputeProvider"
            },
            {
                "Names" : "ComputeProvider",
                "Children": [
                    {
                        "Names" : "MinAdjustment",
                        "Description" : "The minimum instances to update during scaling activities",
                        "Type" : NUMBER_TYPE,
                        "Default" : 1
                    },
                    {
                        "Names" : "MaxAdjustment",
                        "Description" : "The maximum instances to  update during scaling activities",
                        "Type" : NUMBER_TYPE,
                        "Default" : 10000
                    },
                    {
                        "Names" : "TargetCapacity",
                        "Description" : "The target usage of the autoscale group to maintain as a percentage",
                        "Type" : NUMBER_TYPE,
                        "Default" : 90
                    },
                    {
                        "Names" : "ManageTermination",
                        "Description" : "Alow the computer provider to manage when instances will be terminated",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ] + scalingPolicyChildrenConfiguration
            }
        ]
    },
    {
        "Names" : "DockerUsers",
        "Subobjects" : true,
        "Children" : [
            {
                "Names" : "UserName",
                "Type" : STRING_TYPE
            },
            {
                "Names" : "UID",
                "Type" : NUMBER_TYPE,
                "Mandatory" : true
            }
        ]
    },
    {
        "Names" : "LogMetrics",
        "Subobjects" : true,
        "Children" : logMetricChildrenConfiguration
    },
    {
        "Names" : "Alerts",
        "Subobjects" : true,
        "Children" : alertChildrenConfiguration
    },
    {
        "Names" : "Hibernate",
        "Children" : [
            {
                "Names" : "Enabled",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "StartUpMode",
                "Type" : STRING_TYPE,
                "Values" : ["replace"],
                "Default" : "replace"
            }
        ]
    },
    {
        "Names" : "Role",
        "Types" : STRING_TYPE,
        "Description" : "Server configuration role",
        "Default" : ""
    },
    {
        "Names" : "OSPatching",
        "Children" : osPatchingChildConfiguration
    }
]]

[#assign containerServiceAttributes = [
    {
        "Names" : "Containers",
        "Subobjects" : true,
        "Children" : containerChildrenConfiguration
    },
    {
        "Names" : "DesiredCount",
        "Type" : NUMBER_TYPE
    },
    {
        "Names" : "ScalingPolicies",
        "Subobjects" : true,
        "Children" : scalingPolicyChildrenConfiguration
    },
    {
        "Names" : "UseTaskRole",
        "Type" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "Permissions",
        "Children" : [
            {
                "Names" : "Decrypt",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AsFile",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AppData",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AppPublic",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            }
        ]
    },
    {
        "Names" : "TaskLogGroup",
        "Type" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "LogMetrics",
        "Subobjects" : true,
        "Children" : logMetricChildrenConfiguration
    },
    {
        "Names" : "Alerts",
        "Subobjects" : true,
        "Children" : alertChildrenConfiguration
    },
    {
        "Names" : "NetworkMode",
        "Type" : STRING_TYPE,
        "Values" : ["none", "bridge", "awsvpc", "host"],
        "Default" : ""
    },
    {
        "Names" : "ContainerNetworkLinks",
        "Type" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "Placement",
        "Children" : [
            {
                "Names" : "Strategy",
                "Type" : STRING_TYPE,
                "Values" : [ "", "daemon"],
                "Description" : "How to place containers on the cluster",
                "Default" : ""
            },
            {
                "Names" : "DistinctInstance",
                "Type" : BOOLEAN_TYPE,
                "Description" : "Each task is running on a different container instance when true",
                "Default" : true
            }
        ]
    },
    {
        "Names" : "Profiles",
        "Children" :
            [
                {
                    "Names" : "Alert",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Processor",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Network",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Logging",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                }
            ]
    },
    {
        "Names" : "Links",
        "Subobjects" : true,
        "Children" : linkChildrenConfiguration
    }
]]

[#assign containerTaskAttributes = [
    {
        "Names" : "Engine",
        "Type" : STRING_TYPE,
        "Values" : [ "ec2", "fargate" ],
        "Default" : "ec2"
    },
    {
        "Names" : "Containers",
        "Subobjects" : true,
        "Children" : containerChildrenConfiguration
    },
    {
        "Names" : "UseTaskRole",
        "Type" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "Permissions",
        "Children" : [
            {
                "Names" : "Decrypt",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AsFile",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AppData",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AppPublic",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            }
        ]
    },
    {
        "Names" : "TaskLogGroup",
        "Type" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "LogMetrics",
        "Subobjects" : true,
        "Children" : logMetricChildrenConfiguration
    },
    {
        "Names" : "Alerts",
        "Subobjects" : true,
        "Children" : alertChildrenConfiguration
    },
    {
        "Names" : "NetworkMode",
        "Type" : STRING_TYPE,
        "Values" : ["none", "bridge", "awsvpc", "host"],
        "Default" : ""
    },
    {
        "Names" : "FixedName",
        "Type" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "Schedules",
        "Subobjects" : true,
        "Children" : [
            {
                "Names" : "Expression",
                "Type" : STRING_TYPE,
                "Default" : "rate(1 hours)"
            },
            {
                "Names" : "TaskCount",
                "Description" : "The number of tasks to run on the schedule",
                "Type" : NUMBER_TYPE,
                "Default" : 1
            }
        ]
    },
    {
        "Names" : "Profiles",
        "Children" :
            [
                {
                    "Names" : "Alert",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Network",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Logging",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                }
            ]
    },
    {
        "Names" : "Links",
        "Subobjects" : true,
        "Children" : linkChildrenConfiguration
    }
]]

[#-- Not for general use - framework only --]
[#assign coreProfileChildConfiguration = [
    {
        "Names" : ["Profiles"],
        "Children" : [
            {
                "Names" : "Deployment",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Policy",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Placement",
                "Type" : STRING_TYPE,
                "Default" : "default"
            },
            {
                "Names" : "Baseline",
                "Description" : "The profile used to lookup standard services provided by the segment baseline",
                "Type" : STRING_TYPE,
                "Default" : "default"
            },
            {
                "Names" : "Testing",
                "Description" : "The testing profiles to apply to the component",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            }
        ]
    }
] ]

[#assign coreSettingsNamespacesConfiguration = [
    {
        "Names" : [ "SettingNamespaces" ],
        "Description" : "Additional namespaces to use during settings lookups",
        "Subobjects" : true,
        "Children" : [
            {
                "Names" : "Match",
                "Description" : "How to match the namespace with available settings",
                "Type" : STRING_TYPE,
                "Values" : [ "exact", "partial" ],
                "Default" : "exact"
            },
            {
                "Names" : "Order",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : [
                    "Tier",
                    "Component",
                    "Type",
                    "SubComponent",
                    "Instance",
                    "Version",
                    "Name"
                ]
            },
            {
                "Names" : "IncludeInNamespace",
                "Children" : [
                    {
                        "Names" : "Tier",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Component",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Type",
                        "Type"  : BOOLEAN_TYPE,
                        "Default" : false
                    }
                    {
                        "Names" : "SubComponent",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "Instance",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Version",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Name",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : false
                    }
                ]
            },
            {
                "Names" : "Name",
                "Type" : STRING_TYPE,
                "Default" : ""
            }
        ]
    }
]]

[#assign tracingChildConfiguration =
    [
        {
            "Names" : "Mode",
            "Type" : STRING_TYPE,
            "Values" : ["active", "passthrough"]
        }
    ]
]
