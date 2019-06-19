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

[#assign COMPUTECLUSTER_COMPONENT_TYPE = "computecluster"]

[#assign CONFIGSTORE_COMPONENT_TYPE = "configstore" ]
[#assign CONFIGSTORE_BRANCH_COMPONENT_TYPE = "configbranch"]

[#assign CONTENTHUB_HUB_COMPONENT_TYPE = "contenthub"]
[#assign CONTENTHUB_NODE_COMPONENT_TYPE = "contentnode"]

[#assign DATAFEED_COMPONENT_TYPE = "datafeed" ]

[#assign DATAPIPELINE_COMPONENT_TYPE = "datapipeline"]

[#assign DATASET_COMPONENT_TYPE = "dataset"]

[#assign DATAVOLUME_COMPONENT_TYPE = "datavolume" ]

[#assign EC2_COMPONENT_TYPE = "ec2"]

[#assign ECS_COMPONENT_TYPE = "ecs" ]
[#assign ECS_SERVICE_COMPONENT_TYPE = "service" ]
[#assign ECS_TASK_COMPONENT_TYPE = "task" ]

[#assign EFS_COMPONENT_TYPE = "efs" ]
[#assign EFS_MOUNT_COMPONENT_TYPE = "efsMount"]

[#assign ES_COMPONENT_TYPE = "es"]
[#assign ES_LEGACY_COMPONENT_TYPE = "elasticsearch"]

[#assign NETWORK_GATEWAY_COMPONENT_TYPE = "gateway"]
[#assign NETWORK_GATEWAY_DESTINATION_COMPONENT_TYPE = "gatewaydestination"]

[#assign LAMBDA_COMPONENT_TYPE = "lambda"]
[#assign LAMBDA_FUNCTION_COMPONENT_TYPE = "function"]

[#assign LB_COMPONENT_TYPE = "lb" ]
[#assign LB_PORT_COMPONENT_TYPE = "lbport" ]
[#assign LB_LEGACY_COMPONENT_TYPE = "alb" ]

[#assign MOBILEAPP_COMPONENT_TYPE = "mobileapp"]

[#assign MOBILENOTIFIER_COMPONENT_TYPE = "mobilenotifier" ]
[#assign MOBILENOTIFIER_PLATFORM_COMPONENT_TYPE = "mobilenotiferplatform" ]

[#assign NETWORK_COMPONENT_TYPE = "network" ]
[#assign NETWORK_ROUTE_TABLE_COMPONENT_TYPE = "networkroute"]
[#assign NETWORK_ACL_COMPONENT_TYPE = "networkacl"]

[#assign RDS_COMPONENT_TYPE = "rds" ]

[#assign S3_COMPONENT_TYPE = "s3" ]

[#assign SERVICE_REGISTRY_COMPONENT_TYPE = "serviceregistry" ]
[#assign SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE = "serviceregistryservice" ]

[#assign SPA_COMPONENT_TYPE = "spa"]

[#assign SQS_COMPONENT_TYPE = "sqs"]

[#assign USER_COMPONENT_TYPE = "user" ]

[#assign USERPOOL_COMPONENT_TYPE = "userpool"]
[#assign USERPOOL_CLIENT_COMPONENT_TYPE = "userpoolclient" ]
[#assign USERPOOL_AUTHPROVIDER_COMPONENT_TYPE = "userpoolauthprovider" ]

[#assign FEDERATEDROLE_COMPONENT_TYPE = "federatedrole" ]
[#assign FEDERATEDROLE_ASSIGNMENT_COMPONENT_TYPE = "federatedroleassignment" ]

[#-- Component configuration is extended dynamically by each component type --]
[#assign componentConfiguration = {} ]

[#-- Resource Groups --]
[#assign DEFAULT_RESOURCE_GROUP = "default"]
[#assign DNS_RESOURCE_GROUP = "dns"]

[#-- Attributes are shared across providers, or provider specific --]
[#assign SHARED_ATTRIBUTES = "shared"]

[#-- Placement profiles --]
[#assign DEFAULT_PLACEMENT_PROFILE = "default"]

[#-- Helper macro - not for general use --]
[#macro mergeComponentConfiguration type configuration]
    [#assign componentConfiguration =
        mergeObjects(
            componentConfiguration,
            {
                type: configuration
            }
        )
    ]
[/#macro]

[#-- Macros to assemble the component configuration --]
[#macro addComponent type properties attributes dependencies=[] ]
    [@mergeComponentConfiguration
        type=type
        configuration=
            {
                "Properties" : asArray(properties)
            } +
            attributeIfContent("Dependencies", dependencies, asArray(dependencies))
    /]
    [#-- Default resource group --]
    [@addResourceGroupInformation
        type=type
        attributes=attributes
        provider=SHARED_ATTRIBUTES
        resourceGroup=DEFAULT_RESOURCE_GROUP
    /]
[/#macro]

[#macro addChildComponent type properties attributes parent childAttribute linkAttributes dependencies=[] ]
    [@addComponent
        type=type
        properties=properties
        attributes=attributes
        dependencies=dependencies
    /]

    [#local children =
        ((componentConfiguration[parent].Components)![]) +
        [
            {
                "Type" : type,
                "Component" : childAttribute,
                "Link" : asArray(linkAttributes)
            }
        ]
    ]
    [@mergeComponentConfiguration
        type=parent
        configuration=
            {
                "Components" : children
            }
    /]
[/#macro]

[#macro addResourceGroupInformation type attributes provider resourceGroup services=[] ]
    [#-- Special processing for profiles --]
    [#if
        (provider == SHARED_ATTRIBUTES) &&
        (resourceGroup == DEFAULT_RESOURCE_GROUP) ]
        [#local extendedAttributes = [] ]
        [#local profileAttribute = coreProfileChildConfiguration[0] ]
        [#list attributes as attribute ]
            [#if asArray(attribute.Names!attribute.Name)?seq_contains("Profiles")]
                [#local profileAttribute +=
                        {
                            "Children" :
                                profileAttribute.Children +
                                attribute.Children
                        }
                    ] ]
            [#else]
                [#local extendedAttributes += [attribute] ]
            [/#if]
        [/#list]
        [#local extendedAttributes +=
            [profileAttribute] +
            coreComponentChildConfiguration ]
    [/#if]
    [@mergeComponentConfiguration
        type=type
        configuration=
            {
                "ResourceGroups" : {
                    resourceGroup : {
                        "Attributes" : {
                            provider :
                                asArray(extendedAttributes!attributes)
                        } +
                        valueIfContent(
                            {
                                "Services" : {
                                    provider : asArray(services)
                                }
                            },
                            services
                        )
                    }
                }
            }
    /]
[/#macro]

[#function getComponentDependencies type]
    [#return (componentConfiguration[type].Dependencies)![] ]
[/#function]

[#function getComponentResourceGroups type]
    [#return (componentConfiguration[type].ResourceGroups)!{} ]
[/#function]

[#function getComponentChildren type]
    [#return (componentConfiguration[type].Components)![] ]
[/#function]

[#function getResourceGroupPlacement key profile]
    [#return profile[key]!{} ]
[/#function]

[#-- Include files once - ignore if not present --]
[#macro includeFiles files ]
    [#list files as file]
        [#local filename = file?join("/") + ".ftl" ]
        [@cfDebug
            mode=listMode!""
            value="Checking for template " + filename + "..."
            enabled=false
        /]
        [#if includeTemplate(filename, true)]
            [@cfDebug
                mode=listMode!""
                value="Loaded template " + filename
                enabled=false
            /]
        [/#if]
    [/#list]
[/#macro]

[#-- Look up shared component definition --]
[#macro includeSharedComponentConfiguration type ]
    [@includeFiles
        files=
            [
                ["shared", type],
                ["shared", "component", type]
            ]
    /]
[/#macro]

[#-- Look up provider service definitions --]
[#-- General hierarchy is provider;service;deploymentFramework;level --]
[#macro includeServiceConfiguration provider service deploymentFramework ]
    [#local files = [] ]

    [#-- Support a variety of layouts depending on user preference --]

    [#-- aws/services/eip.ftl --]
    [#local files += [[provider, "service", service]] ]
    [#-- aws/services/eip/eip.ftl --]
    [#local files += [[provider, "service", service, service]] ]
    [#-- aws/services/eip/cf.ftl --]
    [#local files += [[provider, "service", service, deploymentFramework]] ]

    [#list ["id", "name", "policy", "resource"] as level]
        [#-- aws/services/eip/id.ftl --]
        [#local files += [[provider, "service", service, level]] ]
        [#-- aws/services/eip/cf/id.ftl --]
        [#local files += [[provider, "service", service, deploymentFramework, level]] ]
    [/#list]
    [@includeFiles files=files /]
[/#macro]

[#-- Look up resource group definition --]
[#-- General hierarchy is provider;component;resourceGroup;deploymentFramework;level --]
[#macro includeResourceGroupConfiguration component provider resourceGroup deploymentFramework services]
    [#local files = [] ]

    [#-- Support a variety of layouts depending on user preference --]

    [#-- Provider wide definitions --]
    [#-- aws/aws.ftl --]
    [#local files += [[provider, provider]] ]
    [#-- aws/component/component.ftl --]
    [#local files += [[provider, "component", "component" ]] ]
    [#-- aws/resourcegroup/resourcegroup.ftl --]
    [#local files += [[provider, "resourcegroup", "resourcegroup" ]] ]
    [#-- aws/service/service.ftl --]
    [#local files += [[provider, "service", "service" ]] ]

    [#-- Service based hierarchy --]

    [#-- services the resource group depends on     --]
    [#list services as service]
        [@includeServiceConfiguration
            provider=provider
            service=service
            deploymentFramework=deploymentFramework
        /]
    [/#list]

    [#-- Component based hierarchy --]

    [#-- aws/component/lb.ftl --]
    [#local files += [[provider, "component", component ]] ]
    [#-- aws/component/lb/lb.ftl --]
    [#local files += [[provider, "component", component, component]] ]

    [#-- aws/component/lb/lb-lb.ftl --]
    [#local files += [[provider, "component", component, resourceGroup]] ]
    [#-- aws/component/lb/lb-lb/cf.ftl --]
    [#local files += [[provider, "component", component, resourceGroup, deploymentFramework]] ]

    [#-- Component specific deployment framework definition --]
    [#-- aws/component/lb/cf.ftl --]
    [#local files += [[provider, "component", component, deploymentFramework]] ]
    [#-- aws/component/lb/cf/lb-lb.ftl --]
    [#local files += [[provider, "component", component, deploymentFramework, resourceGroup]] ]

    [#-- Resource group based hierarchy --]

    [#-- mainly for shared resource groups --]
    [#if resourceGroup != DEFAULT_RESOURCE_GROUP ]
        [#-- aws/resourcegroup/lb-lb.ftl --]
        [#local files += [[provider, "resourcegroup", resourceGroup]] ]
        [#-- aws/resourcegroup/lb-lb/cf.ftl --]
        [#local files += [[provider, "resourcegroup", resourceGroup, deploymentFramework]] ]
    [/#if]

    [#list ["id", "name", "setup", "state"] as level]
        [#-- aws/component/lb/id.ftl --]
        [#local files += [[provider, "component", component, level]] ]
        [#-- aws/component/lb/lb-lb/id.ftl --]
        [#local files += [[provider, "component", component, resourceGroup, level]] ]
        [#-- aws/component/lb/lb-lb/cf/id.ftl --]
        [#local files += [[provider, "component", component, resourceGroup, deploymentFramework, level]] ]

        [#if resourceGroup != DEFAULT_RESOURCE_GROUP ]
            [#-- aws/resourcegroup/lb-lb/id.ftl --]
            [#local files += [[provider, "resourcegroup", resourceGroup, level]] ]
            [#-- aws/resourcegroup/lb-lb/cf/id.ftl --]
            [#local files += [[provider, "resourcegroup", resourceGroup, deploymentFramework, level]] ]
        [/#if]
    [/#list]

    [#-- Legacy naming for transition --]
    [#-- TODO(mfl): Remove when transition complete --]
    [#list ["segment", "solution"] as level]
        [#-- aws/component/segment/segment_lb.ftl --]
        [#local files += [[provider, "component", level, level + "_" + component]] ]
    [/#list]

    [@includeFiles files=files /]

[/#macro]

[#macro includeComponentConfiguration component placements={} profile={} ignore=[] ]
    [#-- Determine the component type --]
    [#local type = component]
    [#if component?is_hash]
        [#local type = getComponentType(component)]
    [/#if]

    [#-- Ensure the share configuration is loaded --]
    [@includeSharedComponentConfiguration type=type /]

    [#-- Load static dependencies                                                 --]
    [#-- In general, these shouldn't be needed as link processing will generally  --]
    [#-- pick up most dependencies. However, if code uses definitions from a link --]
    [#-- component type or its resources, then a static dependency may be needed  --]
    [#-- to avoid errors when code is parsed as part of being included.           --]
    [#--                                                                          --]
    [#-- TODO(mfl): reassess this as direct dependency on a resource definitions  --]
    [#-- is bad as it is assuming the provider of the target                      --]
    [#list getComponentDependencies(type) as dependency]
        [#-- Ignore circular references --]
        [#if !(asArray(ignore)?seq_contains(dependency)) ]
            [@includeComponentConfiguration
                component=dependency
                ignore=(asArray(ignore) + [type])
            /]
        [/#if]
    [/#list]

    [#list getComponentResourceGroups(type)?keys as key]
        [#local placement={} ]
        [#if placements?has_content]
            [#local placement = (placements[key].Placement)!placements[key]!{} ]
        [/#if]
        [#if !placement?has_content]
            [#local placement = getResourceGroupPlacement(key, profile)]
        [/#if]
        [#-- TODO(mfl) Replace when use of includeComponentConfiguration in setContext is fixed --]
        [#if !placement?has_content]
            [#local placement = getResourceGroupPlacement(key, placementProfiles[DEFAULT_PLACEMENT_PROFILE])]
        [/#if]
        [@includeResourceGroupConfiguration
            component=type
            provider=placement.Provider
            resourceGroup=key
            deploymentFramework=placement.DeploymentFramework
            services=(value.Services[placement.Provider])![] + [type]
        /]
    [/#list]
[/#macro]

[#function invokeComponentMacro occurrence resourceGroup levels=[] parent={} ]
    [#local placement = (occurrence.State.ResourceGroups[resourceGroup].Placement)!{} ]
    [#if placement?has_content]
        [#local macroOptions = [] ]
            [#list asArray(levels) as level]
                [#if level?has_content]
                    [#local macroOptions +=
                        [
                            [placement.Provider, occurrence.Core.Type, resourceGroup, placement.DeploymentFramework, level],
                            [placement.Provider, occurrence.Core.Type, placement.DeploymentFramework, level],
                            [placement.Provider, resourceGroup, placement.DeploymentFramework, level]
                        ]]
                [#else]
                    [#local macroOptions +=
                        [
                            [placement.Provider, occurrence.Core.Type, resourceGroup, placement.DeploymentFramework],
                            [placement.Provider, occurrence.Core.type, placement.DeploymentFramework],
                            [placement.Provider, resourceGroup, placement.DeploymentFramework]
                        ]]
                [/#if]
            [/#list]
        [#list macroOptions as macroOption]
            [#local macro = macroOption?join("_")]
            [#if (.vars[macro]!"")?is_directive]
                [#if parent?has_content]
                    [@(.vars[macro])
                        occurrence=occurrence
                        parent=parent /]
                [#else]
                    [@(.vars[macro])
                        occurrence=occurrence /]
                [/#if]
                [#return true]
            [#else]
                [@cfDebug
                    mode=listMode
                    value="Unable to invoke macro " + macro
                    enabled=false
                /]
            [/#if]
        [/#list]
    [/#if]
    [#return false]
[/#function]

[#macro processComponents level=""]
    [#list tiers as tier]
        [#list (tier.Components!{})?values as component]
            [#if deploymentRequired(component, deploymentUnit)]
                [#assign componentTemplates = {} ]
                [#assign dashboardRows = []]
                [#assign multiAZ = component.MultiAZ!solnMultiAZ]
                [#list requiredOccurrences(
                    getOccurrences(tier, component),
                    deploymentUnit,
                    true) as occurrence]
                    [@cfDebug
                        mode=listMode
                        value=occurrence
                        enabled=false
                    /]
                    [#list occurrence.State.ResourceGroups as key,value]
                        [#if invokeComponentMacro(
                                occurrence,
                                key,
                                ["setup", level]) ]
                            [@cfDebug
                                mode=listMode
                                value="Processing " + tier.Id + "/" + component.Id + "/" + key + " ..."
                                enabled=false
                            /]
                        [/#if]
                    [/#list]
                [/#list]
            [/#if]
        [/#list]
    [/#list]
[/#macro]


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
        }
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

[#assign alertChildrenConfiguration = [
        "Description",
        {
            "Names" : "Name",
            "Type" : STRING_TYPE,
            "Mandatory" : true
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
            "Names" : "Threshold",
            "Type" : NUMBER_TYPE,
            "Default" : 1
        },
        {
            "Names" : "Severity",
            "Type" : STRING_TYPE,
            "Default" : "Info"
        },
        {
            "Names" : "Namespace",
            "Type" : STRING_TYPE,
            "Default" : ""
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
            "Names" : "Statistic",
            "Type" : STRING_TYPE,
            "Default" : "Sum"
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
        "Values" : [ "create", "remove", "restore", "reducedredundancy" ]
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
                "Default" : ""
            }
        ]
    }
] ]

[#-- Not for general use - framework only --]
[#assign coreComponentChildConfiguration = [
    {
        "Names" : ["Export"],
        "Default" : []
    },
    {
        "Names" : ["DeploymentUnits"],
        "Default" : []
    }
] ]
