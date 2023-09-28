[#ftl]

[#-- Provides generic component macros --]
[#assign SHARED_COMPONENT_TYPE = "shared" ]

[#-- Known component types --]
[#assign ADAPTOR_COMPONENT_TYPE = "adaptor"]

[#assign APIGATEWAY_COMPONENT_TYPE = "apigateway"]
[#assign APIGATEWAY_USAGEPLAN_COMPONENT_TYPE = "apiusageplan"]
[#assign APIGATEWAY_COMPONENT_DOCS_EXTENSION = "docs"]

[#assign BACKUPSTORE_COMPONENT_TYPE = "backupstore"]
[#assign BACKUPSTORE_REGIME_COMPONENT_TYPE = "backupstoreregime" ]

[#assign BASELINE_COMPONENT_TYPE = "baseline" ]
[#assign BASELINE_DATA_COMPONENT_TYPE = "baselinedata" ]
[#assign BASELINE_KEY_COMPONENT_TYPE = "baselinekey" ]

[#assign BASTION_COMPONENT_TYPE = "bastion" ]

[#assign CACHE_COMPONENT_TYPE = "cache" ]

[#assign CDN_COMPONENT_TYPE = "cdn"]
[#assign CDN_ROUTE_COMPONENT_TYPE = "cdnroute" ]
[#assign CDN_ORIGIN_COMPONENT_TYPE = "cdnorigin" ]
[#assign CDN_CACHE_POLICY_COMPONENT_TYPE = "cdncachepolicy" ]
[#assign CDN_RESPONSE_POLICY_COMPONENT_TYPE = "cdnresponsepolicy" ]

[#assign CERTIFICATEAUTHORITY_COMPONENT_TYPE = "certificateauthority"]

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
[#assign CORRESPONDENT_CHANNEL_COMPONENT_TYPE = "correspondentchannel"]

[#assign DATACATALOG_COMPONENT_TYPE = "datacatalog"]
[#assign DATACATALOG_TABLE_COMPONENT_TYPE = "datacatalogtable"]

[#assign DATAFEED_COMPONENT_TYPE = "datafeed" ]

[#assign DATASET_COMPONENT_TYPE = "dataset"]

[#assign DATASTREAM_COMPONENT_TYPE = "datastream"]

[#assign DATAVOLUME_COMPONENT_TYPE = "datavolume" ]

[#assign DB_COMPONENT_TYPE = "db" ]
[@addLegacyComponentTypeMapping
    legacyType="rds"
    type=DB_COMPONENT_TYPE
/]

[#assign DB_PROXY_COMPONENT_TYPE = "dbproxy" ]

[#assign DOCDB_COMPONENT_TYPE = "docdb" ]

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

[#assign IMAGE_COMPONENT_TYPE = "image"]

[#assign INTERNALTEST_COMPONENT_TYPE = "internaltest" ]

[#assign LAMBDA_COMPONENT_TYPE = "lambda"]
[#assign LAMBDA_FUNCTION_COMPONENT_TYPE = "function"]

[#assign LB_COMPONENT_TYPE = "lb" ]
[#assign LB_PORT_COMPONENT_TYPE = "lbport" ]
[#assign LB_BACKEND_COMPONENT_TYPE = "lbbackend" ]

[@addLegacyComponentTypeMapping
    legacyType="alb"
    type=LB_COMPONENT_TYPE
/]

[#assign LOGSTORE_COMPONENT_TYPE = "logstore"]

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
