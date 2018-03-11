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
                    [#if (argValue.Core.Internal.IdExtensions)??]
                        [#local argValue = concatenate(
                                            argValue.Core.Internal.IdExtensions,
                                            separator)]
                    [#else]
                        [#local argValue = argValue.Id!""]
                    [/#if]
                    [#break]
                [#case "-"]
                [#case "_"]
                [#case "/"]
                    [#if (argValue.Core.Internal.NameExtensions)??]
                        [#local argValue = concatenate(
                                            argValue.Core.Internal.NameExtensions,
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
[#function deploymentRequired obj unit subObjects=true]
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
        [#if subObjects]
            [#list obj?values as attribute]
                [#if deploymentRequired(attribute unit)]
                    [#return true]
                [/#if]
            [/#list]
        [/#if]
    [/#if]
    [#return false]
[/#function]

[#function requiredOccurrences occurrences deploymentUnit]
    [#local result = [] ]
    [#list asFlattenedArray(occurrences) as occurrence]
        [#if deploymentRequired(occurrence.Configuration, deploymentUnit, false) ]
            [#local result += [occurrence] ]
        [/#if]
    [/#list]
    [#return result ]
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

[#-- Get a tier --]
[#assign tiers = [] ]
[#function getTier tier]
    [#if tier?is_hash]
        [#local tierId = (tier.Id)!"" ]
    [#else]
        [#local tierId = tier ]
    [/#if]

    [#-- Special processing for the "all" tier --]
    [#if tierId == "all"]
        [#return
          {
              "Id" : "all",
              "Name" : "all"
          } ]
    [/#if]

    [#list tiers as knownTier]
        [#if knownTier.Id == tierId]
            [#return knownTier]
        [/#if]
    [/#list]
    [#return {} ]
[/#function]

[#-- Get the id for a tier --]
[#function getTierId tier]
    [#return getTier(tier).Id!""]
[/#function]

[#-- Get the name for a tier --]
[#function getTierName tier]
    [#return getTier(tier).Name!""]
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

[#-- Get the name for a zone --]
[#function getZoneName zone]
    [#if zone?is_hash]
        [#return zone.Name]
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
    [#if component.Type?has_content]
        [#return component.Type]
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
    [#local type = getComponentType(component) ]
    [#list component as key,value]
        [#if key?lower_case == type]
            [#return value]
        [/#if]
    [/#list]
    [#return {} ]
[/#function]

[#-- Get a component within a tier --]
[#function getComponent tierId componentId type=""]
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
            [#return
                component +
                {
                    "Type" : getComponentType(component),
                    "Tier" : tierId
                }]
        [/#if]
    [/#list]
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

            [#local mandatory = attribute?is_hash?then(attribute.Mandatory!false, false) ]
            [#local defaultProvided = attribute?is_hash?then(attribute.Default??, false) ]
            [#local children = attribute?is_hash?then(attribute.Children![], []) ]
            [#local subobjects = attribute?is_hash?then(attribute.Subobjects!false, false) ]
            [#local populateMissingChildren = attribute?is_hash?then(attribute.PopulateMissingChildren!true, true) ]

            [#-- Look for the first name alternative --]
            [#local providedName = ""]
            [#local providedValue = ""]
            [#list attributeNames as attributeName]
                [#if attributeName == "*"]
                    [#local providedName = "*"]
                [/#if]
                [#if providedName?has_content]
                    [#break]
                [#else]
                    [#list candidates?reverse as object]
                        [#if object[attributeName]??]
                            [#local providedName = attributeName ]
                            [#local providedValue = object[attributeName] ]
                            [#break]
                        [/#if]
                    [/#list]
                [/#if]
            [/#list]

            [#-- Name wildcard means include all candidate objects --]
            [#if providedName == "*"]
                [#break]
            [/#if]

            [#-- Throw an exception if a mandatory attribute is missing --]
            [#if mandatory && ( !(providedName?has_content) ) ]
                [@cfException
                    mode=listMode
                    description="Mandatory attribute missing"
                    context=
                        {
                            "ExpectedNames" : attributeNames,
                            "CandidateObjects" : objects
                        }
                /]

                [#-- Provide a value so hopefully generation completes successfully --]
                [#if children?has_content]
                    [#local populateMissingChildren = true ]
                [#else]
                    [#-- providedName just needs to have content --]
                    [#local providedName = "default" ]
                    [#local providedValue = "Mandatory value missing" ]
                [/#if]
            [/#if]

            [#if children?has_content]
                [#local childObjects = [] ]
                [#list candidates as object]
                    [#if object[providedName]??]
                        [#local childObjects += [object[providedName]] ]
                    [/#if]
                [/#list]
                [#if populateMissingChildren || childObjects?has_content]
                    [#local attributeResult = {} ]
                    [#if subobjects ]
                        [#local subobjectKeys = [] ]
                        [#list childObjects as childObject]
                            [#list childObject as key,value]
                                [#if value?is_hash]
                                    [#local subobjectKeys += [key] ]
                                [/#if]
                            [/#list]
                        [/#list]

                        [#list subobjectKeys as subobjectKey ]
                            [#if subobjectKey == "Configuration" ]
                                [#continue]
                            [/#if]
                            [#local subobjectValues = [] ]
                            [#list childObjects as childObject ]
                                [#local subobjectValues +=
                                    [
                                        childObject.Configuration!{},
                                        childObject[subobjectKey]!{}
                                    ]
                                ]
                            [/#list]
                            [#local attributeResult +=
                                {
                                  subobjectKey :
                                      getCompositeObject(
                                          [
                                              {
                                                  "Name" : "Id",
                                                  "Mandatory" : true
                                              },
                                              {
                                                  "Name" : "Name",
                                                  "Mandatory" : true
                                              }
                                          ] +
                                          children,
                                          subobjectValues)
                                }
                            ]
                        [/#list]
                    [#else]
                        [#local attributeResult =
                            populateMissingChildren?then(
                                {
                                    "Configured" : providedName?has_content
                                },
                                {}
                            ) +
                            getCompositeObject(children, childObjects)
                        ]
                    [/#if]
                    [#local result += { attributeNames[0] : attributeResult } ]
                [/#if]
            [#else]
                [#if providedName?has_content ]
                    [#local result +=
                        {
                            attributeNames[0] : providedValue
                        }
                    ]
                [#else]
                    [#if defaultProvided ]
                        [#local result +=
                            {
                                attributeNames[0] : attribute.Default
                            }
                        ]
                    [/#if]
                [/#if]
            [/#if]
        [/#list]
        [#if providedName != "*"]
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
[#function getContextId context]
    [#return
        (context.Id == "default")?then(
            "",
            context.Id
        )
    ]
[/#function]

[#function getContextName context]
    [#return
        getContextId(context)?has_content?then(
            context.Name,
            ""
        )
    ]
[/#function]

[#function getOccurrenceState occurrence]
    [#local result =
        {
            "Resources" : {},
            "Attributes" : {
                "NOATTRIBUTES" : "Attributes not found"
            }
        }
    ]

    [#if occurrence?has_content]
        [#local core = occurrence.Core ]
        [#local configuration = occurrence.Configuration ]

        [#switch core.Type!""]
            [#case "alb"]
                [#local result = getALBState(occurrence)]
                [#break]

            [#case "apigateway"]
                [#local result = getAPIGatewayState(occurrence)]
                [#break]

            [#case "contenthub"]
                [#local result = getContentHubState(occurrence)]
                [#break]

            [#case "contentnode"]
                [#local result = getContentNodeState(occurrence)]
                [#break]

            [#case "ecs"]
                [#local result = getECSState(occurrence)]
                [#break]

            [#case "efs"]
                [#local result = getEFSState(occurrence)]
                [#break]

            [#case "external"]
                [#local result =
                    {
                        "Resources" : {},
                        "Attributes" : {},
                        "Roles" : {
                            "Inbound" : {},
                            "Outbound" : {}
                        }
                    }
                ]
                [#list appSettingsObject!{} as name,value]
                    [#local prefix = core.Component.Name?upper_case + "_"]
                    [#if name?upper_case?starts_with(prefix)]
                        [#local result +=
                        {
                            "Attributes" : result.Attributes + { name?upper_case?remove_beginning(prefix) : value }
                        } ]
                    [/#if]
                [/#list]
                [#list ((credentialsObject[core.Tier.Name + "-" + core.Component.Name])!{})?values as credential]
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
                [#local result = getLambdaState(occurrence)]
                [#break]

            [#case "function"]
                [#local result = getFunctionState(occurrence)]
                [#break]

            [#case "rds"]
                [#local result = getRDSState(occurrence)]
                [#break]

            [#case "s3"]
                [#local result = getS3State(occurrence)]
                [#break]

            [#case "service"]
                [#local result = getServiceState(occurrence)]
                [#break]

            [#case "spa"]
                [#local result = getSPAState(occurrence)]
                [#break]

            [#case "sqs"]
                [#local result = getSQSState(occurrence)]
                [#break]

            [#case "task"]
                [#local result = getTaskState(occurrence)]
                [#break]

            [#case "userpool"]
                [#local result = getUserPoolState(occurrence)]
                [#break]
        [/#switch]
    [/#if]

    [#-- Update resource deployment status --]
    [#list result.Resources as alias,resource]
        [#local result +=
            {
                "Resources" :
                    result.Resources +
                    {
                        alias :
                          resource +
                          {
                              "Deployed" : getExistingReference(resource.Id)?has_content
                          }
                    }
            } ]
    [/#list]
    [#return result ]
[/#function]

[#function getOccurrenceConfigurationAttributes type]
    [#local configuration = componentConfiguration[type]![] ]

    [#return
        configuration?is_hash?then(
            configuration.Attributes![],
            configuration) ]
[/#function]

[#function getOccurrenceSubComponents type]
    [#local configuration = componentConfiguration[type]![] ]

    [#return
        configuration?is_hash?then(
            configuration.Components![],
            []) ]
[/#function]

[#-- Get the occurrences of versions/instances of a component--]
[#function getOccurrencesInternal component tier={} parentOccurrence={} parentContexts=[] componentType="" ]

    [#if !(component?has_content) ]
        [#return [] ]
    [/#if]

    [#local contexts = asArray(parentContexts) + [component] ]

    [#if tier?has_content]
        [#local tierId = getTierId(tier) ]
        [#local tierName = getTierName(tier) ]
        [#local componentId = getComponentId(component) ]
        [#local componentName = getComponentName(component) ]
        [#local subComponentId = "" ]
        [#local subComponentName = "" ]
        [#local type = getComponentType(component) ]
        [#local typeObject = getComponentTypeObject(component) ]
        [#local contexts += [typeObject] ]
    [#else]
        [#local tierId = parentOccurrence.Core.Tier.Id ]
        [#local tierName = parentOccurrence.Core.Tier.Name ]
        [#local componentId = parentOccurrence.Core.Component.Id ]
        [#local componentName = parentOccurrence.Core.Component.Name ]
        [#local subComponentId = getComponentId(component) ]
        [#local subComponentName = getComponentName(component) ]
        [#local type = componentType ]
        [#local typeObject = component ]
    [/#if]

    [#local attributes = getOccurrenceConfigurationAttributes(type) ]
    [#local subComponents = getOccurrenceSubComponents(type) ]

    [#-- Add Export and DeploymentUnits as standard attributes --]
    [#local attributes +=
        [
            {
                "Name" : "Export",
                "Default" : []
            },
            {
                "Name" : "DeploymentUnits",
                "Default" : []
            }
        ]
    ]

    [#local occurrences=[] ]

    [#list (typeObject.Instances!{"default" : {"Id" : "default"}})?values as instance]
        [#if instance?is_hash ]
            [#local instanceId = getContextId(instance) ]
            [#local instanceName = getContextName(instance) ]

            [#list (instance.Versions!{"default" : {"Id" : "default"}})?values as version]
                [#if version?is_hash ]
                    [#local versionId = getContextId(version) ]
                    [#local versionName = getContextName(version) ]
                    [#local contexts += [instance, version] ]
                    [#local occurrence =
                        {
                            "Core" : {
                                "Type" : type,
                                "Tier" : {
                                    "Id" : tierId,
                                    "Name" : tierName
                                },
                                "Component" : {
                                    "Id" : componentId,
                                    "Name" : componentName,
                                    "Type" : type
                                },
                                "Instance" : {
                                    "Id" : firstContent(instanceId, (parentOccurrence.Core.Instance.Id)!""),
                                    "Name" : firstContent(instanceName, (parentOccurrence.Core.Instance.Name)!"")
                                },
                                "Version" : {
                                    "Id" : firstContent(versionId, (parentOccurrence.Core.Version.Id)!""),
                                    "Name" : firstContent(versionName, (parentOccurrence.Core.Version.Name)!"")
                                },
                                "Internal" : {
                                    "IdExtensions" : [subComponentId, instanceId, versionId],
                                    "NameExtensions" : [subComponentName, instanceName, versionName]
                                }
                            } +
                            attributeIfContent(
                                "SubComponent",
                                subComponentId,
                                {
                                    "Id" : subComponentId,
                                    "Name" : subComponentName
                                }
                            ),
                            "Configuration" : getCompositeObject(attributes, contexts)
                        }
                    ]
                    [#local occurrence +=
                        {
                            "Core" :
                                occurrence.Core +
                                {
                                    "Id" :
                                        valueIfContent(
                                            formatId(
                                                (parentOccurrence.Core.Id)!"",
                                                occurrence.Core.Internal.IdExtensions),
                                            parentOccurrence,
                                            formatId(
                                                occurrence.Core.Tier,
                                                occurrence.Core.Component,
                                                occurrence.Core.Internal.NameExtensions)),
                                    "Name" :
                                        valueIfContent(
                                            formatName(
                                                (parentOccurrence.Core.Name)!"",
                                                occurrence.Core.Internal.IdExtensions),
                                            parentOccurrence,
                                            formatName(
                                                occurrence.Core.Tier,
                                                occurrence.Core.Component,
                                                occurrence.Core.Internal.NameExtensions))
                                }
                        } ]
                    [#local occurrence += { "State" : getOccurrenceState(occurrence) } ]

                    [#local subOccurrences = [] ]
                    [#list subComponents as subComponent]
                        [#-- Subcomponent instances can either be under a Components --]
                        [#-- attribute or directly under the subcomponent object.    --]
                        [#-- For the latter case, any default configuration must be  --]
                        [#-- under a Configuration attribute to avoid the            --]
                        [#-- configuration being treated as subcomponent instances.  --]
                        [#local subComponentInstances =
                            (typeObject[subComponent.Component].Components)!
                            (typeObject[subComponent.Component])!
                            {}
                        ]
                        [#list subComponentInstances as key,subComponentInstance ]
                            [#if subComponentInstance?is_hash ]
                                [#if key == "Configuration" ]
                                    [#continue]
                                [/#if]
                                [#local
                                    subOccurrences +=
                                        getOccurrencesInternal(
                                            subComponentInstance,
                                            {},
                                            occurrence,
                                            contexts +
                                                [
                                                    typeObject[subComponent.Component],
                                                    typeObject[subComponent.Component].Configuration!{}
                                                ],
                                            subComponent.Type
                                        )
                                ]
                            [/#if]
                        [/#list]
                    [/#list]

                    [#local occurrences +=
                        [
                            occurrence +
                            attributeIfContent("Occurrences", subOccurrences)
                        ]
                    ]
                [/#if]
            [/#list]
        [/#if]
    [/#list]

    [#return occurrences ]
[/#function]

[#-- Get the occurrences of versions/instances of a component --]
[#function getOccurrences tier component ]
    [#return getOccurrencesInternal(component, tier) ]
[/#function]

[#function getLinkTarget occurrence link]

    [#if link.Tier?lower_case == "external"]
        [#local targetOccurrence =
            {
                "Core" : {
                    "Type" : "external",
                    "Tier" : {
                        "Id" : link.Tier,
                        "Name" : link.Tier
                    },
                    "Component" : {
                        "Id" : link.Component,
                        "Name" : link.Component
                    },
                    "Instance" : {
                        "Id" : "",
                        "Name" : ""
                    },
                    "Version" : {
                        "Id" : "",
                        "Name" : ""
                    }
                },
                "Configuration" : {}
            }
        ]
        [#return
            targetOccurrence +
            {
                "State" : getOccurrenceState(targetOccurrence),
                "Direction" : link.Direction!"outbound"
            } +
            attributeIfContent("Role", link.Role!"")
        ]
    [/#if]

    [#list getOccurrences(
                getTier(link.Tier),
                getComponent(link.Tier, link.Component)) as targetOccurrence]
        [@cfDebug listMode targetOccurrence false /]

        [#local core = targetOccurrence.Core ]

        [#local targetSubOccurrences = [targetOccurrence] ]
        [#local subComponentId = "" ]

        [#-- Check if suboccurrence linking is required --]
        [#local subComponents = getOccurrenceSubComponents(core.Type) ]
        [#list subComponents as subComponent]
            [#local linkAttribute = subComponent.Link!"" ]
            [#local subComponentId = link[linkAttribute]!"" ]
            [#if subComponentId?has_content ]
                [#local targetSubOccurrences = targetOccurrence.Occurrences![] ]
                [#break]
            [/#if]
        [/#list]

        [#-- Legacy support for links to lambda without explicit function --]
        [#if targetOccurrence.Occurrences?has_content &&
                subComponentId == "" &&
                (core.Type == LAMBDA_COMPONENT_TYPE) ]
            [#local subComponentId = (targetOccurrence.Occurrences[0].Core.SubComponent.Id)!"" ]
        [/#if]

        [#if subComponentId?has_content]
            [#local targetSubOccurrences = targetOccurrence.Occurrences![] ]
        [/#if]

        [#list targetSubOccurrences as targetSubOccurrence]
            [#local core = targetSubOccurrence.Core ]

            [#-- Subcomponent checking --]
            [#if subComponentId?has_content &&
                    (subComponentId != (core.SubComponent.Id)!"") ]
                [#continue]
            [/#if]

            [#if core.Version.Id?has_content]
                [#if (core.Instance.Id != occurrence.Core.Instance.Id) ||
                    (core.Version.Id != occurrence.Core.Version.Id) ]
                    [#continue]
                [/#if]
            [/#if]
            [#if core.Instance.Id?has_content]
                [#if (core.Instance.Id != occurrence.Core.Instance.Id) ]
                    [#continue]
                [/#if]
            [/#if]
            [#return
                targetSubOccurrence +
                {
                    "Direction" : link.Direction!"outbound"
                } +
                attributeIfContent("Role", link.Role!"") ]
        [/#list]
    [/#list]

    [@cfPostconditionFailed
        listMode
        "getLinkTarget"
        {
            "Occurrence" : occurrence,
            "Link" : link
        }
        "Link not found" /]

    [#return
        {
            "Core" : {},
            "Configuration" : {},
            "State" : {
                "Resources" : {},
                "Attributes" : {},
                "Roles" : {}
            },
            "Direction" : ""
        } ]
[/#function]

[#function getLinkTargets occurrence links={}]
    [#local result={} ]
    [#list (valueIfContent(links, links, occurrence.Configuration.Links!{}))?values as link]
        [#if link?is_hash]
            [#local linkTarget = getLinkTarget(occurrence, link)!{} ]

            [#local result +=
                valueIfContent(
                    {
                        link.Name : linkTarget
                    },
                    linkTarget
                )]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#function getLinkTargetsOutboundRoles LinkTargets]
    [#local roles = [] ]
    [#list LinkTargets?values as linkTarget]
        [#local linkTargetOutboundRoles = (linkTarget.State.Roles.Outbound)!{} ]
        [#local roleName = linkTarget.Role!linkTargetOutboundRoles["default"]!""]
        [#local role = linkTargetOutboundRoles[roleName]!{} ]
        [#if (linkTarget.Direction == "outbound") && role?has_content ]
            [#local roles += asArray(role![]) ]
        [/#if]
    [/#list]
    [#return roles]
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
                valueIfTrue(occurrence.Core.Instance.Name!"", includes.Instance),
                valueIfTrue(occurrence.Core.Version.Name!"", includes.Version),
                valueIfTrue(segmentName!"", includes.Segment),
                valueIfTrue(environmentName!"", includes.Environment),
                valueIfTrue(productName!"", includes.Product)
            )
        )
    ]
]
[/#function]

[#-- Directory Structure for ContentHubs --]
[#function getContentPath occurrence ]

    [#local core = occurrence.Core ]
    [#local pathObject = occurrence.Configuration.Path ]
    [#local includes = pathObject.IncludeInPath]

    [#local path =  valueIfTrue(
            [
                pathObject.Host
            ],
            pathObject.Host?has_content && (!(includes.Host)),
            [
                valueIfTrue(productName!"", includes.Product),
                valueIfTrue(solutionObject.Id!"", includes.Solution),
                valueIfTrue(environmentName!"", includes.Environment),
                valueIfTrue(segmentName!"", includes.Segment),
                valueIfTrue(getTierName(core.Tier), includes.Tier),
                valueIfTrue(getComponentName(core.Component), includes.Component),
                valueIfTrue(core.Instance.Name!"", includes.Instance),
                valueIfTrue(core.Version.Name!"", includes.Version),
                valueIfTrue(pathObject.Host, includes.Host)
            ]
        )
    ]

    [#if pathObject.Style = "single" ]
        [#return formatName(path) ]
    [#else]
        [#return formatRelativePath(path)]
    [/#if]

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

