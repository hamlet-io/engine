[#ftl]

[#-- Known component types --]

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

[#assign CONTENTHUB_HUB_COMPONENT_TYPE = "contenthub"]
[#assign CONTENTHUB_NODE_COMPONENT_TYPE = "contentnode"]

[#assign DATAFEED_COMPONENT_TYPE = "datafeed" ]

[#assign DATAPIPELINE_COMPONENT_TYPE = "datapipeline"]

[#assign DATASET_COMPONENT_TYPE = "dataset"]

[#assign DATAVOLUME_COMPONENT_TYPE = "datavolume" ]

[#assign DB_COMPONENT_TYPE = "db" ]
[#assign DB_LEGACY_COMPONENT_TYPE = "rds" ]

[#assign EC2_COMPONENT_TYPE = "ec2"]

[#assign ECS_COMPONENT_TYPE = "ecs" ]
[#assign ECS_SERVICE_COMPONENT_TYPE = "service" ]
[#assign ECS_TASK_COMPONENT_TYPE = "task" ]

[#assign EFS_COMPONENT_TYPE = "efs" ]
[#assign EFS_MOUNT_COMPONENT_TYPE = "efsMount"]

[#assign ES_COMPONENT_TYPE = "es"]
[#assign ES_LEGACY_COMPONENT_TYPE = "elasticsearch"]

[#assign FEDERATEDROLE_COMPONENT_TYPE = "federatedrole" ]
[#assign FEDERATEDROLE_ASSIGNMENT_COMPONENT_TYPE = "federatedroleassignment" ]

[#assign LAMBDA_COMPONENT_TYPE = "lambda"]
[#assign LAMBDA_FUNCTION_COMPONENT_TYPE = "function"]

[#assign LB_COMPONENT_TYPE = "lb" ]
[#assign LB_PORT_COMPONENT_TYPE = "lbport" ]
[#assign LB_LEGACY_COMPONENT_TYPE = "alb" ]

[#assign MOBILEAPP_COMPONENT_TYPE = "mobileapp"]

[#assign MOBILENOTIFIER_COMPONENT_TYPE = "mobilenotifier" ]
[#assign MOBILENOTIFIER_PLATFORM_COMPONENT_TYPE = "mobilenotiferplatform" ]

[#assign NETWORK_ACL_COMPONENT_TYPE = "networkacl"]
[#assign NETWORK_COMPONENT_TYPE = "network" ]
[#assign NETWORK_GATEWAY_COMPONENT_TYPE = "gateway"]
[#assign NETWORK_GATEWAY_DESTINATION_COMPONENT_TYPE = "gatewaydestination"]
[#assign NETWORK_ROUTE_TABLE_COMPONENT_TYPE = "networkroute"]

[#assign S3_COMPONENT_TYPE = "s3" ]

[#assign SERVICE_REGISTRY_COMPONENT_TYPE = "serviceregistry" ]
[#assign SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE = "serviceregistryservice" ]

[#assign SPA_COMPONENT_TYPE = "spa"]

[#assign SQS_COMPONENT_TYPE = "sqs"]

[#assign TOPIC_COMPONENT_TYPE = "topic"]
[#assign TOPIC_SUBSCRIPTION_COMPONENT_TYPE = "topicsubscription" ]

[#assign USER_COMPONENT_TYPE = "user" ]

[#assign USERPOOL_COMPONENT_TYPE = "userpool"]
[#assign USERPOOL_CLIENT_COMPONENT_TYPE = "userpoolclient" ]
[#assign USERPOOL_AUTHPROVIDER_COMPONENT_TYPE = "userpoolauthprovider" ]

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
            "Names" : [ "AuthProvider" ],
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
            "Names" : "Instance",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Version",
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
            "Names" : "Resource",
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
            "Default" : "Step"
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
                    "Type" : "NUMBER_TYPE",
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
            "Mandatory" : true
        },
        {
            "Names" : "OWASP",
            "Type" : BOOLEAN_TYPE,
            "Default" : false
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
        "Type" : STRING_TYPE,
        "Default" : ""
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
                "Names" : "Placement",
                "Type" : STRING_TYPE,
                "Default" : "default"
            },
            {
                "Names" : "Baseline",
                "Description" : "The profile used to lookup standard services provided by the segment baseline",
                "Type" : STRING_TYPE,
                "Default" : "default"
            }
        ]
    }
] ]
