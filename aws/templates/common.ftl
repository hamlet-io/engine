[#ftl]

[#-- Utility arrays --]
[#assign powersOf2 = [1] ]
[#list 0..31 as index]
    [#assign powersOf2 += [2*powersOf2[index]] ]
[/#list]

[#-- Utility functions --]

[#function asArray arg flatten=false ignoreEmpty=false]
    [#local result = [] ]
    [#if arg?is_sequence]
        [#if flatten]
            [#list arg as element]
                [#local result += asArray(element, flatten, ignoreEmpty) ]
            [/#list]
        [#else]
            [#if ignoreEmpty]
                [#list arg as element]
                    [#local elementResult = asArray(element, flatten, ignoreEmpty) ]
                    [#if elementResult?has_content]
                        [#local result += valueIfTrue([elementResult], element?is_sequence, elementResult) ]
                    [/#if]
                [/#list]
            [#else]
                [#local result = arg]
            [/#if]
        [/#if]
    [#else]
        [#local result = valueIfTrue([arg], !ignoreEmpty || arg?has_content, []) ]
    [/#if]

    [#return result ]
[/#function]

[#function asFlattenedArray arg ignoreEmpty=false]
    [#return asArray(arg, true, ignoreEmpty) ]
[/#function]

[#function getUniqueArrayElements args...]
    [#local result = [] ]
    [#list args as arg]
        [#list asFlattenedArray(arg) as member]
            [#if !result?seq_contains(member) ]
                [#local result += [member] ]
            [/#if]
        [/#list]
    [/#list]
    [#return result ]
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
      [#if object[id]?? && object[id]?is_hash]
          [#return object + { id : object[id] + descendent } ]
      [/#if]
      [#return object + { id : descendent } ]
    [/#if]
[/#function]

[#function valueIfTrue value condition otherwise={}]
    [#return condition?then(value, otherwise) ]
[/#function]

[#function valueIfContent value content otherwise={}]
    [#return valueIfTrue(value, content?has_content, otherwise) ]
[/#function]

[#function contentIfContent value otherwise={}]
    [#return valueIfTrue(value, value?has_content, otherwise) ]
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
        [#if occurrence.Configuration.Solution.Enabled &&
            deploymentRequired(occurrence.Configuration.Solution, deploymentUnit, false) ]
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

[#-- S3 settings/appdata storage  --]

[#function getSettingsFilePrefix occurrence ]
    [#return formatRelativePath("settings", occurrence.Core.FullRelativePath) ]
[/#function]

[#function getAppDataFilePrefix occurrence={} ]
    [#if occurrence?has_content]
        [#local override =
            getOccurrenceSettingValue(
                occurrence,
                [
                    ["FilePrefixes", "AppData"],
                    ["DefaultFilePrefix"]
                ], true) ]
        [#return
            valueIfContent(
                formatSegmentRelativePath("appdata", override),
                override,
                formatRelativePath("appdata", occurrence.Core.FullRelativePath)
            ) ]
    [#else]
        [#return context.Environment["APPDATA_PREFIX"] ]
    [/#if]
[/#function]

[#function getAppDataPublicFilePrefix occurrence={} ]
    [#if (segmentObject.Data.Public.Enabled)!false]
        [#if occurrence?has_content]
            [#local override =
                getOccurrenceSettingValue(
                    occurrence,
                    [
                        ["FilePrefixes", "AppPublic"],
                        ["FilePrefixes", "AppData"],
                        ["DefaultFilePrefix"]
                    ], true) ]
            [#return
                valueIfContent(
                    formatSegmentRelativePath("apppublic", override),
                    override,
                    formatRelativePath("apppublic", occurrence.Core.FullRelativePath)
                ) ]
        [#else]
            [#return context.Environment["APPDATA_PUBLIC_PREFIX"] ]
        [/#if]
    [#else]
        [#return ""]
    [/#if]
[/#function]

[#function getBackupsFilePrefix occurrence={} ]
    [#if occurrence?has_content ]
        [#return formatRelativePath("backups", occurrence.Core.FullRelativePath) ]
    [#else]
        [#return context.Environment["BACKUPS_PREFIX"] ]
    [/#if]
[/#function]

[#-- Legacy functions - appsettings and credentials now treated the same --]
[#-- These were required in container fragments before permissions were  --]
[#-- automatically added.                                                --]

[#function getCredentialsFilePrefix occurrence={} ]
    [#if occurrence?has_content ]
        [#return getSettingsFilePrefix(occurrence) ]
    [#else]
        [#return context.Environment["SETTINGS_PREFIX"] ]
    [/#if]
[/#function]

[#function getAppSettingsFilePrefix occurrence={} ]
    [#if occurrence?has_content]
        [#return getSettingsFilePrefix(occurrence) ]
    [#else]
        [#return context.Environment["SETTINGS_PREFIX"] ]
    [/#if]
[/#function]

[#-- End legacy functions --]

[#function getSegmentCredentialsFilePrefix  ]
    [#return formatSegmentPrefixPath("credentials")]
[/#function]

[#function getSegmentAppSettingsFilePrefix  ]
    [#return formatSegmentPrefixPath("appsettings")]
[/#function]

[#function getSegmentAppDataFilePrefix ]
    [#return formatSegmentPrefixPath("appdata")]
[/#function]

[#function getSegmentBackupsFilePrefix ]
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

[#function getDeploymentState resources ]
    [#local result = resources ]
    [#if resources?is_hash]
        [#list resources as alias,resource]
            [#if resource.Id?has_content]
                [#local result +=
                    {
                        alias :
                          resource +
                          {
                              "Deployed" : getExistingReference(resource.Id)?has_content
                          }
                    } ]
            [#else]
                [#local result +=
                    {
                        alias : getDeploymentState(resource)
                    } ]
            [/#if]
        [/#list]
    [/#if]
    [#return result]
[/#function]

[#function getOccurrenceState occurrence parentOccurrence]
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
        [#local environment =
            occurrence.Configuration.Environment.General +
            occurrence.Configuration.Environment.Sensitive ]

        [#switch core.Type!""]
            [#case ALB_COMPONENT_TYPE]
                [#local result = getALBState(occurrence)]
                [#break]

            [#case ALB_PORT_COMPONENT_TYPE]
                [#local result = getALBPortState(occurrence, parentOccurrence)]
                [#break]

            [#case "apigateway"]
                [#local result = getAPIGatewayState(occurrence)]
                [#break]

            [#case "cache"]
                [#local result = getCacheState(occurrence)]
                [#break]

            [#case "contenthub"]
                [#local result = getContentHubState(occurrence)]
                [#break]

            [#case "contentnode"]
                [#local result = getContentNodeState(occurrence)]
                [#break]

            [#case "ec2"]
                [#local result = getEC2State(occurrence)]
                [#break]

            [#case "ecs"]
                [#local result = getECSState(occurrence)]
                [#break]

            [#case "efs"]
                [#local result = getEFSState(occurrence)]
                [#break]

            [#case "elb"]
                [#local result = getELBState(occurrence)]
                [#break]

            [#case "es"]
                [#local result = getESState(occurrence)]
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
                [#list environment as name,value]
                    [#local prefix = core.Component.Name?upper_case + "_"]
                    [#if name?starts_with(prefix)]
                        [#local result +=
                        {
                            "Attributes" : result.Attributes + { name?remove_beginning(prefix) : value }
                        } ]
                    [/#if]
                [/#list]
                [#break]

            [#case "function"]
                [#local result = getFunctionState(occurrence)]
                [#break]

            [#case "lambda"]
                [#local result = getLambdaState(occurrence)]
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
    [#local result +=
        {
            "Resources" : getDeploymentState(result.Resources)
        } ]
    [#return result ]
[/#function]

[#function asFlattenedSettings object prefix=""]
    [#local result = {} ]
    [#list object as key,value]
        [#if value?is_hash]
            [#if value.Value??]
                [#local result += {formatSettingName(prefix,key) : value} ]
            [#else]
                [#local result += asFlattenedSettings(value, formatSettingName(prefix, key)) ]
            [/#if]
            [#continue]
        [/#if]
        [#if value?is_sequence]
            [#continue]
        [/#if]
        [#local result += {formatSettingName(prefix, key) : {"Value" : value}} ]
    [/#list]
    [#return result]
[/#function]

[#function markAsSensitive settings]
    [#local result = {} ]
    [#list settings as key,value]
        [#local result += { key : value + {"Sensitive" : true}} ]
    [/#list]
    [#return result ]
[/#function]

[#function getOccurrenceCoreSettings occurrence]
    [#local core = occurrence.Core ]
    [#return
        asFlattenedSettings(
            {
                "TEMPLATE_TIMESTAMP" : .now?iso_utc,
                "PRODUCT" : productName,
                "ENVIRONMENT" : environmentName,
                "SEGMENT" : segmentName,
                "TIER" : core.Tier.Name,
                "COMPONENT" : core.Component.Name,
                "COMPONENT_INSTANCE" : core.Instance.Name,
                "COMPONENT_VERSION" : core.Version.Name,
                "REQUEST_REFERENCE" : requestReference,
                "CONFIGURATION_REFERENCE" : configurationReference,
                "APPDATA_BUCKET" : dataBucket,
                "APPDATA_PREFIX" : getAppDataFilePrefix(occurrence),
                "OPSDATA_BUCKET" : operationsBucket,
                "APPSETTINGS_PREFIX" : getSettingsFilePrefix(occurrence),
                "CREDENTIALS_PREFIX" : getSettingsFilePrefix(occurrence),
                "SETTINGS_PREFIX" : getSettingsFilePrefix(occurrence)
            } +
            attributeIfContent("SUBCOMPONENT", (core.SubComponent.Name)!"") +
            attributeIfContent("APPDATA_PUBLIC_PREFIX", getAppDataPublicFilePrefix(occurrence)) +
            attributeIfContent("SES_REGION", (productObject.SES.Region)!"")
        )
    ]
[/#function]

[#function getOccurrenceSettings possibilities alternatives]
    [#local contexts = [] ]

    [#-- Order possibilities in increasing priority --]
    [#list possibilities?keys?sort as key]
        [#local matchKey = key?lower_case?remove_ending("-asfile") ]
        [#local value = possibilities[key] ]
        [#if value?has_content]
            [#list alternatives as alternative]
                [#if
                    (
                        ((alternative.Match == "exact") && (alternative.Key == matchKey)) ||
                        ((alternative.Match == "partial") && (alternative.Key?starts_with(matchKey)))
                    ) ]
                    [#local contexts += [value] ]
                [/#if]
            [/#list]
        [/#if]
    [/#list]
    [#return asFlattenedSettings(getCompositeObject({ "Name" : "*" }, contexts)) ]
[/#function]

[#function getOccurrenceAccountSettings occurrence]
    [#local alternatives = [{"Key" : accountName, "Match" : "exact"}] ]
    [#return
        getOccurrenceSettings(
            (settingsObject.AppSettings.Accounts)!{},
            alternatives) ]
[/#function]

[#function getOccurrenceBuildSettings occurrence]
    [#local deploymentUnit = (occurrence.Configuration.Solution.DeploymentUnits[0])!"" ]

    [#local alternatives =
        [
            {"Key" : formatSegmentFullName(deploymentUnit), "Match" : "exact"},
            {"Key" : occurrence.Core.FullName, "Match" : "partial"},
            {"Key" : occurrence.Core.TypedFullName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortFullName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortTypedFullName, "Match" : "partial"}
        ] ]

    [#local occurrenceBuild =
        getOccurrenceSettings(
            (settingsObject.Builds.Products)!{},
            alternatives
        ) ]

    [#-- Reference could be a deployment unit or a component --]
    [#if occurrenceBuild.REFERENCE?has_content]
        [#local occurrenceBuild +=
            getOccurrenceSettings(
                (settingsObject.Builds.Products)!{},
                [
                    {"Key" : formatSegmentFullName(occurrenceBuild.REFERENCE.Value?replace("/","-")), "Match" : "exact"}
                ]
            ) ]
    [/#if]

    [#return
        attributeIfContent(
            "BUILD_REFERENCE",
            occurrenceBuild.COMMIT!{}
        ) +
        attributeIfContent(
            "BUILD_UNIT",
            occurrenceBuild.UNIT!
            valueIfContent(
                {"Value" : (occurrenceBuild.REFERENCE.Value?replace("/","-"))!""},
                occurrenceBuild.REFERENCE!{},
                valueIfContent(
                    {"Value" : deploymentUnit},
                    deploymentUnit
                )
            )
        ) +
        attributeIfContent(
            "APP_REFERENCE"
            occurrenceBuild.TAG!{}
        ) ]
[/#function]

[#function getOccurrenceProductSettings occurrence ]
    [#local deploymentUnit = (occurrence.Configuration.Solution.DeploymentUnits[0])!"" ]

    [#local alternatives =
        [
            {"Key" : formatSegmentFullName(deploymentUnit), "Match" : "exact"},
            {"Key" : occurrence.Core.FullName, "Match" : "partial"},
            {"Key" : occurrence.Core.TypedFullName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortFullName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortTypedFullName, "Match" : "partial"}
        ] ]

    [#return
        getOccurrenceSettings(
            (settingsObject.AppSettings.Products)!{},
            alternatives) ]
[/#function]


[#function getOccurrenceCredentialSettings occurrence]
    [#local deploymentUnit = (occurrence.Configuration.Solution.DeploymentUnits[0])!"" ]

    [#local buildDeploymentUnit =
        (settingsObject.Builds.Products[formatSegmentFullName(deploymentUnit)].Reference)!"" ]

    [#local alternatives =
        [
            {"Key" : formatSegmentFullName(buildDeploymentUnit), "Match" : "exact"},
            {"Key" : formatSegmentFullName(deploymentUnit), "Match" : "exact"},
            {"Key" : occurrence.Core.FullName, "Match" : "partial"},
            {"Key" : occurrence.Core.TypedFullName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortFullName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortTypedFullName, "Match" : "partial"}
        ] ]

    [#return
        markAsSensitive(
            getOccurrenceSettings(
                (settingsObject.Credentials.Products)!{},
                alternatives) ) ]
[/#function]

[#-- Try to match the desired setting in decreasing specificity --]
[#-- A single match array or an array of arrays can be provided --]
[#function getOccurrenceSetting occurrence names emptyIfNotProvided=false]
    [#local nameAlternatives = asArray(names) ]
    [#if !(nameAlternatives[0]?is_sequence) ]
      [#local nameAlternatives = [nameAlternatives] ]
    [/#if]
    [#local settingNames = [] ]
    [#local setting = {} ]

    [#list nameAlternatives as nameAlternative]
        [#local nameParts = asArray(nameAlternative) ]
        [#list nameParts as namePart]
            [#local settingNames +=
                [formatSettingName(nameParts[namePart?index..])] ]
        [/#list]
    [/#list]

    [#list settingNames as settingName]
        [#local setting =
            contentIfContent(
                (occurrence.Configuration.Settings.Build[settingName])!{},
                contentIfContent(
                    (occurrence.Configuration.Settings.Product[settingName])!{},
                    contentIfContent(
                        (occurrence.Configuration.Settings.Account[settingName])!{},
                        (occurrence.Configuration.Settings.Core[settingName])!{}
                    )
                )
            ) ]
        [#if setting?has_content]
            [#break]
        [/#if]
    [/#list]

    [#return
        contentIfContent(
            setting,
            valueIfTrue(
                {"Value" : ""},
                emptyIfNotProvided,
                {"Value" : "COTException: Setting not provided"}
            )
        ) ]
[/#function]

[#function getOccurrenceSettingValue occurrence names emptyIfNotProvided=false]
    [#return getOccurrenceSetting(occurrence, names, emptyIfNotProvided).Value]
[/#function]

[#function getOccurrenceBuildReference occurrence]
    [#return
        contentIfContent(
            getOccurrenceSettingValue(occurrence, "BUILD_REFERENCE", true),
            "COTException: Build reference not found") ]
[/#function]

[#function getOccurrenceBuildUnit occurrence]
    [#return
        contentIfContent(
            getOccurrenceSettingValue(occurrence, "BUILD_UNIT", true),
            "COTException: Build unit not found"
        ) ]
[/#function]

[#function getAsFileSettings settings ]
    [#local result = [] ]
    [#list settings as key,value]
        [#if value?is_hash && value.AsFile?has_content]
                [#local result += [value] ]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#function syncFilesToBucket settings bucket prefix]
    [#-- Create an array for the files --]
    [#local result = ["filePathsToSynch=()"] ]
    [#list settings as setting]
        [#local result += ["filePathsToSynch+=(\"" + setting.AsFile + "\")"] ]
    [/#list]
    [#local result += ["#"] ]

    [#-- Locate where each file is --]
    [#local result +=
        [
            "filesToSynch=()",
            "dirsToCheck=(\"$\{SEGMENT_APPSETTINGS_DIR}\")",
            "dirsToCheck+=(\"$\{SEGMENT_CREDENTIALS_DIR}\")",
            "#",
            "for f in \"$\{filePathsToSynch[@]}\"; do",
            "  for d in \"$\{dirsToCheck[@]}\"; do",
            "    if [[ -f \"$\{d}/$\{f}\" ]]; then",
            "      filesToSynch+=(\"$\{d}/$\{f}\")",
            "      break",
            "  done",
            "done",
            "#"
        ] ]

    [#-- Perform the h --]
    [#local result +=
        [
            "case $\{STACK_OPERATION} in",
            "  delete)",
            "    deleteTreeFromBucket" + " " +
                "\"" + regionId + "\"" + " " +
                "\"" + bucket   + "\"" + " " +
                "\"" + prefix   + "\"" + " " +
                "|| return $?",
            "    ;;",
            "  create|update)",
            "    synchFilesToBucket"    + " " +
                "\"" + regionId + "\"" + " " +
                "\"" + bucket   + "\"" + " " +
                "\"" + prefix   + "\"" + " " +
                "filesToSynch --delete || return $?",
            "    ;;",
            " esac"
        ] ]
    [#return result ]
[/#function]

[#function getSettingsAsEnvironment settings sensitive=false obfuscate=false]
    [#local result = {} ]
    [#list settings as key,value]
        [#if value?is_hash]
            [#if sensitive && value.Sensitive!false]
                [#local result += { key : valueIfTrue("****", obfuscate, value.Value)} ]
                [#continue]
            [/#if]
            [#if (!sensitive) && !(value.Sensitive!false)]
                [#local result += { key : value.Value} ]
                [#continue]
            [/#if]
        [#else]
            [#local result += { key, "COTException:Internal error - setting is not a hash" } ]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#function getOccurrenceSettingsAsEnvironment occurrence sensitive=false obfuscate=false]
    [#return
        getSettingsAsEnvironment(occurrence.Configuration.Settings.Core, sensitive, obfuscate) +
        getSettingsAsEnvironment(occurrence.Configuration.Settings.Product, sensitive, obfuscate)
    ]
[/#function]

[#function getOccurrenceSolutionAttributes type]
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

[#-- Migrate any older component structures to what's now expected --]
[#function migrateComponent component type]
    [#local result = component]
        [#switch type]
            [#case "alb"]
                [#return migrateALBComponent(component) ]
                [#break]
        [/#switch]
    [#return result]
[/#function]

[#-- Get the occurrences of versions/instances of a component           --]
[#-- This function should NOT be called directly - it is for the use of --]
[#-- other functions in this file                                       --]
[#function getOccurrencesInternal component tier={} parentOccurrence={} parentContexts=[] componentType="" ]

    [#if !(component?has_content) ]
        [#return [] ]
    [/#if]

    [#local componentContexts = asArray(parentContexts) ]

    [#if tier?has_content]
        [#local type = getComponentType(component) ]
        [#local typeObject = migrateComponent(getComponentTypeObject(component), type) ]
    [#else]
        [#local type = componentType ]
        [#local typeObject = migrateComponent(component, type) ]
    [/#if]

    [#if tier?has_content]
        [#local tierId = getTierId(tier) ]
        [#local tierName = getTierName(tier) ]
        [#local componentId = getComponentId(component) ]
        [#local componentName = getComponentName(component) ]
        [#local subComponentId = [] ]
        [#local subComponentName = [] ]
        [#local componentContexts += [component, typeObject] ]
    [#else]
        [#local tierId = parentOccurrence.Core.Tier.Id ]
        [#local tierName = parentOccurrence.Core.Tier.Name ]
        [#local componentId = parentOccurrence.Core.Component.Id ]
        [#local componentName = parentOccurrence.Core.Component.Name ]
        [#local subComponentId = typeObject.Id?split("-") ]
        [#local subComponentName = typeObject.Name?split("-") ]
        [#local componentContexts += [typeObject] ]
    [/#if]

    [#local attributes = getOccurrenceSolutionAttributes(type) ]
    [#local subComponents = getOccurrenceSubComponents(type) ]

    [#-- Add standard attributes --]
    [#local attributes +=
        [
            {
                "Name" : "Enabled",
                "Default" : true
            },
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
                    [#local occurrenceContexts = componentContexts + [instance, version] ]
                    [#local idExtensions =
                                subComponentId +
                                asArray(instanceId, true, true) +
                                asArray(versionId, true, true) ]
                    [#local nameExtensions =
                                subComponentName +
                                asArray(instanceName, true, true) +
                                asArray(versionName, true, true) ]
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
                                    "IdExtensions" : idExtensions,
                                    "NameExtensions" : nameExtensions
                                },
                                "Extensions" : {
                                    "Id" :
                                        ((parentOccurrence.Core.Extensions.Id)![tierId, componentId]) + idExtensions,
                                    "Name" :
                                        ((parentOccurrence.Core.Extensions.Name)![tierName, componentName]) + nameExtensions
                                }

                            } +
                            attributeIfContent(
                                "SubComponent",
                                subComponentId,
                                {
                                    "Id" : formatId(subComponentId),
                                    "Name" : formatName(subComponentName)
                                }
                            ),
                            "Configuration" : {
                                "Solution" : getCompositeObject(attributes, occurrenceContexts)
                            }
                        }
                    ]
                    [#local occurrence +=
                        {
                            "Core" :
                                occurrence.Core +
                                {
                                    "Id" : formatId(occurrence.Core.Extensions.Id),
                                    "TypedId" : formatId(occurrence.Core.Extensions.Id, type),
                                    "Name" : formatName(occurrence.Core.Extensions.Name),
                                    "TypedName" : formatName(occurrence.Core.Extensions.Name, type),
                                    "FullName" : formatSegmentFullName(occurrence.Core.Extensions.Name),
                                    "TypedFullName" : formatSegmentFullName(occurrence.Core.Extensions.Name, type),
                                    "ShortName" : formatName(occurrence.Core.Extensions.Id),
                                    "ShortTypedName" : formatName(occurrence.Core.Extensions.Id, type),
                                    "ShortFullName" : formatSegmentShortName(occurrence.Core.Extensions.Id),
                                    "ShortTypedFullName" : formatSegmentShortName(occurrence.Core.Extensions.Id, type),
                                    "RelativePath" : formatRelativePath(occurrence.Core.Extensions.Name),
                                    "FullRelativePath" : formatSegmentRelativePath(occurrence.Core.Extensions.Name),
                                    "AbsolutePath" : formatAbsolutePath(occurrence.Core.Extensions.Name),
                                    "FullAbsolutePath" : formatSegmentAbsolutePath(occurrence.Core.Extensions.Name)
                                }
                        } ]

                    [#local occurrence +=
                        {
                            "Configuration" :
                                occurrence.Configuration +
                                {
                                    "Settings" : {
                                        "Build" : getOccurrenceBuildSettings(occurrence),
                                        "Core" : getOccurrenceCoreSettings(occurrence),
                                        "Account" : getOccurrenceAccountSettings(occurrence),
                                        "Product" :
                                            getOccurrenceProductSettings(occurrence) +
                                            getOccurrenceCredentialSettings(occurrence)
                                    }
                                }
                        } ]
                    [#local occurrence +=
                        {
                            "Configuration" :
                                occurrence.Configuration +
                                {
                                    "Environment" : {
                                        "Build" :
                                            getSettingsAsEnvironment(occurrence.Configuration.Settings.Build),
                                        "General" :
                                            getOccurrenceSettingsAsEnvironment(occurrence, false),
                                        "Sensitive" :
                                            getOccurrenceSettingsAsEnvironment(occurrence, true)
                                    }
                                }
                        } ]
                    [#local occurrence +=
                        {
                            "State" : getOccurrenceState(occurrence, parentOccurrence)

                        } ]
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
                                            occurrenceContexts +
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

    [#local instanceToMatch = link.Instance!occurrence.Core.Instance.Id ]
    [#local versionToMatch = link.Version!occurrence.Core.Version.Id ]

    [@cfDebug
        listMode
        {
            "Text" : "Getting link Target",
            "Occurrence" : occurrence,
            "Link" : link,
            "EffectiveInstance" : instanceToMatch,
            "EffectiveVersion" : versionToMatch
        }
        false
    /]
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
                "Configuration" : {
                    "Environment" : occurrence.Configuration.Environment
                }
            }
        ]
        [#return
            targetOccurrence +
            {
                "State" : getOccurrenceState(targetOccurrence, {}),
                "Direction" : link.Direction!"outbound"
            } +
            attributeIfContent("Role", link.Role!"")
        ]
    [/#if]

    [#list getOccurrences(
                getTier(link.Tier),
                getComponent(link.Tier, link.Component)) as targetOccurrence]

        [@cfDebug
            listMode
            {
                "Text" : "Possible link target",
                "Occurrence" : targetOccurrence
            }
            false
        /]

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
                [#-- Hack for port name to number conversion --]
                [#if (linkAttribute == "Port") && subComponentId?is_string ]
                    [#local subComponentId = (ports[subComponentId].Port?c)!subComponentId ]
                [/#if]
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

            [#-- Match needs to be exact                            --]
            [#-- If occurrences don't match, overrides can be added --]
            [#-- to the link.                                       --]
            [#if (core.Instance.Id != instanceToMatch) ||
                (core.Version.Id != versionToMatch) ]
                [#continue]
            [/#if]

            [@cfDebug listMode "Link matched target" false /]

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
            "Link" : link,
            "EffectiveInstance" : instanceToMatch,
            "EffectiveVersion" : versionToMatch
        }
        "COTException:Link not found" /]

    [#return {} ]
[/#function]

[#function getLinkTargets occurrence links={}]
    [#local result={} ]
    [#list (valueIfContent(links, links, occurrence.Configuration.Solution.Links!{}))?values as link]
        [#if link?is_hash]
            [#local linkTarget = getLinkTarget(occurrence, link) ]
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

[#function getHostName certificateObject occurrence]

    [#local core = occurrence.Core ]
    [#local includes = certificateObject.IncludeInHost ]

    [#return
        valueIfTrue(
            certificateObject.Host,
            certificateObject.Host?has_content && (!(includes.Host)),
            formatName(
                valueIfTrue(certificateObject.Host, includes.Host),
                valueIfTrue(getTierName(core.Tier), includes.Tier),
                valueIfTrue(getComponentName(core.Component), includes.Component),
                valueIfTrue(core.Instance.Name!"", includes.Instance),
                valueIfTrue(core.Version.Name!"", includes.Version),
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
    [#local pathObject = occurrence.Configuration.Solution.Path ]
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

[#-- CIDRs --]
[#function asCIDR value mask]
    [#local remainder = value]
    [#local result = []]
    [#list 0..3 as index]
        [#local result = [remainder % 256] + result]
        [#local remainder = (remainder / 256)?int ]
    [/#list]
    [#return [result?join("."), mask]?join("/")]
[/#function]

[#function analyzeCIDR cidr ]
    [#local re = cidr?matches(r"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})") ]
    [#if !re ]
        [#return {}]
    [/#if]

    [#local ip = re?groups[1] ]
    [#local mask = re?groups[2]?number ]
    [#local parts = re?groups[1]?split(".") ]
    [#local partMasks = [] ]
    [#list 0..3 as index]
        [#local partMask = mask - 8*index ]
        [#if partMask gte 8]
            [#local partMask = 8 ]
        [/#if]
        [#if partMask lte 0]
            [#local partMask = 0 ]
        [/#if]
        [#local partMasks += [partMask] ]
    [/#list]

    [#local base = [] ]
    [#list 0..3 as index]
        [#local partBits = partMasks[index] ]
        [#local partValue = parts[index]?number ]
        [#local baseValue = 0]
        [#list 7..0 as bit]
            [#if partBits lte 0]
                [#break]
            [/#if]
            [#if partValue gte powersOf2[bit] ]
                [#local baseValue += powersOf2[bit] ]
                [#local partValue -= powersOf2[bit] ]
            [/#if]
            [#local partBits -= 1]
        [/#list]
        [#local base += [baseValue] ]
    [/#list]
    [#local offset = base[3] + 256*(base[2] + 256*(base[1] + 256*base[0])) ]

    [#return
        {
            "IP" : ip,
            "Mask" : mask,
            "Parts" : parts,
            "PartMasks" : partMasks,
            "Base" : base,
            "Offset" : offset
        }
    ]
[/#function]

[#function expandCIDR cidrs... ]
    [#local boundaries=[8,16,24,32] ]
    [#local boundaryOffsets=[24,16,8,0] ]
    [#local result = [] ]
    [#list asFlattenedArray(cidrs) as cidr]

        [#local analyzedCIDR = analyzeCIDR(cidr) ]
        [@cfDebug listMode analyzedCIDR false /]

        [#if !analyzedCIDR?has_content]
            [#continue]
        [/#if]
        [#list 0..boundaries?size-1 as index]
            [#local boundary = boundaries[index] ]
            [#if boundary == analyzedCIDR.Mask]
                [#local result += [cidr] ]
                [#break]
            [/#if]
            [#if boundary > analyzedCIDR.Mask]
                [#local nextCIDR = analyzedCIDR.Offset ]
                [#list 0..powersOf2[boundary - analyzedCIDR.Mask]-1 as increment]
                    [#local result += [asCIDR(nextCIDR, boundary)] ]
                    [#local nextCIDR += powersOf2[boundaryOffsets[index]] ]
                [/#list]
                [#break]
            [/#if]
        [/#list]
    [/#list]
    [#return result]
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
                [#local result = "\"" + obj?json_string + "\""]
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

