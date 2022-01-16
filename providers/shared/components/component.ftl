[#ftl]

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

[#assign CLIENTVPN_COMPONENT_TYPE = "clientvpn" ]

[#assign COMPUTECLUSTER_COMPONENT_TYPE = "computecluster"]

[#assign CONFIGSTORE_COMPONENT_TYPE = "configstore" ]
[#assign CONFIGSTORE_BRANCH_COMPONENT_TYPE = "configbranch"]

[#assign CONTAINERHOST_COMPONENT_TYPE="containerhost"]
[#assign CONTAINERSERVICE_COMPONENT_TYPE="containerservice"]
[#assign CONTAINERTASK_COMPONENT_TYPE="containertask"]

[#assign CONTENTHUB_HUB_COMPONENT_TYPE = "contenthub"]
[#assign CONTENTHUB_NODE_COMPONENT_TYPE = "contentnode"]

[#assign CORRESPONDENT_COMPONENT_TYPE = "correspondent"]

[#assign DATAFEED_COMPONENT_TYPE = "datafeed" ]

[#assign DATAPIPELINE_COMPONENT_TYPE = "datapipeline"]

[#assign DATASET_COMPONENT_TYPE = "dataset"]

[#assign DATAVOLUME_COMPONENT_TYPE = "datavolume" ]

[#assign DB_COMPONENT_TYPE = "db" ]
[@addLegacyComponentTypeMapping
    legacyType="rds"
    type=DB_COMPONENT_TYPE
/]

[#assign DIRECTORY_COMPONENT_TYPE = "directory" ]

[#assign EC2_COMPONENT_TYPE = "ec2"]

[#assign ECS_COMPONENT_TYPE = "ecs" ]
[#assign ECS_SERVICE_COMPONENT_TYPE = "service" ]
[#assign ECS_TASK_COMPONENT_TYPE = "task" ]

[#assign FILESHARE_COMPONENT_TYPE = "fileshare" ]
[#assign FILESHARE_MOUNT_COMPONENT_TYPE = "filesharemount"]

[@addLegacyComponentTypeMapping
    legacyType="efs"
    type=FILESHARE_COMPONENT_TYPE
/]

[@addLegacyComponentTypeMapping
    legacyType="efsmount"
    type=FILESHARE_MOUNT_COMPONENT_TYPE
/]

[#assign ES_COMPONENT_TYPE = "es"]

[@addLegacyComponentTypeMapping
    legacyType="elasticsearch"
    type=ES_COMPONENT_TYPE
/]

[#assign EXTERNALNETWORK_COMPONENT_TYPE = "externalnetwork" ]
[#assign EXTERNALNETWORK_CONNECTION_COMPONENT_TYPE = "externalnetworkconnection" ]

[#assign EXTERNALSERVICE_COMPONENT_TYPE = "externalservice" ]
[#assign EXTERNALSERVICE_ENDPOINT_COMPONENT_TYPE = "externalserviceendpoint" ]

[#assign FEDERATEDROLE_COMPONENT_TYPE = "federatedrole" ]
[#assign FEDERATEDROLE_ASSIGNMENT_COMPONENT_TYPE = "federatedroleassignment" ]

[#assign FILETRANSFER_COMPONENT_TYPE = "filetransfer"]

[#assign FIREWALL_COMPONENT_TYPE = "firewall"]
[#assign FIREWALL_RULE_COMPONENT_TYPE = "firewallrule"]
[#assign FIREWALL_DESTINATION_COMPONENT_TYPE = "firewalldestination"]

[#assign GLOBALDB_COMPONENT_TYPE = "globaldb" ]

[#assign HEALTHCHECK_COMPONENT_TYPE = "healthcheck" ]

[#assign HOSTING_PLATFORM_COMPONENT_TYPE = "hostingplatform"]

[#assign INTERNALTEST_COMPONENT_TYPE = "internaltest" ]

[#assign LAMBDA_COMPONENT_TYPE = "lambda"]
[#assign LAMBDA_FUNCTION_COMPONENT_TYPE = "function"]

[#assign LB_COMPONENT_TYPE = "lb" ]
[#assign LB_PORT_COMPONENT_TYPE = "lbport" ]

[@addLegacyComponentTypeMapping
    legacyType="alb"
    type=LB_COMPONENT_TYPE
/]

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

[#assign RUNBOOK_COMPONENT_TYPE = "runbook" ]
[#assign RUNBOOK_STEP_COMPONENT_TYPE = "runbookstep"]

[#assign S3_COMPONENT_TYPE = "s3" ]

[#assign SECRETSTORE_COMPONENT_TYPE = "secretstore" ]
[#assign SECRETSTORE_SECRET_COMPONENT_TYPE = "secret" ]

[#assign SERVICE_REGISTRY_COMPONENT_TYPE = "serviceregistry" ]
[#assign SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE = "serviceregistryservice" ]

[#assign SPA_COMPONENT_TYPE = "spa"]

[#assign SQS_COMPONENT_TYPE = "sqs"]

[#assign SUBSCRIPTION_COMPONENT_TYPE = "subscription"]

[#assign TEMPLATE_COMPONENT_TYPE = "template"]

[#assign TOPIC_COMPONENT_TYPE = "topic"]
[#assign TOPIC_SUBSCRIPTION_COMPONENT_TYPE = "topicsubscription" ]

[#assign USER_COMPONENT_TYPE = "user" ]

[#assign USERPOOL_COMPONENT_TYPE = "userpool"]
[#assign USERPOOL_CLIENT_COMPONENT_TYPE = "userpoolclient" ]
[#assign USERPOOL_AUTHPROVIDER_COMPONENT_TYPE = "userpoolauthprovider" ]
[#assign USERPOOL_RESOURCE_COMPONENT_TYPE = "userpoolresource" ]

[#assign DNS_ZONE_COMPONENT_TYPE = "dnszone"]

[#assign domainNameChildConfiguration = [
    {
        "Names" : "Domain",
        "Description" : "Explicit domain id which will override the product domain",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "IncludeInDomain",
        "Children" : [
            {
                "Names" : "Product",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Environment",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Segment",
                "Types" : BOOLEAN_TYPE
            }
        ]
    }
]]

[#assign hostNameChildConfiguration = [
    {
        "Names" : "Host",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "HostParts",
        "Types" : ARRAY_OF_STRING_TYPE
    },
    {
        "Names" : "IncludeInHost",
        "Children" : [
            {
                "Names" : "Product",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Environment",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Segment",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Tier",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Component",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Instance",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Version",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Host",
                "Types" : BOOLEAN_TYPE
            }
        ]
    }
]]

[#assign certificateChildConfiguration =
    [
        {
            "Names" : "Enabled",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        }
    ] +
    domainNameChildConfiguration +
    hostNameChildConfiguration +
    [
        {
            "Names" : "External",
            "Types" : BOOLEAN_TYPE
        },
        {
            "Names" : "Wildcard",
            "Types" : BOOLEAN_TYPE
        }
    ]
]

[#assign secretTemplateConfiguration = [
    {
        "Names" : "Generated",
        "Children" : [
            {
                "Names" : "Content",
                "Description" : "A JSON object which contains the nonsensitve parts of the secret",
                "Types" : OBJECT_TYPE,
                "Default" : {
                    "username" : "admin"
                }
            },
            {
                "Names" : "SecretKey",
                "Description" : "The key in the JSON secret to set the generated secret to",
                "Types" : STRING_TYPE,
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
                        "Types" : BOOLEAN_TYPE,
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
        "Types" : STRING_TYPE,
        "Values" : [ "user", "generated" ],
        "Default" : "user"
    },
    {
        "Names" : "Requirements",
        "Description" : "Format requirements for the Secret",
        "AttributeSet" : SECRETSTRING_ATTRIBUTESET_TYPE
    }
]]

[#assign containerHostAttributes = [
    {
        "Names" : [ "Extensions", "Fragment", "Container" ],
        "Description" : "Extensions to invoke as part of component processing",
        "Types" : ARRAY_OF_STRING_TYPE,
        "Default" : []
    },
    {
        "Names" : "FixedIP",
        "Types" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "LogDriver",
        "Types" : STRING_TYPE,
        "Values" : ["awslogs", "json-file", "fluentd"],
        "Default" : "awslogs"
    },
    {
        "Names" : "VolumeDrivers",
        "Types" : ARRAY_OF_STRING_TYPE,
        "Values" : [ "ebs" ],
        "Default" : []
    },
    {
        "Names" : "ClusterLogGroup",
        "Types" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "Links",
        "SubObjects": true,
        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "Profiles",
        "Children" :
            [
                {
                    "Names" : "ComputeProvider",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Storage",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Alert",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Network",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Logging",
                    "Description" : "profile to define where logs are forwarded to from this component",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "LogFile",
                    "Description" : "Defines the logfile profile which sets the log files to collect from the compute instance",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Bootstrap",
                    "Description" : "A profile to include additional bootstrap sources as part of the instance startup",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                }
            ]
    },
    {
        "Names" : "Permissions",
        "Children" : [
            {
                "Names" : "Decrypt",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "AsFile",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "AppData",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "AppPublic",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            }
        ]
    },
    {
        "Names" : "AutoScaling",
        "AttributeSet" : AUTOSCALEGROUP_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "HostScalingPolicies",
        "SubObjects" : true,
        "AttributeSet" : SCALINGPOLICY_ECS_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "DockerUsers",
        "SubObjects" : true,
        "Children" : [
            {
                "Names" : "UserName",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "UID",
                "Types" : NUMBER_TYPE,
                "Mandatory" : true
            }
        ]
    },
    {
        "Names" : "LogMetrics",
        "SubObjects" : true,
        "AttributeSet" : LOGMETRIC_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "Alerts",
        "SubObjects" : true,
        "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "Hibernate",
        "Children" : [
            {
                "Names" : "Enabled",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "StartUpMode",
                "Types" : STRING_TYPE,
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
        "Names" : "ComputeInstance",
        "Description" : "Configuration of compute instances used in the component",
        "Children" : [
            {
                "Names" : "ManagementPorts",
                "Description" : "The network ports used for remote management of the instance",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "ssh" ]
            },
            {
                "Names" : "Image",
                "Description" : "Configures the source of the virtual machine image used for the instance",
                "AttributeSet" : ECS_COMPUTEIMAGE_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "OperatingSystem",
                "Description" : "The operating system details of the compute instance",
                "AttributeSet" : OPERATINGSYSTEM_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "OSPatching",
                "Description" : "Configuration for scheduled OS Patching",
                "AttributeSet" : OSPATCHING_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "ComputeTasks",
                "Description" : "Customisation to setup the compute instance from its image",
                "Children" : [
                    {
                        "Names" : "Extensions",
                        "Description" : "A list of extensions to source boostrap tasks from",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    },
                    {
                        "Names" : "UserTasksRequired",
                        "Description" : "A list of compute task types which must be accounted for in extensions on top of the component tasks",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    }
                ]
            }
        ]
    }
]]

[#assign containerServiceAttributes = [
    {
        "Names" : "Engine",
        "Description" : "The engine used to run the container",
        "Types" : STRING_TYPE,
        "Values" : [ "ec2" ],
        "Default" : "ec2"
    },
    {
        "Names" : "Containers",
        "SubObjects" : true,
        "AttributeSet" : CONTTAINERTASK_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "DesiredCount",
        "Types" : NUMBER_TYPE
    },
    {
        "Names" : "ScalingPolicies",
        "SubObjects" : true,
        "AttributeSet" : SCALINGPOLICY_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "UseTaskRole",
        "Types" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "Permissions",
        "Children" : [
            {
                "Names" : "Decrypt",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AsFile",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AppData",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AppPublic",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            }
        ]
    },
    {
        "Names" : "TaskLogGroup",
        "Types" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "LogMetrics",
        "SubObjects" : true,
        "AttributeSet" : LOGMETRIC_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "Alerts",
        "SubObjects" : true,
        "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "NetworkMode",
        "Types" : STRING_TYPE,
        "Values" : ["none", "bridge", "host"],
        "Default" : ""
    },
    {
        "Names" : "ContainerNetworkLinks",
        "Types" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "Placement",
        "Children" : [
            {
                "Names" : "Strategy",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Values" : [
                    "spread-multiAZ",
                    "spread-instance",
                    "binpack-cpu",
                    "binpack-memory",
                    "daemon",
                    "random"
                ],
                "Description" : "How to place containers on the cluster",
                "Default" : []
            },
            {
                "Names" : "DistinctInstance",
                "Types" : BOOLEAN_TYPE,
                "Description" : "Each task is running on a different container instance when true",
                "Default" : true
            },
            {
                "Names" : "ComputeProvider",
                "Description" : "The compute provider placement policy",
                "Children" : [
                    {
                        "Names" : "Default",
                        "Children" : [
                            {
                                "Names" : "Provider",
                                "Description" : "The default container compute provider - _engine uses the default provider of the engine",
                                "Types"  : STRING_TYPE,
                                "Values" : [ "_engine" ],
                                "Default" : "_engine"
                            },
                            {
                                "Names" : "Weight",
                                "Types" : NUMBER_TYPE,
                                "Description" : "The ratio of containers allocated to the provider based on the configured providers",
                                "Default" : 1
                            },
                            {
                                "Names" : "RequiredCount",
                                "Description" : "The minimum count of containers to run on the default provider",
                                "Types" : NUMBER_TYPE,
                                "Default" : 1
                            }
                        ]
                    },
                    {
                        "Names" : "Additional",
                        "Description" : "Providers who will meet the additional compute capacity outside of the default",
                        "SubObjects" : true,
                        "Children" : [
                            {
                                "Names" : "Provider",
                                "Types" : STRING_TYPE,
                                "Values" : [ "_engine" ],
                                "Mandatory" : true
                            },
                            {
                                "Names" : "Weight",
                                "Types" : NUMBER_TYPE,
                                "Description" : "The ratio of containers allocated to the provider based on the configured providers",
                                "Default" : 1
                            }
                        ]
                    }
                ]
            }
        ]
    },
    {
        "Names" : "Profiles",
        "Children" :
            [
                {
                    "Names" : "Alert",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Network",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Logging",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                }
            ]
    },
    {
        "Names" : "Links",
        "SubObjects": true,
        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
    }
]]

[#assign containerTaskAttributes = [
    {
        "Names" : "Engine",
        "Description" : "The engine used to run the container",
        "Types" : STRING_TYPE,
        "Values" : [ "ec2" ],
        "Default" : "ec2"
    },
    {
        "Names" : "Containers",
        "SubObjects" : true,
        "AttributeSet" : CONTTAINERTASK_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "UseTaskRole",
        "Types" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "Permissions",
        "Children" : [
            {
                "Names" : "Decrypt",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AsFile",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AppData",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AppPublic",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            }
        ]
    },
    {
        "Names" : "TaskLogGroup",
        "Types" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "LogMetrics",
        "SubObjects" : true,
        "AttributeSet" : LOGMETRIC_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "Alerts",
        "SubObjects" : true,
        "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "NetworkMode",
        "Types" : STRING_TYPE,
        "Values" : ["none", "bridge", "host"],
        "Default" : ""
    },
    {
        "Names" : "FixedName",
        "Types" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "Schedules",
        "SubObjects" : true,
        "Children" : [
            {
                "Names" : "Enabled",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Expression",
                "Types" : STRING_TYPE,
                "Default" : "rate(1 hours)"
            },
            {
                "Names" : "TaskCount",
                "Description" : "The number of tasks to run on the schedule",
                "Types" : NUMBER_TYPE,
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
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Network",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Logging",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                }
            ]
    },
    {
        "Names" : "Links",
        "SubObjects": true,
        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
    }
]]
