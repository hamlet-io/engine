[#ftl]

[#-- Utility functions --]

[#function asArray arg flatten=false ]
    [#if arg?is_sequence]
        [#if flatten]
            [#local result = [] ]
            [#list arg as element]
                [#local result += asArray(element, true) ]
            [/#list]
            [#return result ]
        [#else]
            [#return arg ]
        [/#if]
    [#else]
        [#return [arg] ]
    [/#if]
[/#function]

[#function asFlattenedArray arg]
    [#return asArray(arg, true) ]
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

[#function getDescendent object default path...]
    [#local descendent=object]
    [#list asFlattenedArray(path) as part]
        [#if descendent[part]??]
            [#local descendent=descendent[part] ]
        [#else]
            [#return default]
        [/#if]
    [/#list]
        
    [#return descendent]
[/#function]

[#function setDescendent object descendent id path...]
  [#local effectivePath = asFlattenedArray(path) ]
    [#if effectivePath?has_content]
      [#return
        object +
        {
          effectivePath?first : 
            setDescendent(
              object[effectivePath?first]!{},
              descendent,
              id,
              (effectivePath?size == 1)?then([],effectivePath[1..]))
        }
      ]
    [#else]
      [#return object + { id : object[id]!{} + descendent } ]
    [/#if]
[/#function]

[#function valueIfTrue value condition otherwise={}]
    [#return condition?then(value, otherwise) ]
[/#function]

[#function valueIfContent value content otherwise={}]
    [#return valueIfTrue(value, content?has_content, otherwise) ]
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

[#function firstContent alternatives=[] otherwise={}]
    [#list asArray(alternatives) as alternative]
        [#if alternative?has_content]
            [#return alternative]
        [/#if]
    [/#list]
    [#return otherwise ]
[/#function]

[#-- Recursively concatenate sequence of non-empty strings with a separator --]
[#function concatenate args separator]
    [#local content = []]
    [#list asFlattenedArray(args) as arg]
        [#local argValue = arg!"ERROR_INVALID_ARG_TO_CONCATENATE"]
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
                [#case "_"]
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

[#function getAppDataPublicFilePrefix ]

    [#if (segmentObject.Data.Public.Enabled)!false]
        [#return formatSegmentPrefixPath(
            "apppublic",
            (appSettingsObject.FilePrefixes.AppData)!
                (appSettingsObject.DefaultFilePrefix)!
                deploymentUnit)]
    [#else]
        [#return 
            ""
        ]
    [/#if]
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
    [#else]
        [#return {}]
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
      [#local tierObject = getTier(tier) ]
        [#return tierObject.Name!tier ]
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
    [#if ! (component?is_hash && component.Id?has_content) ]
        [@cfPreconditionFailed listMode "getComponentType" component /]
        [#return "???"]
    [/#if]
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
    [#if isTier(tierId) ]
        [#list ((getTier(tierId).Components)!{})?values as component]
            [#if
                component?is_hash &&
                (
                    (component.Id == componentId) ||
                    (
                      type?has_content &&
                      (getComponentId(component) == componentId) &&
                      (getComponentType(component) == type)
                    )
                ) ]
                [#return component]
            [/#if]
        [/#list]
    [/#if]
    [#return {} ]
[/#function]

[#-- Formulate a composite object based on order precedence - lowest to highest  --]
[#-- If no attributes are provided, simply combine the objects --]
[#-- It is also possible to define an attribute with a name of "*" which will trigger --]
[#-- the combining of the objects in addition to any attributes already created --]
[#function getCompositeObject attributes=[] objects...]
    [#local result = {} ]
    [#local candidates = [] ]

    [#list asFlattenedArray(objects) as element]
        [#if element?is_hash]
            [#local candidates += [element] ]
        [/#if]
    [/#list]

    [#if attributes?has_content]
        [#list asFlattenedArray(attributes) as attribute]
            [#local attributeNames = 
                attribute?is_sequence?then(
                    attribute,
                    attribute?is_hash?then(
                        attribute.Name?is_sequence?then(
                            attribute.Name,
                            [attribute.Name]),
                        [attribute])) ]

            [#local children = attribute?is_hash?then(attribute.Children![], []) ]
            [#local populateMissingChildren = attribute?is_hash?then(attribute.PopulateMissingChildren!true, true) ]
    
            [#-- Look for the first name alternative --]
            [#local firstName = ""]
            [#list attributeNames as attributeName]
                [#if attributeName == "*"]
                    [#local firstName = "*"]
                [/#if]
                [#if firstName?has_content]
                    [#break]
                [#else]
                    [#list candidates?reverse as object]
                        [#if object[attributeName]??]
                            [#local firstName = attributeName]
                            [#break]
                        [/#if]
                    [/#list]
                [/#if]
            [/#list]
            [#if firstName == "*"]
                [#break]
            [/#if]
    
            [#if children?has_content]
                [#local childObjects = [] ]
                [#list candidates as object]
                    [#if object[firstName]??]
                        [#local childObjects += [object[firstName]] ]
                    [/#if]
                [/#list]
                [#if populateMissingChildren || childObjects?has_content]
                    [#local result +=
                        {
                            attributeNames[0] :
                                populateMissingChildren?then(
                                    {
                                        "Configured" : firstName?has_content
                                    },
                                    {}
                                ) +
                                getCompositeObject(children, childObjects)
                        }
                        
                    ]
                [/#if]
            [#else]
                [#local valueProvided = false ]
                [#list candidates?reverse as object]
                    [#if object[firstName]??]
                        [#local attributeValue = object[firstName] ]
                        [#local valueProvided = true ]
                        [#break]
                    [/#if]
                [/#list]
                [#if valueProvided]
                    [#local result +=
                        {
                            attributeNames[0] : attributeValue
                        }
                    ]
                [#else]
                    [#if attribute?is_hash && attribute.Default?? ]
                        [#local result += 
                            {
                                attributeNames[0] : attribute.Default
                            }
                        ]          
                    [/#if]
                [/#if]
            [/#if]
        [/#list]
        [#if firstName != "*"]
            [#return result ]
        [/#if]
    [/#if]

    [#list candidates as object]
        [#local result += object?is_hash?then(object, {}) ]
    [/#list]
    [#return result ] 
[/#function]

[#function getObjectAndQualifiers object qualifiers...]
    [#local result = [] ]
    [#if object?is_hash]
        [#local result += [object] ]
        [#list asFlattenedArray(qualifiers) as qualifier]
            [#if ((object.Qualifiers[qualifier])!"")?is_hash]
                [#local result += [object.Qualifiers[qualifier]] ]
            [/#if]
        [/#list]
    [/#if]
    [#return result ]
[/#function]

[#function getObjectAncestry collection start qualifiers...]
    [#local result = [] ]
    [#local startingObject = "" ]
    [#list asFlattenedArray(start) as startEntry]
        [#if startEntry?is_hash]
            [#local startingObject = start ]
            [#break]
        [#else]
            [#if startEntry?is_string]
                [#if ((collection[startEntry])!"")?is_hash]
                    [#local startingObject = collection[startEntry] ]
                    [#break]
                [/#if]
            [/#if]
        [/#if]
    [/#list]

    [#if startingObject?is_hash]
        [#local base = getObjectAndQualifiers(startingObject, qualifiers) ]
        [#local result += [base] ]
        [#local parentObject = getCompositeObject( ["Parent"], base ) ]
        [#if parentObject.Parent?has_content]
            [#local result =
                        getObjectAncestry(
                            collection,
                            parentObject.Parent,
                            qualifiers) +
                        result ]
        [/#if]
    [/#if]
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
                    "Name" : "Certificate",
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
                            "Name" : "Enabled",
                            "Default" : true
                        },
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
                            "Name" : "Enabled",
                            "Default" : true
                        },
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
                    "Name" : "Certificate",
                    "Children" : [
                        {
                            "Name" : "Enabled",
                            "Default" : true
                        },
                        {
                            "Name" : "*"
                        }
                    ]
                },
                {
                    "Name" : "Publish",
                    "Children" : [
                        {
                            "Name"  : "Enabled",
                            "Default" : true
                        },
                        {
                            "Name" : "DnsNamePrefix",
                            "Default" : "docs"
                        },
                        {
                            "Name" : "IPAddressGroups",
                            "Default" : []
                        }
                    ]
                }
            ],
        "ecs" : 
            [
                {
                    "Name" : "ClusterWideStorage",
                    "Default" : false
                }
            ],
        "lambda" :
            [
                "RunTime",
                "Container",
                "Handler",
                {
                    "Name" : "Links",
                    "Default" : {}
                },
                {
                    "Name" : ["Memory", "MemorySize"],
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
        "rds" : 
            [
                "Engine",
                "EngineVersion",
                "Port",
                { 
                    "Name" : "Size",
                    "Default" : "20"
                },
                {
                    "Name" : "Backup",
                    "Children" : [
                        {
                            "Name" : "RetentionPeriod",
                            "Default" : 35
                        }
                    ]
                },
                {
                    "Name" : "SnapShotOnDeploy",
                    "Default" : true
                }
            ],
        "s3" : 
            [
                {
                    "Name" : "Lifecycle",
                    "Children" : [
                        {
                            "Name" : "Expiration"
                        }
                    ]
                },
                { 
                    "Name" : "Website",
                    "Children" : [
                        {
                            "Name"  : "Enabled",
                            "Default" : true
                        },
                        {
                            "Name": "Index",
                            "Default": "index.html"
                        },
                        {
                            "Name": "Error",
                            "Default": ""
                        }
                    ]
                }
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
        "spa" :
            [
                {
                    "Name" : "Links",
                    "Default" : {}
                },
                {
                    "Name" : "WAF",
                    "Children" : [
                        {
                            "Name" : "Enabled",
                            "Default" : true
                        },
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
                        },
                        {
                            "Name" : "ErrorPage",
                            "Default" : "/index.html"
                        }
                    ]
                },
                {
                    "Name" : "Certificate",
                    "Children" : [
                        {
                            "Name" : "Enabled",
                            "Default" : true
                        },
                        {
                            "Name" : "*"
                        }
                    ]
                }
            ],
        "sqs" : 
            [
                "DelaySeconds",
                "MaximumMessageSize",
                "MessageRetentionPeriod",
                "ReceiveMessageWaitTimeSeconds",
                {
                    "Name" : "DeadLetterQueue",
                    "Children" : [
                        {
                            "Name" : "MaxReceives",
                            "Default" : 0
                        },
                        {
                            "Name" : "Enabled",
                            "Default" : true
                        }
                    ]
                },
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
            ],
        "userpool" :
            [
                { 
                    "Name" : "MFA",
                    "Default" : false
                },
                {
                    "Name" : "adminCreatesUser",
                    "Default" : true
                },
                {
                    "Name" : "unusedAccountTimeout"
                },
                {
                    "Name" : "verifyEmail",
                    "Default" : true
                },
                {
                    "Name" : "verifyPhone",
                    "Default" : false
                },
                {
                    "Name" : "loginAliases",
                    "Default" : [
                        "email"
                    ]
                },
                {
                    "Name" : "clientGenerateSecret",
                    "Default" : false
                },
                {
                    "Name" : "clientTokenValidity",
                    "Default" : 30
                },
                {
                    "Name" : "allowUnauthIds",
                    "Default" : false
                }
                {
                    "Name" : "passwordPolicy",
                    "Children" : [
                        {
                           "Name" : "MinimumLength",
                           "Default" : "8"
                        },
                        {
                            "Name" : "Lowercase",
                            "Default" : true
                        },
                        {
                            "Name" : "Uppercase",
                            "Default" : true
                        },
                        {
                            "Name" : "Numbers",
                            "Default" : true
                        },
                        {
                            "Name" : "SpecialCharacters",
                            "Default" : false
                        }
                    ] 
                }
            ],
        "efs"  :
            [
            ]
    }
]

[#-- Get the occurrences of versions/instances of a component/subcomponent --]
[#function getOccurrences root deploymentUnit="" subComponentType=""]
    [#if subComponentType?has_content]
        [#local type = subComponentType]
        [#local componentObject = root]
        [#local subComponentId = [root.Id] ]
        [#local subComponentName = [root.Name] ]
    [#else]
        [#local type = getComponentType(root)]
        [#local componentObject = getComponentTypeObject(root)]
        [#local subComponentId = [] ]
        [#local subComponentName = [] ]
    [/#if]
    [#local attributes = componentAttributes[type]![] ]
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
                                    getCompositeObject(attributes, componentObject, instance, version)
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
                            getCompositeObject(attributes, componentObject, instance)
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
                            getCompositeObject(attributes, componentObject, version)
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
                        getCompositeObject(attributes, componentObject)
                    ]
                ]
            [/#if]
        [/#if]
    [/#if]
    [#return occurrences ]
[/#function]

[#function getLinkTarget occurrence link]
    [#local result = {} ]
    [#local targetComponentType = "" ]

    [#if link.Tier?lower_case == "external"]
        [#local result = 
            {
                "InstanceId" : "",
                "InstanceName" : "",
                "VersionId" : "",
                "VersionName" : ""
            } ]
        [#local targetComponentType = "external" ]
    [#else]
        [#local targetComponent = getComponent(link.Tier, link.Component)]
        [#if targetComponent?has_content]
            [#local targetComponentType = getComponentType(targetComponent) ]
            [#list getOccurrences(targetComponent) as targetOccurrence]
                [#if targetOccurrence.VersionId?has_content]
                    [#if (targetOccurrence.InstanceId != occurrence.InstanceId) ||
                        (targetOccurrence.VersionId != occurrence.VersionId) ]
                        [#continue]
                    [/#if]
                [/#if]
                [#if targetOccurrence.InstanceId?has_content]
                    [#if (targetOccurrence.InstanceId != occurrence.InstanceId) ]
                        [#continue]
                    [/#if]
                [/#if]
                [#local
                    result =
                        targetOccurrence +
                        {
                            "Type" : targetComponentType,
                            "Tier" : link.Tier,
                            "Component" : link.Component
                        } ]
            [/#list]
        [/#if]
    [/#if]

    [#if !(result?has_content) ]
        [@cfPostconditionFailed
            listMode
            "getLinkTarget"
            {
                "Occurrence" : occurrence,
                "Link" : link
            }
            "Link not found" /]
    [/#if]
    [#return result ]
[/#function]

[#function getLinkTargetInformation target]
    [#local result = {} ]
    [@cfDebug listMode target false /]

    [#if !(target?has_content)]
        [#return
            {
                "ResourceId" : "unknown",
                "Attributes" : {
                    "NOATTRIBUTES" : "link not found"
                }
            }
        ]
    [/#if]

    [#local fqdn = ""]
    [#local signingFqdn = ""]
    [#if ((target.Certificate.Configured)!false) && 
            ((target.Certificate.Enabled)!false) ]
        [#local certificateObject = getCertificateObject(target.Certificate, segmentId, segmentName) ]
        [#local hostName = getHostName(certificateObject, target.Tier, target.Component, target) ]
        [#local fqdn = formatDomainName(hostName, certificateObject.Domain.Name) ]
        [#local signingFqdn = formatDomainName(
            formatName("sig4", hostName), certificateObject.Domain.Name) ] 
    [/#if]
    [#switch target.Type!""]
        [#case "alb"]
            [#local id =
                formatALBId(
                    target.Tier,
                    target.Component,
                    target) ]
            [#local internalFqdn =
                getExistingReference(id, DNS_ATTRIBUTE_TYPE) ]
            [#local fqdn = valueIfContent(fqdn, fqdn, internalFqdn) ]
            [#if (target.PortMappings![])?has_content]
                [#local portMapping = target.PortMappings[0]?is_hash?then(
                        target.PortMappings[0],
                        {
                            "Mapping" : target.PortMappings[0]
                        }
                    )]
    
                [#local scheme =
                    ((ports[portMappings[mappingObject.Mapping].Source].Certificate)!false)?then(
                        "https",
                        "http"
                    )]
            [#else]
                [#local scheme = "?????" ]
            [/#if]
            [#local result =
                {
                    "ResourceId" : id,
                    "Attributes" : {
                        "FQDN" : fqdn,
                        "URL" : scheme + "://" + fqdn,
                        "INTERNAL_FQDN" : internalFqdn,
                        "INTERNAL_URL" : scheme + "://" + internalFqdn
                    }
                }
            ]
            [#break]

        [#case "apigateway"]
            [#local id =
                formatAPIGatewayId(
                    target.Tier,
                    target.Component,
                    target)]
            [#local internalFqdn =
                formatDomainName(
                    getExistingReference(id),
                    "execute-api",
                    regionId,
                    "amazonaws.com") ]
            [#local fqdn = valueIfContent(fqdn, fqdn, internalFqdn) ]
            [#local signingFqdn = valueIfContent(signingFqdn, signingFqdn, internalFqdn) ]
            [#local result =
                {
                    "ResourceId" : id,
                    "Attributes" : {
                        "FQDN" : fqdn,
                        "URL" : "https://" + fqdn,
                        "SIGNING_FQDN" : signingFqdn,
                        "SIGNING_URL" : "https://" + signingFqdn,
                        "INTERNAL_FQDN" : internalFqdn,
                        "INTERNAL_URL" : "https://" + internalFqdn
                    },
                    "Policy" : apigatewayInvokePermission(id, target.VersionId)
                }
            ]
            [#break]

        [#case "external"]
            [#local result =
                {
                    "ResourceId" : "externalXlink",
                    "Attributes" : {}
                }
            ]
            [#list appSettingsObject!{} as name,value]
                [#local prefix = target.Component?upper_case + "_"]
                [#if name?upper_case?starts_with(prefix)]
                    [#local result +=
                    {
                      "Attributes" : result.Attributes + { name?upper_case?remove_beginning(prefix) : value }
                    } ]
                [/#if]
            [/#list]
            [#list ((credentialsObject[target.Tier + "-" + target.Component])!{})?values as credential]
                [#list credential as name,value]
                    [#local result +=
                        {
                          "Attributes" : result.Attributes + { name?upper_case : value }
                        }
                    ]
                [/#list]
            [/#list]
            [#break]

        [#case "lambda"]
            [#local id =
                formatLambdaId(
                    target.Tier,
                    target.Component,
                    target)]

            [#local result =
                {
                    "ResourceId" : id,
                    "Attributes" : {
                        "REGION" : regionId
                    }
                }
            ]
            [#break]

        [#case "rds"]
            [#local id =
                formatRDSId(
                    target.Tier,
                    target.Component,
                    target)]

            [#local result =
                {
                    "ResourceId" : id,
                    "Attributes" : {
                        "FQDN" : getExistingReference(id, DNS_ATTRIBUTE_TYPE),
                        "PORT" : getExistingReference(id, PORT_ATTRIBUTE_TYPE),
                        "NAME" : getExistingReference(id, DATABASENAME_ATTRIBUTE_TYPE)
                    }
                }
            ]
            [#list (credentialsObject[target.Tier + "-" + target.Component].Login)!{} as name,value]
                [#local result +=
                    {
                      "Attributes" : result.Attributes + { name?upper_case : value }
                    }
                ]
            [/#list]
            [#break]

        [#case "sqs"]
            [#local id =
                formatComponentSQSId(
                    target.Tier,
                    target.Component,
                    target)]
            [#local result +=
                {
                    "ResourceId" : id,
                    "Attributes" : {
                        "NAME" : getExistingReference(id, NAME_ATTRIBUTE_TYPE),
                        "URL" : getExistingReference(id, URL_ATTRIBUTE_TYPE),
                        "ARN" : getExistingReference(id, ARN_ATTRIBUTE_TYPE),
                        "REGION" : regionId
                    }
                }
            ]
            [#break]

        [#case "s3"]
            [#local id =
                formatComponentS3Id(
                    target.Tier,
                    target.Component,
                    target)]
            [#local result +=
                {
                    "ResourceId" : id,
                    "Attributes" : {
                        "NAME" : getExistingReference(id, NAME_ATTRIBUTE_TYPE),
                        "FQDN" : getExistingReference(id, DNS_ATTRIBUTE_TYPE),
                        "INTERNAL_FQDN" : getExistingReference(id, DNS_ATTRIBUTE_TYPE),
                        "WEBSITE_URL" : getExistingReference(id, URL_ATTRIBUTE_TYPE),
                        "ARN" : getExistingReference(id, ARN_ATTRIBUTE_TYPE),
                        "REGION" : regionId
                    }
                }
            ]
            [#break]

        [#case "userpool"] 
            [#local id = formatUserPoolId(target.Tier, target.Component) ]
            [#local clientId = formatUserPoolClientId(target.Tier, target.Component) ]
            [#local identityPoolId = formatIdentityPoolId(target.Tier, target.Component) ]
            [#local result +=
                {
                    "ResourceId" : id,
                    "Attributes" : {
                        "USER_POOL" : getReference(id),
                        "IDENTITY_POOL" : getReference(identityPoolId),
                        "CLIENT" : getReference(clientId),
                        "REGION" : regionId

                    }
                }
            ]
            [#break]
    [/#switch]
    
    [#return result]
[/#function]

[#function getLinkTargets occurrence links={}]
    [#local result={} ]
    [#list (valueIfContent(links, links, occurrence.Links!{}))?values as link]
        [#if link?is_hash]
            [#local linkInformation =
                getLinkTargetInformation(getLinkTarget(occurrence, link)) ]
            
            [#local result +=
                valueIfContent(
                    {
                        link.Name : linkInformation
                    },
                    linkInformation
                )]
        [/#if]
    [/#list]
    [#return result ]
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

[#function getDomainObject start qualifiers...]
    [#local name = "" ]
    [#local domainObjects = getObjectAncestry(domains, start, qualifiers) ]
    [#list domainObjects as domainObject]
        [#local qualifiedDomainObject = getCompositeObject(["Stem", "Name", "Zone"], domainObject) ]
        [#local name = formatDomainName(
                          qualifiedDomainObject.Stem?has_content?then(
                              qualifiedDomainObject.Stem,
                              qualifiedDomainObject.Name?has_content?then(
                                  qualifiedDomainObject.Name,
                                  "")),
                          name) ]
    [/#list]
    [#return
        {
            "Name" : name
        } +
        getCompositeObject( ["Zone"], domainObjects ) ]
[/#function]

[#function getCertificateObject start qualifiers...]

    [#local certificateObject = 
        getCompositeObject(
            [
                "External",
                "Wildcard",
                "Domain",
                {
                    "Name" : "Host",
                    "Default" : ""
                },
                {
                    "Name" : "IncludeInHost",
                    "Children" : [
                      "Product",
                      "Environment",
                      "Segment",
                      "Tier",
                      "Component",
                      "Instance",
                      "Version",
                      "Host"
                    ]
                }
            ],
            asFlattenedArray(
                getObjectAndQualifiers((blueprintObject.CertificateBehaviours)!{}, qualifiers) +
                getObjectAndQualifiers((tenantObject.CertificateBehaviours)!{}, qualifiers) +
                getObjectAndQualifiers((productObject.CertificateBehaviours)!{}, qualifiers) +
                getObjectAncestry(certificates, [productId, productName], qualifiers) +
                getObjectAncestry(certificates, start, qualifiers)
            )
        )
    ]

    [#return
        certificateObject +
        {
            "Domain" : getDomainObject(certificateObject.Domain, qualifiers)
        }
    ]
[/#function]

[#function getHostName certificateObject tier="" component="" occurrence={}]

    [#local includes = certificateObject.IncludeInHost ]

    [#return
        valueIfTrue(
            certificateObject.Host,
            certificateObject.Host?has_content && (!(includes.Host)),
            formatName(
                valueIfTrue(certificateObject.Host, includes.Host),
                valueIfTrue(getTierName(tier), includes.Tier),
                valueIfTrue(getComponentName(component), includes.Component),
                valueIfTrue(occurrence.InstanceName!"", includes.Instance),
                valueIfTrue(occurrence.VersionName!"", includes.Version),
                valueIfTrue(segmentName!"", includes.Segment),
                valueIfTrue(environmentName!"", includes.Environment),
                valueIfTrue(productName!"", includes.Product)
            )
        )
    ]
]
[/#function]

[#-- Output object as JSON --]
[#function getJSON obj escaped=false]
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
    [#return escaped?then(result?json_string, result) ]
[/#function]

[#-- Utility functions --]

[#macro toJSON obj escaped=false]
    ${getJSON(obj, escaped)}[/#macro]
        
