[#ftl]

[#-- Utility functions --]

[#-- Recursively concatenate sequence of non-empty strings with a separator --]
[#function concatenate args separator]
    [#local content = []]
    [#list asArray(args) as arg]
        [#local argValue = arg!"CHECK_CONCATENATE"]
        [#if argValue?is_sequence]
            [#local argValue = concatenate(argValue, separator)]
        [/#if]f
        [#if argValue?is_hash]
            [#switch separator]
                [#case "X"]
                    [#if (argValue.Internal.IdExtensions)??]
                        [#local argValue = concatenate(
                                            argValue.Internal.IdExtensions,
                                            separator)]
                    [#else]
                        [#local argValue = argValue.Id!""]
                    [/#if]
                    [#break]
                [#case "-"]
                [#case "/"]
                    [#if (argValue.Internal.NameExtensions)??]
                        [#local argValue = concatenate(
                                            argValue.Internal.NameExtensions,
                                            separator)]
                    [#else]
                        [#local argValue = argValue.Name!""]
                    [/#if]
                    [#break]
                [#default]
                    [#local argValue = ""]
                    [#break]
            [/#switch]
        [/#if]
        [#if argValue?is_number]
            [#local argValue = argValue?c]
        [/#if]
        [#if argValue?has_content]
            [#local content +=
                [
                    argValue?remove_beginning(separator)?remove_ending(separator)
                ]
            ]
        [/#if]
    [/#list]
    [#return content?join(separator)]
[/#function]

[#-- Check if a deployment unit occurs anywhere in provided object --]
[#function deploymentRequired obj unit]
    [#if obj?is_hash]
        [#if allDeploymentUnits!false]
            [#return true]
        [/#if]
        [#if !unit?has_content]
            [#return true]
        [/#if]
        [#if obj.DeploymentUnits?has_content && obj.DeploymentUnits?seq_contains(unit)]
            [#return true]
        [/#if]
        [#list obj?values as attribute]
            [#if deploymentRequired(attribute unit)]
                [#return true]
            [/#if]
        [/#list]
    [/#if]
    [#return false]
[/#function]

[#function deploymentSubsetRequired subset default=false]
    [#return 
        deploymentUnitSubset?has_content?then(
            deploymentUnitSubset?lower_case?contains(subset),
            default
        )]
[/#function]

[#-- Calculate the closest power of 2 --]
[#function getPowerOf2 value]
    [#local exponent = -1]
    [#list powersOf2 as powerOf2]
        [#if powerOf2 <= value]
            [#local exponent = powerOf2?index]
        [#else]
            [#break]
        [/#if]
    [/#list]
    [#return exponent]
[/#function]

[#-- S3 config/credentials/appdata storage  --]

[#function getCredentialsFilePrefix]
    [#return formatSegmentPrefixPath(
            "credentials",
            (appSettingsObject.FilePrefixes.Credentials)!
                (appSettingsObject.DefaultFilePrefix)!
                deploymentUnit)]
[/#function]

[#function getAppSettingsFilePrefix]
    [#return formatSegmentPrefixPath(
            "appsettings",
            (appSettingsObject.FilePrefixes.AppSettings)!
                (appSettingsObject.DefaultFilePrefix)!
                deploymentUnit)]
[/#function]

[#function getAppDataFilePrefix]
    [#return formatSegmentPrefixPath(
            "appdata",
            (appSettingsObject.FilePrefixes.AppData)!
                (appSettingsObject.DefaultFilePrefix)!
                deploymentUnit)]
[/#function]

[#function getBackupsFilePrefix]
    [#return formatSegmentPrefixPath(
            "backups",
            (appSettingsObject.FilePrefixes.Backups)!
                (appSettingsObject.DefaultFilePrefix)!
                deploymentUnit)]
[/#function]

[#function getSegmentCredentialsFilePrefix]
    [#return formatSegmentPrefixPath("credentials")]
[/#function]

[#function getSegmentAppSettingsFilePrefix]
    [#return formatSegmentPrefixPath("appsettings")]
[/#function]

[#function getSegmentAppDataFilePrefix]
    [#return formatSegmentPrefixPath("appdata")]
[/#function]

[#function getSegmentBackupsFilePrefix]
    [#return formatSegmentPrefixPath("backups")]
[/#function]

[#-- Tiers --]

[#-- Check if a tier exists --]
[#function isTier tierId]
    [#return (blueprintObject.Tiers[tierId])??]
[/#function]

[#-- Get a tier --]
[#function getTier tierId]
    [#if isTier(tierId)]
        [#return blueprintObject.Tiers[tierId]]
    [/#if]
[/#function]

[#-- Get the id for a tier --]
[#function getTierId tier]
    [#if tier?is_hash]
        [#return tier.Id]
    [#else]
        [#return tier]
    [/#if]
[/#function]

[#-- Get the name for a tier --]
[#function getTierName tier]
    [#if tier?is_hash]
        [#return tier.Name]
    [#else]
        [#return getTier(tier).Name]
    [/#if]
[/#function]

[#-- Zones --]

[#-- Get the id for a zone --]
[#function getZoneId zone]
    [#if zone?is_hash]
        [#return zone.Id]
    [#else]
        [#return zone]
    [/#if]
[/#function]

[#-- Components --]

[#-- Get the id for a component --]
[#function getComponentId component]
    [#if component?is_hash]
        [#return component.Id?split("-")[0]]
    [#else]
        [#return component?split("-")[0]]
    [/#if]
[/#function]

[#-- Get the name for a component --]
[#function getComponentName component]
    [#if component?is_hash]
        [#return component.Name?split("-")[0]]
    [#else]
        [#return component?split("-")[0]]
    [/#if]
[/#function]

[#-- Get the type for a component --]
[#function getComponentType component]
    [#local idParts = component.Id?split("-")]
    [#if idParts[1]?has_content]
        [#return idParts[1]?lower_case]
    [#else]
        [#list component?keys as key]
            [#switch key]
                [#case "Id"]
                [#case "Name"]
                [#case "Title"]
                [#case "Description"]
                [#case "DeploymentUnits"]
                [#case "MultiAZ"]
                    [#break]

                [#default]
                    [#return key?lower_case]
                    [#break]
            [/#switch]
        [/#list]
    [/#if]
[/#function]

[#-- Get the type object for a component --]
[#function getComponentTypeObject component]
    [#list component as key,value]
        [#switch key]
            [#case "Id"]
            [#case "Name"]
            [#case "Title"]
            [#case "Description"]
            [#case "DeploymentUnits"]
            [#case "MultiAZ"]
                [#break]

            [#default]
                [#return value]
                [#break]
        [/#switch]
    [/#list]
    [#return {}]
[/#function]

[#-- Get a component within a tier --]
[#function getComponent tierId componentId type=""]
    [#if isTier(tierId) && (getTier(tierId).Components)??]
        [#list getTier(tierId).Components?values as component]
            [#if component?is_hash && (component.Id == componentId)]
                [#return component]
            [/#if]
            [#if type?has_content &&
                (getComponentId(component) == componentId) &&
                (getComponentType(component) == type)]
                [#return component]
            [/#if]
        [/#list]
    [/#if]
    [#return {} ]
[/#function]

[#-- Get the type specific attributes of versions/instances of a component --]
[#function getOccurrenceAttributes attributes=[] root={} instance={} version={} ]
    [#local result = {} ]
    [#list asArray(attributes) as attribute]
        [#local attributeName = attribute?is_hash?then(attribute.Name, attribute) ]
        [#local children = attribute?is_hash?then(attribute.Children![], []) ]
        [#local attributeDefault = attribute?is_hash?then(attribute.Default!"","") ]
        [#local isConfigured =
                    version[attributeName]?? ||
                    instance[attributeName]?? ||
                    root[attributeName]?? ]
        [#local result +=
            {
                attributeName + "IsConfigured": isConfigured
            }
        ]
        [#local result +=
            {
                attributeName :
                    children?has_content?then(
                        getOccurrenceAttributes(
                            children,
                            root[attributeName]!{},
                            instance[attributeName]!{},
                            version[attributeName]!{}
                        ),
                        version[attributeName]!
                            instance[attributeName]!
                            root[attributeName]!
                            attributeDefault
                    )
            }
        ]
    [/#list]
    [#return result ] 
[/#function]

[#-- treat the value "default" for version/instance as the same as blank --]
[#function getOccurrenceId occurrence]
    [#return
        (occurrence.Id == "default")?then(
            "",
            occurrence.Id
        )
    ]
[/#function]

[#function getOccurrenceName occurrence]
    [#return
        getOccurrenceId(occurrence)?has_content?then(
            occurrence.Name,
            ""
        )
    ]
[/#function]

[#-- Component attributes object can be extended dynamically by each component type --]
[#assign componentAttributes =
    {
        "alb" :
            [
                {
                    "Name" : "Logs",
                    "Default" : false
                },
                {
                    "Name" : "PortMappings",
                    "Default" : []
                },
                {
                    "Name" : "IPAddressGroups",
                    "Default" : []
                },
                {
                    "Name" : "DNS",
                    "Default" : {}
                }
            ],
        "apigateway" :
            [
                {
                    "Name" : "Links",
                    "Default" : {}
                },
                {
                    "Name" : "WAF",
                    "Children" : [
                        {
                            "Name" : "IPAddressGroups",
                            "Default" : []
                        },
                        {
                            "Name" : "Default"
                        },
                        {
                            "Name" : "RuleDefault"
                        }
                    ]
                },
                {
                    "Name" : "CloudFront",
                    "Children" : [
                        {
                            "Name" : "AssumeSNI",
                            "Default" : true
                        },
                        {
                            "Name" : "EnableLogging",
                            "Default" : true
                        },
                        {
                            "Name" : "CountryGroups",
                            "Default" : []
                        }
                    ]
                },
                {
                    "Name" : "DNS",
                    "Children" : [
                        {
                            "Name" : "Host",
                            "Default" : ""
                        }
                    ]
                }
            ],
        "ecs" : 
            [
            ],
        "lambda" :
            [
                "RunTime",
                "Container",
                "Handler",
                {
                    "Name" : "MemorySize",
                    "Default" : 0
                },
                {
                    "Name" : "Timeout",
                    "Default" : 0
                },
                {
                    "Name" : "VPCAccess",
                    "Default" : true
                },
                {
                    "Name" : "Functions",
                    "Default" : {}
                },
                {
                    "Name" : "UseSegmentKey",
                    "Default" : false
                }
            ],
        "s3" : 
            [
                "Lifecycle",
                "Style",
                "Notifications"
            ],
        "service" : 
            [
                {
                    "Name" : "DesiredCount",
                    "Default" : -1
                },
                {
                    "Name" : "Containers",
                    "Default" : {}
                },
                {
                    "Name" : "UseTaskRole",
                    "Default" : true
                }
            ],
        "sqs" : 
            [
                "DelaySeconds",
                "MaximumMessageSize",
                "MessageRetentionPeriod",
                "ReceiveMessageWaitTimeSeconds",
                "VisibilityTimeout"               
            ],
        "task" : 
            [
                {
                    "Name" : "Containers",
                    "Default" : {}
                },
                {
                    "Name" : "UseTaskRole",
                    "Default" : true
                }
            ]
    }
]

[#-- Get the occurrences of versions/instances of a component/subcomponent --]
[#function getOccurrences root deploymentUnit="" subComponentType=""]
    [#if subComponentType?has_content]
        [#local componentObject = root]
        [#local attributes = componentAttributes[subComponentType]![] ]
        [#local subComponentId = [root.Id] ]
        [#local subComponentName = [root.Name] ]
    [#else]
        [#local componentObject = getComponentTypeObject(root)]
        [#local attributes = componentAttributes[getComponentType(root)]![] ]
        [#local subComponentId = [] ]
        [#local subComponentName = [] ]
    [/#if]
    [#local occurrences=[] ]
    [#if componentObject.Instances?has_content]
        [#list componentObject.Instances?values as instance]
            [#if instance?is_hash && deploymentRequired(instance, deploymentUnit)]
                [#local instanceId = getOccurrenceId(instance)]
                [#local instanceName = getOccurrenceName(instance)]
                [#if instance.Versions?has_content]
                    [#list instance.Versions?values as version]
                        [#if version?is_hash && deploymentRequired(version, deploymentUnit)]
                            [#local versionId = getOccurrenceId(version)]
                            [#local versionName = getOccurrenceName(version)]
                            [#local occurrences +=
                                [
                                    {
                                        "InstanceId" : instanceId,
                                        "InstanceName" : instanceName,
                                        "VersionId" : versionId,
                                        "VersionName" : versionName,
                                        "Internal" : {
                                            "IdExtensions" : subComponentId + [instanceId, versionId],
                                            "NameExtensions" : subComponentName + [instanceName, versionName]
                                        }
                                    } +
                                    getOccurrenceAttributes(attributes, componentObject, instance, version)
                                ]
                            ]
                        [/#if]
                    [/#list]
                [#else]
                    [#local occurrences +=
                        [
                            {
                                "InstanceId" : instanceId,
                                "InstanceName" : instanceName,
                                "VersionId" : "",
                                "VersionName" : "",
                                "Internal" : {
                                    "IdExtensions" : subComponentId + [instanceId],
                                    "NameExtensions" : subComponentName + [instanceName]
                                }
                            } +
                            getOccurrenceAttributes(attributes, componentObject, instance)
                        ]
                    ]
                [/#if]
            [/#if]
        [/#list]
    [#else]
        [#if componentObject.Versions?has_content]
            [#list componentObject.Versions?values as version]
                [#if version?is_hash && deploymentRequired(version, deploymentUnit)]
                    [#local versionId = getOccurrenceId(version)]
                    [#local versionName = getOccurrenceName(version)]
                    [#local occurrences +=
                        [
                            {
                                "InstanceId" : "",
                                "InstanceName" : "",
                                "VersionId" : versionId,
                                "VersionName" : versionName,
                                "Internal" : {
                                    "IdExtensions" : subComponentId + [versionId],
                                    "NameExtensions" : subComponentName + [versionName]
                                }
                            } +
                            getOccurrenceAttributes(attributes, componentObject, {}, version)
                        ]
                    ]
                [/#if]
            [/#list]
        [#else]
            [#if deploymentRequired(root, deploymentUnit)]
                [#local occurrences +=
                    [
                        {
                            "InstanceId" : "",
                            "InstanceName" : "",
                            "VersionId" : "",
                            "VersionName" : "",
                            "Internal" : {
                                "IdExtensions" : subComponentId,
                                "NameExtensions" : subComponentName
                            }
                        } +
                        getOccurrenceAttributes(attributes, componentObject)
                    ]
                ]
            [/#if]
        [/#if]
    [/#if]
    [#return occurrences ]
[/#function]

[#-- Get processor settings --]
[#function getProcessor tier component type extensions...]
    [#local tc = formatComponentShortName(
                    tier,
                    component,
                    extensions)]
    [#local defaultProfile = "default"]
    [#if (component[type].Processor)??]
        [#return component[type].Processor]
    [/#if]
    [#if (processors[solutionObject.CapacityProfile][tc])??]
        [#return processors[solutionObject.CapacityProfile][tc]]
    [/#if]
    [#if (processors[solutionObject.CapacityProfile][type])??]
        [#return processors[solutionObject.CapacityProfile][type]]
    [/#if]
    [#if (processors[defaultProfile][tc])??]
        [#return processors[defaultProfile][tc]]
    [/#if]
    [#if (processors[defaultProfile][type])??]
        [#return processors[defaultProfile][type]]
    [/#if]
[/#function]

[#-- Get storage settings --]
[#function getStorage tier component type extensions...]
    [#local tc = formatComponentShortName(
                    tier,
                    component,
                    extensions)]
    [#local defaultProfile = "default"]
    [#if (component[type].Storage)??]
        [#return component[type].Storage]
    [/#if]
    [#if (storage[solutionObject.CapacityProfile][tc])??]
        [#return storage[solutionObject.CapacityProfile][tc]]
    [/#if]
    [#if (storage[solutionObject.CapacityProfile][type])??]
        [#return storage[solutionObject.CapacityProfile][type]]
    [/#if]
    [#if (storage[defaultProfile][tc])??]
        [#return storage[defaultProfile][tc]]
    [/#if]
    [#if (storage[defaultProfile][type])??]
        [#return storage[defaultProfile][type]]
    [/#if]
[/#function]

[#-- Utility Macros --]

[#-- Output object as JSON --]
[#function getJSON obj]
    [#local result = ""]
    [#if obj?is_hash]
        [#local result += "{"]
        [#list obj as key,value]
            [#local result += "\"" + key + "\" : " + getJSON(value)]
            [#sep][#local result += ","][/#sep]
        [/#list]
        [#local result += "}"]
    [#else]
        [#if obj?is_sequence]
            [#local result += "["]
            [#list obj as entry]
                [#local result += getJSON(entry)]
                [#sep][#local result += ","][/#sep]
            [/#list]
            [#local result += "]"]
        [#else]
            [#if obj?is_string]
                [#local result = "\"" + obj + "\""]
            [#else]
                [#local result = obj?c]
            [/#if]
        [/#if]
    [/#if]
    [#return result]
[/#function]

[#macro toJSON obj escaped=false]
    ${escaped?then(
        getJSON(obj)?json_string,
        getJSON(obj))}[/#macro]
        
[#function asArray arg]
    [#return arg?is_sequence?then(arg, [arg])]
[/#function]

[#function valueIfTrue value condition]
    [#return condition?then(value, {}) ]
[/#function]

[#function valueIfContent value content]
    [#return valueIfTrue(value, content?has_content) ]
[/#function]

[#function attributeIfTrue attribute condition value]
    [#return valueIfTrue({attribute : value}, condition) ]
[/#function]

[#function attributeIfContent attribute content value={}]
    [#return attributeIfTrue(
        attribute,
        content?has_content,
        value?has_content?then(value,content)) ]
[/#function]

[#function if arg value]
    [#return arg?then(value, {}) ]
[/#function]

[#function asString arg attribute]
    [#return
        arg?is_string?then(
            arg,
            arg?is_hash?then(
                arg[attribute]?has_content?then(
                    asString(arg[attribute], attribute),
                    ""
                ),
                arg[0]?has_content?then(
                    asString(arg[0], attribute),
                    ""
                )
            )
        )
    ]
[/#function]
