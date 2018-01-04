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

[#-- Formulate a composite object based on order precedence - lowest to highest  --]
[#-- If no attributes are provided, simply combine the objects --]
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
                            attributeNames[0] : getCompositeObject(children, childObjects) 
                        } +
                        populateMissingChildren?then(
                            {
                                attributeNames[0] + "IsConfigured" : firstName?has_content
                            },
                            {}
                        )
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
                    [#if attribute?is_hash && attribute.Default??]
                        [#local result +=
                            {
                                attributeNames[0] : attribute.Default
                            }
                        ]
                    [/#if]
                [/#if]
            [/#if]
        [/#list]
    [#else]
        [#list candidates as object]
            [#local result += object?is_hash?then(object, {}) ]
        [/#list]
    [/#if]
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
                    "Name" : "DNS",
                    "Children" : [
                        {
                            "Name" : "Enabled",
                            "Default" : true
                        },
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
                      "Version"
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
        formatDomainName(
            valueIfContent(
                certificateObject.Host,
                certificateObject.Host,
                formatName(
                    valueIfTrue(getTierName(tier), includes.Tier),
                    valueIfTrue(getComponentName(component), includes.Component),
                    valueIfTrue(occurrence.InstanceName!"", includes.Instance),
                    valueIfTrue(occurrence.VersionName!"", includes.Version),
                    valueIfTrue(segmentName!"", includes.Segment),
                    valueIfTrue(environmentName!"", includes.Environment),
                    valueIfTrue(productName!"", includes.Product)
                )
            ),
            certificateObject.Domain.Name
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
        
