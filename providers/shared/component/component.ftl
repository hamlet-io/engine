[#ftl]
[#assign SHARED_ATTRIBUTES = "shared"]

[#function formatResourceGroupName componentName groupName]
    [#return formatName(componentName, groupName)]
[/#function]

[#assign PRODUCT_PLACEMENT = "product"]
[#assign DNS_PLACEMENT = "dns"]

[#-- Lookup shared component definition --]
[#macro includeSharedComponentConfiguration component ]
    [#-- Handle object or type string --]
    [#local type = component ]
    [#if component?is_hash]
        [#local type = getComponentType(component) ]
    [/#if]
    [#local possibleFiles = [] ]
    [#local possibleFiles += [["shared", type]] ]
    [#local possibleFiles += [["shared", "component", type]] ]
    [#list possibleFiles as possibleFile]
        [#local filename = possibleFile?join("/") + ".ftl" ]
        [@cfDebug listMode "Checking for template " + filename + "..." false /]
        [#if includeTemplate(filename, true)]
            [@cfDebug listMode "Loaded template " + filename + " for component type " + type false /]
        [/#if]
    [/#list]
[/#macro]

[#function getComponentResourceGroups component]
    [#-- Handle object or type string --]
    [#local obj = component ]
    [#if component?is_string]
        [#local obj = (componentConfiguration[component])!{} ]
    [/#if]

    [#local result = {} ]

    [#if obj.ResourceGroups??]
        [#-- explicit resource group definition --]
        [#local result = obj.ResourceGroups]
    [#else]
        [#-- TODO(mfl) Can remove this once all components converted to resource groups --]
        [#if obj?has_content]
            [#-- default configuration --]
            [#local result =
                {
                    "default" : {
                        "Placement" : PRODUCT_PLACEMENT,
                        "Attributes" : {
                            SHARED_ATTRIBUTES : obj.Attributes![]
                        }
                    }
                } ]
        [/#if]
    [/#if]

    [#return result]
[/#function]

[#macro includeComponentConfiguration component ]
    [#-- Ensure the share configuration is loaded --]
    [@includeSharedComponentConfiguration component /]

    [#-- Provider specific processing based on resource groups --]
    [#local resourceGroups = getComponentResourceGroups(component)]

    [#local possibleFiles = [] ]
    [#local componentType = component]
    [#if component?is_hash]
        [#local componentType = getComponentType(component)]
    [/#if]
    [#list resourceGroups as id,value]
        [#-- Resource Group determines provider and deployment framework --]
        [#-- TODO(mfl): Work out how to determine these from the configuration --]
        [#local provider = "aws" ]
        [#local deploymentFramework = "cf" ]

        [#-- Support a variety of layouts depending on user preference --]
        [#-- General hierarchy is provider;component;resourceGroup;deploymentFramework;level --]

        [#-- Provider wide definitions --]
        [#-- aws/aws.ftl --]
        [#local possibleFiles += [[provider, provider]] ]
        [#-- aws/component/component.ftl --]
        [#local possibleFiles += [[provider, "component", "component" ]] ]
        [#-- aws/resourcegroup/resourcegroup.ftl --]
        [#local possibleFiles += [[provider, "resourcegroup", "resourcegroup" ]] ]
        [#-- aws/service/service.ftl --]
        [#local possibleFiles += [[provider, "service", "service" ]] ]

        [#-- Component based hierarchy --]

        [#-- aws/component/lb.ftl --]
        [#local possibleFiles += [[provider, "component", componentType ]] ]
        [#-- aws/component/lb/lb.ftl --]
        [#local possibleFiles += [[provider, "component", componentType, componentType]] ]

        [#-- aws/component/lb/lb-lb.ftl --]
        [#local possibleFiles += [[provider, "component", componentType, id]] ]
        [#-- aws/component/lb/lb-lb/cf.ftl --]
        [#local possibleFiles += [[provider, "component", componentType, id, deploymentFramework]] ]

        [#-- Component specific deployment framework definition --]
        [#-- aws/component/lb/cf.ftl --]
        [#local possibleFiles += [[provider, "component", componentType, deploymentFramework]] ]
        [#-- aws/component/lb/cf/lb-lb.ftl --]
        [#local possibleFiles += [[provider, "component", componentType, deploymentFramework, id]] ]

        [#-- Resource group based hierarchy --]

        [#-- mainly for shared resource groups --]
        [#if id != "default"]
            [#-- aws/resourcegroup/lb-lb.ftl --]
            [#local possibleFiles += [[provider, "resourcegroup", id]] ]
            [#-- aws/resourcegroup/lb-lb/cf.ftl --]
            [#local possibleFiles += [[provider, "resourcegroup", id, deploymentFramework]] ]
        [/#if]

        [#list ["id", "name", "setup", "state"] as level]
            [#-- aws/component/lb/id.ftl --]
            [#local possibleFiles += [[provider, "component", componentType, level]] ]
            [#-- aws/component/lb/lb-lb/id.ftl --]
            [#local possibleFiles += [[provider, "component", componentType, id, level]] ]
            [#-- aws/component/lb/lb-lb/cf/id.ftl --]
            [#local possibleFiles += [[provider, "component", componentType, id, deploymentFramework, level]] ]

            [#-- aws/resourcegroup/lb-lb/id.ftl --]
            [#local possibleFiles += [[provider, "resourcegroup", id, level]] ]
            [#-- aws/resourcegroup/lb-lb/cf/id.ftl --]
            [#local possibleFiles += [[provider, "resourcegroup", id, deploymentFramework, level]] ]

        [/#list]

        [#-- Legacy naming for transition --]
        [#-- TODO(mfl): Remove when transition complete --]
        [#list ["segment", "solution", "application"] as level]
            [#-- aws/component/segment/segment_lb.ftl --]
            [#local possibleFiles += [[provider, "component", level, level + "_" + componentType]] ]
        [/#list]

        [#-- Service based hierarchy --]

        [#-- Resource group identifies the provider services it depends on  --]
        [#-- TODO(mfl): Work out how to determine these from the configuration --]
        [#local services = [componentType] ]

        [#-- General hierarchy is provider;service;deploymentFramework;level --]

        [#list services as service]
            [#-- aws/services/eip.ftl --]
            [#local possibleFiles += [[provider, "service", service]] ]
            [#-- aws/services/eip/cf.ftl --]
            [#local possibleFiles += [[provider, "service", service, deploymentFramework]] ]

            [#list ["id", "name", "resource"] as level]
                [#-- aws/services/eip/id.ftl --]
                [#local possibleFiles += [[provider, "service", service, level]] ]
                [#-- aws/services/eip/cf/id.ftl --]
                [#local possibleFiles += [[provider, "service", service, deploymentFramework, level]] ]
            [/#list]

        [/#list]
    [/#list]

    [#-- Attempt to load the additional file --]
    [#list possibleFiles as possibleFile]
        [#local filename = possibleFile?join("/") + ".ftl" ]
        [@cfDebug listMode "Checking for template " + filename + "..." false /]
        [#if includeTemplate(filename, true)]
            [@cfDebug listMode "Loaded template " + filename + " for component " + componentType false /]
        [/#if]
    [/#list]
[/#macro]

[#macro processComponents level=""]
    [#list tiers as tier]
        [#list (tier.Components!{})?values as component]
            [#if deploymentRequired(component, deploymentUnit)]
                [#assign componentTemplates = {} ]
                [#assign dashboardRows = []]
                [#assign multiAZ = component.MultiAZ!solnMultiAZ]
                [#local componentMacro =
                    (["aws", getComponentType(component), "cf"] +
                    arrayIfContent(level, level))?join("_")]
                [@cfDebug listMode "Checking " + tier.Id + "/" + component.Id + "..." false /]
                [#list requiredOccurrences(
                    getOccurrences(tier, component),
                    deploymentUnit,
                    true) as occurrence]
                    [#if (.vars[componentMacro]!"")?is_directive]
                        [@cfDebug listMode "Processing " + tier.Id + "/" + component.Id + "..." false /]
                        [@(.vars[componentMacro]) occurrence /]
                    [#else]
                        [@cfDebug listMode "Unable to invoke macro " + componentMacro false /]
                    [/#if]
                [/#list]
            [/#if]
        [/#list]
    [/#list]
[/#macro]

[#-- Component configuration is extended dynamically by each component type --]
[#assign componentConfiguration = {} ]

[#macro mergeComponentConfiguration type configuration]
    [#assign componentConfiguration =
        mergeObjects(
            componentConfiguration,
            {
                type: configuration
            }
        )]
[/#macro]

[#macro addComponentConfiguration type properties=[] ]
    [@mergeComponentConfiguration
        type
        {
            "Properties" : asArray(properties)
        }
    /]
[/#macro]

[#macro addComponentResourceGroup type provider="common" resourceGroup="default" attributes=[] ]
    [@mergeComponentConfiguration
        type
        {
            "ResourceGroups" : {
                resourceGroup : {
                    "Attributes" : {
                        provider : asArray(attributes)
                    }
                }
            }
        }
    /]
[/#macro]

[#macro addComponentChildren componentType childType childAttribute linkAttribute ]
    [#local components =
        ((componentConfiguration[componentType].Components)![]) +
        {
            "Type" : childType,
            "Component" : childAttribute,
            "Link" : linkAttributes
        } ]
    [@mergeComponentConfiguration
        componentType
        {
            "Components" : components
        }
    /]
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

[#assign profileChildConfiguration = [
    {
        "Names" : "Deployment",
        "Type" : ARRAY_OF_STRING_TYPE
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