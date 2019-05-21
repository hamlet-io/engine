[#ftl]

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
            formatRelativePath(
                "appdata",
                valueIfContent(
                    formatSegmentRelativePath(override),
                    override,
                    occurrence.Core.FullRelativePath
                )
            ) ]
    [#else]
        [#return _context.Environment["APPDATA_PREFIX"] ]
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
                formatRelativePath(
                    "apppublic",
                    valueIfContent(
                        formatSegmentRelativePath(override),
                        override,
                        occurrence.Core.FullRelativePath
                    )
                ) ]
        [#else]
            [#return _context.Environment["APPDATA_PUBLIC_PREFIX"] ]
        [/#if]
    [#else]
        [#return ""]
    [/#if]
[/#function]

[#function getBackupsFilePrefix occurrence={} ]
    [#if occurrence?has_content ]
        [#return formatRelativePath("backups", occurrence.Core.FullRelativePath) ]
    [#else]
        [#return _context.Environment["BACKUPS_PREFIX"] ]
    [/#if]
[/#function]

[#-- Legacy functions - appsettings and credentials now treated the same --]
[#-- These were required in container fragments before permissions were  --]
[#-- automatically added.                                                --]

[#function getCredentialsFilePrefix occurrence={} ]
    [#if occurrence?has_content ]
        [#return getSettingsFilePrefix(occurrence) ]
    [#else]
        [#return _context.Environment["SETTINGS_PREFIX"] ]
    [/#if]
[/#function]

[#function getAppSettingsFilePrefix occurrence={} ]
    [#if occurrence?has_content]
        [#return getSettingsFilePrefix(occurrence) ]
    [#else]
        [#return _context.Environment["SETTINGS_PREFIX"] ]
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
            [#switch key?lower_case]
                [#case "id"]
                [#case "name"]
                [#case "title"]
                [#case "description"]
                [#case "deploymentunits"]
                [#case "multiaz"]
                    [#break]
                [#-- Backwards Compatability for Component renaming --]
                [#case ALB_COMPONENT_TYPE ]
                    [#return LB_COMPONENT_TYPE]
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
        [#-- Backwards Compatability for Component renaming --]
        [#elseif key?lower_case == ALB_COMPONENT_TYPE && type == LB_COMPONENT_TYPE ]
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

[#-- Qualification support --

A qualifier allows the value used for a part of a JSON document to vary depending on
the context. An example might be varying settings depending on the current environment.
If no qualifier applies, then a "default" value applies.

Central to the operation of qualification is the idea of a filter. A filter consists of one or
more values for each of one or more filter attributes. A "MatchBehaviour" is used to compare filters
for a match.

The current context is represented by the "Context Filter". It is managed dynamically during
template processing, and contains values such as the current tenant, product, environment etc.

Each qualifier has a filter and a value. If the filter matches the Context Filter,
then the qualifier value is used to amend the default value which applies if no qualifier matches.
More than one qualifier may match, in which case they are processed in the order they are defined,
and the result of one match becomes the default for the next match.

One way to think of filters is in terms of Venn Diagrams. Each filter defines a set of configuration
entities and if the sets overlap based on the FilterBehaviour, then the qualifier applies. (A similar
logic is applied for links, where the link filter needs to define a set containing a single,
"component" configuration entity.)

The way in which the default value is modified is controlled by the "DefaultBehaviour" of the
qualifier. Typically this means simple values will be replaced and for objects,
the default value is prefix added to the qualifier value.

One or more qualifiers can be added at any point in the JSON document via a reserved "Qualifiers"
entity. Where the qualified entity is not itself an object, the desired entity is
wrapped in an object in order that qualifiers can be attached. In this case, the default value
should be provided via a "Default" attribute at the same level as the "Qualifiers" attribute.

There is a short form and a long form for qualifiers.

In the short form, the "Qualifiers" entity is an object and each attribute represents a qualifier.
The attribute name is the value of the filter "Any" attribute, and the MatchBehaviour is "any",
meaning the value of the Any attribute needs to match one value in any of the attributes of the
Context Filter. The qualifier value is the value of the attribute. Because object attribute
processing is not ordered, the short form does not provide fine control in the situation where
multiple qualifiers match - effectively they need to be independent.

The short form is useful for simple situations such as setting variation based on environment.

In the long form, the "Qualifiers" entity is an array of qualifier objects. Each qualifier object
must have a "Filter" attribute and a "Value" attribute, as well as optional "MatchBehaviour" and
"DefaultBehaviour" attributes. By default, the MatchBehaviour is "onetoone", meaning a value of
each attribute of the qualifier filter must match a value of the same named attribute in the Context
Filter.

The long form gives full control over the qualification process, and allows ordering of qualifier
application, depending on the DefaultBehaviour selected.

Note that override (hierarchy) behaviour takes precedence over qualifier (at level variation)
behaviour.

--]


[#assign contextFilter = {} ]

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

[#-- Formulate a composite object based on                                            --]
[#--   * order precedence - lowest to highest, then                                   --]
[#--   * qualifiers - less specific to more specific                                  --]
[#-- If no attributes are provided, simply combine the qualified objects              --]
[#-- It is also possible to define an attribute with a name of "*" which will trigger --]
[#-- the combining of the objects in addition to any attributes already created       --]
[#function getCompositeObject attributes=[] objects...]

    [#-- Ignore any candidate that is not a hash --]
    [#local candidates = [] ]
    [#list asFlattenedArray(objects) as element]
        [#if element?is_hash]
            [#local candidates += [element] ]
        [/#if]
    [/#list]

    [#-- Normalise attributes --]
    [#local normalisedAttributes = [] ]
    [#local inhibitEnabled = false]
    [#local explicitEnabled = false]
    [#if attributes?has_content]
        [#list asFlattenedArray(attributes) as attribute]
            [#local normalisedAttribute =
                {
                    "Names" : asArray(attribute),
                    "Types" : [ANY_TYPE],
                    "Mandatory" : false,
                    "DefaultBehaviour" : "ignore",
                    "DefaultProvided" : false,
                    "Default" : "",
                    "Values" : [],
                    "Children" : [],
                    "SubObjects" : false,
                    "PopulateMissingChildren" : true
                } ]
            [#if normalisedAttribute.Names?seq_contains("InhibitEnabled") ]
                [#local inhibitEnabled = true ]
            [/#if]
            [#if attribute?is_hash ]
                [#local names = attribute.Names!"COT:Missing" ]
                [#if (names?is_string) && (names == "COT:Missing") ]
                    [@cfException
                        mode=listMode
                        description="Attribute must have a \"Names\" attribute"
                        context=attribute
                    /]
                [/#if]
                [#local normalisedAttribute =
                    {
                        "Names" : asArray(names),
                        "Types" : asArray(attribute.Types!attribute.Type!ANY_TYPE),
                        "Mandatory" : attribute.Mandatory!false,
                        "DefaultBehaviour" : attribute.DefaultBehaviour!"ignore",
                        "DefaultProvided" : attribute.Default??,
                        "Default" : attribute.Default!"",
                        "Values" : asArray(attribute.Values![]),
                        "Children" : asArray(attribute.Children![]),
                        "SubObjects" : attribute.SubObjects!attribute.Subobjects!false,
                        "PopulateMissingChildren" : attribute.PopulateMissingChildren!true
                    } ]
            [/#if]
            [#local normalisedAttributes += [normalisedAttribute] ]
            [#local explicitEnabled = explicitEnabled || normalisedAttribute.Names?seq_contains("Enabled") ]
        [/#list]
        [#if (!explicitEnabled) && (!inhibitEnabled) ]
            [#-- Put "Enabled" first to ensure it is processed in case a name of "*" is used --]
            [#local normalisedAttributes =
                [
                    {
                        "Names" : ["Enabled"],
                        "Types" : [BOOLEAN_TYPE],
                        "Mandatory" : false,
                        "DefaultBehaviour" : "ignore",
                        "DefaultProvided" : true,
                        "Default" : true,
                        "Values" : [],
                        "Children" : [],
                        "SubObjects" : false,
                        "PopulateMissingChildren" : true
                    }
                ] +
                normalisedAttributes ]
        [/#if]
    [/#if]

    [#-- Determine the attribute values --]
    [#local result = {} ]
    [#if normalisedAttributes?has_content]
        [#list normalisedAttributes as attribute]

            [#local populateMissingChildren = attribute.PopulateMissingChildren ]

            [#-- Look for the first name alternative --]
            [#local providedName = ""]
            [#local providedValue = ""]
            [#local providedCandidate = {}]
            [#list attribute.Names as attributeName]
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
                            [#local providedCandidate = object ]
                            [#break]
                        [/#if]
                    [/#list]
                [/#if]
            [/#list]

            [#-- Name wildcard means include all candidate objects --]
            [#if providedName == "*"]
                [#break]
            [/#if]

            [#-- Throw an exception if a mandatory attribute is missing      --]
            [#-- If no candidates, assume we are entirely populating missing --]
            [#-- children so ignore mandatory check                          --]
            [#if attribute.Mandatory &&
                    ( !(providedName?has_content) ) &&
                    candidates?has_content ]
                [@cfException
                    mode=listMode
                    description="Mandatory attribute missing"
                    context=
                        {
                            "ExpectedNames" : attribute.Names,
                            "CandidateObjects" : objects
                        }
                /]

                [#-- Provide a value so hopefully generation completes successfully --]
                [#if attribute.Children?has_content]
                    [#local populateMissingChildren = true ]
                [#else]
                    [#-- providedName just needs to have content --]
                    [#local providedName = "default" ]
                    [#local providedValue = "Mandatory value missing" ]
                [/#if]
            [/#if]

            [#if attribute.Children?has_content]
                [#local childObjects = [] ]
                [#list candidates as object]
                    [#if object[providedName]??]
                        [#local childObjects += [object[providedName]] ]
                    [/#if]
                [/#list]
                [#if populateMissingChildren || childObjects?has_content]
                    [#local attributeResult = {} ]
                    [#if attribute.SubObjects ]
                        [#local subobjectKeys = [] ]
                        [#list childObjects as childObject]
                            [#if childObject?is_hash]
                              [#list childObject as key,value]
                                  [#if value?is_hash]
                                      [#local subobjectKeys += [key] ]
                                  [/#if]
                              [/#list]
                            [#else]
                              [@cfException
                                mode=listMode
                                description="Child content is not a hash"
                                context=childObject /]
                            [/#if]
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
                                                  "Names" : "Id",
                                                  "Mandatory" : true
                                              },
                                              {
                                                  "Names" : "Name",
                                                  "Mandatory" : true
                                              }
                                          ] +
                                          attribute.Children,
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
                            getCompositeObject(attribute.Children, childObjects)
                        ]
                    [/#if]
                    [#local result += { attribute.Names[0] : attributeResult } ]
                [/#if]
            [#else]
                [#-- Combine any provided and/or default values --]
                [#if providedName?has_content ]
                    [#-- Perform type conversion and type checking --]
                    [#local providedValue = asType(providedValue, attribute.Types) ]
                    [#if !isOfType(providedValue, attribute.Types) ]
                        [@cfException
                          mode=listMode
                          description="Attribute is not of the correct type"
                          context=
                            {
                                "Name" : providedName,
                                "Value" : providedValue,
                                "ExpectedTypes" : attribute.Types,
                                "Candidate" : providedCandidate
                            } /]
                    [#else]
                        [#if attribute.Values?has_content]
                            [#list asArray(providedValue) as value]
                                [#if !(attribute.Values?seq_contains(value)) ]
                                    [@cfException
                                      mode=listMode
                                      description="Attribute value is not one of the expected values"
                                      context=
                                        {
                                            "Name" : providedName,
                                            "Value" : value,
                                            "ExpectedValues" : attribute.Values,
                                            "Candidate" : providedCandidate
                                        } /]
                                [/#if]
                            [/#list]
                        [/#if]
                    [/#if]

                    [#if attribute.DefaultProvided ]
                        [#switch attribute.DefaultBehaviour]
                            [#case "prefix"]
                                [#local providedValue = attribute.Default + providedValue ]
                                [#break]
                            [#case "postfix"]
                                [#local providedValue = providedValue + attribute.Default]
                                [#break]
                            [#case "ignore"]
                            [#default]
                                [#-- Ignore default --]
                                [#break]
                        [/#switch]
                    [/#if]
                    [#local result +=
                        {
                            attribute.Names[0] : providedValue
                        } ]
                [#else]
                    [#if attribute.DefaultProvided ]
                        [#local result +=
                            {
                                attribute.Names[0] : attribute.Default
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
        [#local result += object ]
    [/#list]
    [#return result ]
[/#function]

[#-- Check if a configuration item with children is present --]
[#function isPresent configuration={} ]
    [#return (configuration.Configured!false) && (configuration.Enabled!false) ]
[/#function]

[#function getObjectLineage collection end qualifiers...]
    [#local result = [] ]
    [#local endingObject = "" ]
    [#list asFlattenedArray(end) as endEntry]
        [#if endEntry?is_hash]
            [#local endingObject = endEntry ]
            [#break]
        [#else]
            [#if endEntry?is_string]
                [#if ((collection[endEntry])!"")?is_hash]
                    [#local endingObject = collection[endEntry] ]
                    [#break]
                [/#if]
            [/#if]
        [/#if]
    [/#list]

    [#if endingObject?is_hash]
        [#local base = getObjectAndQualifiers(endingObject, qualifiers) ]
        [#local parentId =
                (getCompositeObject(
                    [
                        {
                            "Names" : "Parent",
                            "Type" : STRING_TYPE
                        }
                    ],
                    base
                ).Parent)!"" ]
        [#local parentIds =
                (getCompositeObject(
                    [
                        {
                            "Names" : "Parents",
                            "Type" : ARRAY_OF_STRING_TYPE
                        }
                    ],
                    base
                ).Parents)!arrayIfContent(parentId, parentId) ]

        [#if parentIds?has_content]
            [#list parentIds as parentId]
                [#local lines = getObjectLineage(collection, parentId, qualifiers) ]
                [#list lines as line]
                    [#local result += [ line + [base] ] ]
                [/#list]
            [/#list]
        [#else]
            [#local result += [ [base] ] ]
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

[#function isOneResourceDeployed resources ]
    [#if resources?is_hash]
        [#if resources?has_content ]
            [#list resources as alias,resource]
                [#if resource.Id?has_content]
                    [#if resource.Deployed]
                        [#return true]
                    [/#if]
                [#else]
                    [#if isOneResourceDeployed(resource) ]
                        [#return true]
                    [/#if]
                [/#if]
            [/#list]
        [#else]
            [#return true]
        [/#if]
    [/#if]
    [#return false]
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

        [#if (core.External!false) || ((core.Type!"") == "external") ]
            [#local externalAttributes = {} ]
            [#list environment as name,value]
                [#local prefix = core.Component.Name?upper_case + "_"]
                [#if name?starts_with(prefix)]
                    [#local externalAttributes += { name?remove_beginning(prefix) : value } ]
                [/#if]
            [/#list]
            [#if externalAttributes?has_content]
                [#local result += { "Attributes" : externalAttributes } ]
            [/#if]

        [/#if]

        [#switch core.Type!""]
            [#case LB_COMPONENT_TYPE]
                [#local result = getLBState(occurrence)]
                [#break]

            [#case LB_PORT_COMPONENT_TYPE]
                [#local result = getLBPortState(occurrence, parentOccurrence)]
                [#break]

            [#case APIGATEWAY_COMPONENT_TYPE]
                [#local result = getAPIGatewayState(occurrence)]
                [#break]

            [#case APIGATEWAY_USAGEPLAN_COMPONENT_TYPE]
                [#local result = getAPIGatewayUsagePlanState(occurrence)]
                [#break]

            [#case "cache"]
                [#local result = getCacheState(occurrence)]
                [#break]

            [#case "contenthub"]
                [#local result = getContentHubState(occurrence, result)]
                [#break]

            [#case "contentnode"]
                [#local result = getContentNodeState(occurrence)]
                [#break]

            [#case DATASET_COMPONENT_TYPE ]
                [#local result = getDataSetState(occurrence)]
                [#break]

            [#case DATAPIPELINE_COMPONENT_TYPE ]
                [#local result = getDataPipelineState(occurrence)]
                [#break]

            [#case DATAVOLUME_COMPONENT_TYPE ]
                [#local result = getDataVolumeState(occurrence)]
                [#break]

            [#case EC2_COMPONENT_TYPE]
                [#local result = getEC2State(occurrence)]
                [#break]

            [#case COMPUTECLUSTER_COMPONENT_TYPE]
                [#local result = getComputeClusterState(occurrence)]
                [#break]

            [#case "ecs"]
                [#local result = getECSState(occurrence)]
                [#break]

            [#case "efs"]
                [#local result = getEFSState(occurrence)]
                [#break]

            [#case "efsMount" ]
                [#local result = getEFSMountState(occurrence, parentOccurrence)]
                [#break]

            [#case ES_COMPONENT_TYPE]
                [#local result = getESState(occurrence)]
                [#break]
            
            [#case ES_DATAFEED_COMPONENT_TYPE]
                [#local result = getESFeedState(occurrence)]
                [#break]

            [#case "function"]
                [#local result = getFunctionState(occurrence, parentOccurrence)]
                [#break]

            [#case "lambda"]
                [#local result = getLambdaState(occurrence)]
                [#break]

            [#case MOBILEAPP_COMPONENT_TYPE]
                [#local result = getMobileAppState(occurrence)]
                [#break]

            [#case MOBILENOTIFIER_COMPONENT_TYPE ]
                [#local result = getMobileNotifierState(occurrence)]
                [#break]

            [#case MOBILENOTIFIER_PLATFORM_COMPONENT_TYPE ]
                [#local result = getMobileNotifierPlatformState(occurrence)]
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

            [#case SQS_COMPONENT_TYPE]
                [#local result = getSQSState(occurrence, result)]
                [#break]

            [#case CONFIGSTORE_COMPONENT_TYPE]
                [#local result = getConfigStoreState(occurrence)]
                [#break]

            [#case CONFIGSTORE_BRANCH_COMPONENT_TYPE]
                [#local result = getConfigBranchState(occurrence, parentOccurrence)]
                [#break]

            [#case "task"]
                [#local result = getTaskState(occurrence, parentOccurrence)]
                [#break]

            [#case USER_COMPONENT_TYPE ]
                [#local result = getUserState(occurrence) ]
                [#break]

            [#case USERPOOL_COMPONENT_TYPE]
                [#local result = getUserPoolState(occurrence, result)]
                [#break]

            [#case USERPOOL_CLIENT_COMPONENT_TYPE]
                [#local result = getUserPoolClientState(occurrence, parentOccurrence)]
                [#break]

            [#case USERPOOL_AUTHPROVIDER_COMPONENT_TYPE]
                [#local result = getUserPoolAuthProviderState(occurrence)]
                [#break]

            [#case BASTION_COMPONENT_TYPE ]
                [#local result = getBastionState(occurrence)]
                [#break]

            [#case NETWORK_COMPONENT_TYPE ]
                [#local result = getNetworkState(occurrence)]
                [#break]

            [#case NETWORK_ROUTE_TABLE_COMPONENT_TYPE ]
                [#local result = getNetworkRouteTableState(occurrence )]
                [#break]

            [#case NETWORK_ACL_COMPONENT_TYPE ]
                [#local result = getNetworkACLState(occurrence)]
                [#break]

            [#case NETWORK_GATEWAY_COMPONENT_TYPE ]
                [#local result = getNetworkGatewayState(occurrence)]
                [#break]

            [#case NETWORK_GATEWAY_DESTINATION_COMPONENT_TYPE ]
                [#local result = getNetworkGatewayDestinationState(occurrence, parentOccurrence)]
                [#break]

            [#case BASELINE_COMPONENT_TYPE ]
                [#local result = getBaselineState(occurrence)]
                [#break]

            [#case BASELINE_DATA_COMPONENT_TYPE ]
                [#local result = getBaselineStorageState(occurrence, parentOccurrence)]
                [#break]

            [#case "external"]
                [#local result +=
                    {
                        "Roles" : {
                            "Inbound" : {},
                            "Outbound" : {}
                        }
                    }
                ]
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

[#function getOccurrenceSettings possibilities root prefixes alternatives]
    [#local contexts = [] ]

    [#-- Order possibilities in increasing priority --]
    [#list prefixes as prefix]
        [#list possibilities?keys?sort as key]
            [#local matchKey = key?lower_case?remove_ending("-asfile") ]
            [#local value = possibilities[key] ]
            [#if value?has_content]
                [#list alternatives as alternative]
                    [#local alternativeKey = formatName(root, prefix, alternative.Key) ]
                    [@cfDebug
                        mode=listMode
                        value=alternative.Match + " comparison of " + matchKey + " to " + alternativeKey
                        enabled=false
                    /]
                    [#if
                        (
                            ((alternative.Match == "exact") && (alternativeKey == matchKey)) ||
                            ((alternative.Match == "partial") && (alternativeKey?starts_with(matchKey)))
                        ) ]
                        [@cfDebug
                            mode=listMode
                            value=alternative.Match + " comparison of " + matchKey + " to " + alternativeKey + " successful"
                            enabled=false
                        /]
                        [#local contexts += [value] ]
                        [#break]
                    [/#if]
                [/#list]
            [/#if]
        [/#list]
    [/#list]
    [#return asFlattenedSettings(getCompositeObject({ "Names" : "*" }, contexts)) ]
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

[#function getAccountSettings ]
    [#local alternatives = [{"Key" : "shared", "Match" : "exact"}] ]

    [#-- Fudge prefixes for accounts --]
    [#return
        getOccurrenceSettings(
            (settingsObject.Settings.Accounts)!{},
            accountName,
            [""],
            alternatives) ]
[/#function]

[#function getOccurrenceBuildSettings occurrence]
    [#local deploymentUnit = (occurrence.Configuration.Solution.DeploymentUnits[0])!"" ]

    [#local alternatives =
        [
            {"Key" : deploymentUnit, "Match" : "exact"},
            {"Key" : occurrence.Core.Name, "Match" : "partial"},
            {"Key" : occurrence.Core.TypedName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortTypedName, "Match" : "partial"}
        ] ]

    [#local occurrenceBuild =
        getOccurrenceSettings(
            (settingsObject.Builds.Products)!{},
            productName,
            cmdbProductLookupPrefixes,
            alternatives
        ) ]

    [#-- Reference could be a deployment unit or a component --]
    [#if occurrenceBuild.REFERENCE?has_content]
        [#-- Support cross-segment references --]
        [#if occurrenceBuild.SEGMENT?has_content]
            [#local buildLookupPrefixes =
                [
                    ["shared", occurrenceBuild.SEGMENT.Value],
                    [environmentName, occurrenceBuild.SEGMENT.Value]
                ] +
                cmdbProductLookupPrefixes ]
        [#else]
            [#local buildLookupPrefixes = cmdbProductLookupPrefixes]
        [/#if]
        [#local occurrenceBuild +=
            getOccurrenceSettings(
                (settingsObject.Builds.Products)!{},
                productName,
                buildLookupPrefixes,
                [
                    {"Key" : occurrenceBuild.REFERENCE.Value?replace("/","-"), "Match" : "exact"}
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
            {"Key" : deploymentUnit, "Match" : "exact"},
            {"Key" : occurrence.Core.Name, "Match" : "partial"},
            {"Key" : occurrence.Core.TypedName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortTypedName, "Match" : "partial"}
        ] ]

    [#return
        getOccurrenceSettings(
            (settingsObject.Settings.Products)!{},
            productName,
            cmdbProductLookupPrefixes,
            alternatives) ]
[/#function]


[#function getOccurrenceSensitiveSettings occurrence]
    [#local deploymentUnit = (occurrence.Configuration.Solution.DeploymentUnits[0])!"" ]

    [#local alternatives =
        [
            {"Key" : deploymentUnit, "Match" : "exact"},
            {"Key" : occurrence.Core.Name, "Match" : "partial"},
            {"Key" : occurrence.Core.TypedName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortTypedName, "Match" : "partial"}
        ] ]

    [#return
        markAsSensitive(
            getOccurrenceSettings(
                (settingsObject.Sensitive.Products)!{},
                productName,
                cmdbProductLookupPrefixes,
                alternatives) ) ]
[/#function]

[#-- Try to match the desired setting in decreasing specificity --]
[#-- A single match array or an array of arrays can be provided --]
[#-- Sets of settings are provide in least to most specific     --]
[#function getSetting settingSets names emptyIfNotProvided=false]
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
        [#list asArray(settingSets)?reverse as settingSet]

            [#local setting = settingSet[settingName]!{} ]
            [#if setting?has_content]
                [#break]
            [/#if]
        [/#list]
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

[#function getOccurrenceSetting occurrence names emptyIfNotProvided=false]
    [#return getSetting(
        [
            (occurrence.Configuration.Settings.Account)!{},
            (occurrence.Configuration.Settings.Product)!{},
            (occurrence.Configuration.Settings.Core)!{},
            (occurrence.Configuration.Settings.Build)!{}
        ],
        names,
        emptyIfNotProvided)
    ]
[/#function]

[#function getOccurrenceSettingValue occurrence names emptyIfNotProvided=false]
    [#return getOccurrenceSetting(occurrence, names, emptyIfNotProvided).Value]
[/#function]

[#function getOccurrenceBuildReference occurrence emptyIfNotProvided=false]
    [#return
        contentIfContent(
            getOccurrenceSettingValue(occurrence, "BUILD_REFERENCE", true),
            valueIfTrue(
                "",
                emptyIfNotProvided,
                "COTException: Build reference not found"
            )
        ) ]
[/#function]

[#function getOccurrenceBuildUnit occurrence emptyIfNotProvided=false]
    [#return
        contentIfContent(
            getOccurrenceSettingValue(occurrence, "BUILD_UNIT", true),
            valueIfTrue(
                "",
                emptyIfNotProvided,
                "COTException: Build unit not found"
            )
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

[#function getSettingsAsEnvironment settings format={} ]

    [#local formatting =
        {
            "Include" : {
                "General" : true,
                "Sensitive" : true
            },
            "Obfuscate" : false,
            "Escaped" : true,
            "Prefix" : ""
        }  +
        format ]

    [#local result = {} ]

    [#list settings as key,value]
        [#if value?is_hash]
            [#if value.Internal!false]
                [#continue]
            [/#if]
            [#local serialisedValue =
                valueIfTrue(
                    valueIfTrue(
                        formatting.Prefix?ensure_ends_with(":"),
                        formatting.Prefix?has_content &&
                            (value.Value?is_hash || value.Value?is_sequence),
                        ""
                    ) +
                    asSerialisableString(value.Value),
                    formatting.Escaped,
                    value.Value) ]
            [#if ((formatting.Include.General)!true) && !(value.Sensitive!false)]
                [#local result += { key : serialisedValue} ]
                [#continue]
            [/#if]
            [#if ((formatting.Include.Sensitive)!true) && value.Sensitive!false]
                [#local result += { key : valueIfTrue("****", formatting.Obfuscate, serialisedValue)} ]
                [#continue]
            [/#if]
        [#else]
            [#local result += { key, "COTException:Internal error - setting is not a hash" } ]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#function getOccurrenceSettingsAsEnvironment occurrence format]
    [#return
        getSettingsAsEnvironment(occurrence.Configuration.Settings.Core, format) +
        getSettingsAsEnvironment(occurrence.Configuration.Settings.Product, format)
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
        [#local typeObject = getComponentTypeObject(component) ]
    [#else]
        [#local type = componentType ]
        [#local typeObject = component ]
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
                "Names" : ["Export"],
                "Default" : []
            },
            {
                "Names" : ["DeploymentUnits"],
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
                            )
                        }
                    ]

                    [#local occurrenceProfiles = [] ]
                    [#list occurrenceContexts as occurrenceContext ]
                        [#if ((occurrenceContext.Profiles.Deployment)![])?has_content ]
                            [#local occurrenceProfiles = occurrenceContext.Profiles.Deployment ]
                        [/#if]
                    [/#list]

                    [#local occurrenceContexts += [ (getDeploymentProfile(occurrenceProfiles, deploymentMode)[type])!{} ]]

                    [#local occurrence += 
                        {
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
                                        "Account" : getAccountSettings(),
                                        "Product" :
                                            getOccurrenceProductSettings(occurrence) +
                                            getOccurrenceSensitiveSettings(occurrence)
                                    }
                                }
                        } ]
                    [#-- Some core settings are controlled by product level settings --]
                    [#-- (e.g. file prefixes) so initialise core last                --]
                    [#local occurrence +=
                        {
                            "Configuration" :
                                occurrence.Configuration +
                                {
                                    "Settings" :
                                        occurrence.Configuration.Settings +
                                        {
                                            "Core" : getOccurrenceCoreSettings(occurrence)
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
                                            getOccurrenceSettingsAsEnvironment(
                                                occurrence,
                                                {"Include" : {"Sensitive" : false}}
                                            ),
                                        "Sensitive" :
                                            getOccurrenceSettingsAsEnvironment(
                                                occurrence,
                                                {"Include" : {"General" : false}}
                                            )
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
                        [#-- To cater for the latter case, any default configuration --]
                        [#-- must be under a "Configuration" attribute to avoid the  --]
                        [#-- configuration being treated as subcomponent instances.  --]
                        [#local subComponentInstances = {} ]
                        [#if ((typeObject[subComponent.Component])!{})?is_hash ]
                            [#local subComponentInstances =
                                (typeObject[subComponent.Component].Components)!
                                (typeObject[subComponent.Component])!{}
                            ]
                        [#else]
                            [@cfException
                              mode=listMode
                              description="Subcomponent " + subComponent.Component + " content is not a hash"
                              context=typeObject[subComponent.Component] /]
                        [/#if]

                        [#list subComponentInstances as key,subComponentInstance ]
                            [#if subComponentInstance?is_hash ]
                                [#if
                                    (!((typeObject[subComponent.Component].Components)?has_content)) &&
                                    (key == "Configuration") ]
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

[#function isOccurrenceDeployed occurrence]
    [#return
        ((occurrence.Configuration.Solution.Enabled)!true) &&
        isOneResourceDeployed((occurrence.State.Resources)!{})
    ]

[/#function]

[#function getLinkTarget occurrence link activeOnly=true]

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
    [#if ! (link.Enabled)!true ]
        [#return {} ]
    [/#if]

    [#if link.Tier?lower_case == "external"]
        [#local targetOccurrence =
            {
                "Core" : {
                    "External" : true,
                    "Type" : link.Type!"external",
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
                "Direction" : link.Direction!"outbound",
                "Role" : link.Role!"external"
            }
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
        [#-- Support multiple alternatives --]
        [#local subComponents = getOccurrenceSubComponents(core.Type) ]
        [#list subComponents as subComponent]
            [#local linkAttributes = asFlattenedArray(subComponent.Link!"") ]
            [#list linkAttributes as linkAttribute]
                [#local subComponentId = link[linkAttribute]!"" ]
                [#if subComponentId?has_content ]
                    [#break]
                [/#if]
            [/#list]
            [#if subComponentId?has_content ]
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
            [#-- If occurrences do not match, overrides can be added --]
            [#-- to the link.                                       --]
            [#if (core.Instance.Id != instanceToMatch) ||
                (core.Version.Id != versionToMatch) ]
                [#continue]
            [/#if]

            [@cfDebug listMode "Link matched target" false /]

            [#-- Determine if deployed --]
            [#if activeOnly && !isOccurrenceDeployed(targetSubOccurrence) ]
                [#return {} ]
            [/#if]

            [#-- Determine the role --]
            [#local direction = link.Direction!"outbound"]

            [#local role =
                link.Role!
                (targetSubOccurrence.State.Roles[direction?capitalize]["default"])!""]

            [#return
                targetSubOccurrence +
                {
                    "Direction" : direction,
                    "Role" : role
                } ]
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

[#function getLinkTargets occurrence links={} activeOnly=true]
    [#local result={} ]
    [#list (valueIfContent(links, links, occurrence.Configuration.Solution.Links!{}))?values as link]
        [#if link?is_hash]
            [#local linkTarget = getLinkTarget(occurrence, link, activeOnly) ]
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

[#function isLinkTargetActive target]
    [#return
        ((target.Configuration.Solution.Enabled)!true) &&
        (
            isOccurrenceDeployed(target) ||
            (target.Core.External!false)
        ) ]
[/#function]

[#function getLinkTargetsOutboundRoles LinkTargets ]
    [#local roles = [] ]
    [#list LinkTargets?values as linkTarget]
        [#if !isLinkTargetActive(linkTarget) ]
            [#continue]
        [/#if]
        [#local role = (linkTarget.State.Roles.Outbound[linkTarget.Role])!{} ]
        [#if (linkTarget.Direction == "outbound") && role?has_content ]
            [#local roles += asArray(role![]) ]
        [/#if]
    [/#list]
    [#return roles]
[/#function]

[#-- Get processor settings --]
[#function getProcessor occurrence type ]

    [#local tc = formatComponentShortName( occurrence.Core.Tier.Id, occurrence.Core.Component.Id)]

    [#local processorProfile = occurrence.Configuration.Solution.Profiles.Processor ]
    
    [#if (component[type].Processor)??]
        [#return component[type].Processor]
    [/#if]
    [#if (processors[solutionObject.CapacityProfile][tc])??]
        [#return processors[solutionObject.CapacityProfile][tc]]
    [/#if]
    [#if (processors[solutionObject.CapacityProfile][type])??]
        [#return processors[solutionObject.CapacityProfile][type]]
    [/#if]
    [#if (processors[processorProfile][tc])??]
        [#return processors[processorProfile][tc]]
    [/#if]
    [#if (processors[processorProfile][type])??]
        [#return processors[processorProfile][type]]
    [/#if]
    [#return {}]
[/#function]

[#function getLogFileProfile tier component type extensions... ]
    [#local tc = formatComponentShortName(
                    tier,
                    component,
                    extensions)]
    [#local defaultProfile = "default"]
    [#if (component[type].LogFileProfile)??]
        [#return component[type].LogFileProfile]
    [/#if]
    [#if (logFileProfiles[defaultProfile][tc])??]
        [#return logFileProfiles[defaultProfile][tc]]
    [/#if]
    [#if (logFileProfiles[defaultProfile][type])??]
        [#return logFileProfiles[defaultProfile][type]]
    [/#if]
[/#function]

[#function getBootstrapProfile tier component type extensions... ]
    [#local tc = formatComponentShortName(
                    tier,
                    component,
                    extensions)]
    [#local defaultProfile = "default"]
    [#if (component[type].BootstrapProfile)??]
        [#return component[type].Bootstrap]
    [/#if]
    [#if (bootstrapProfiles[defaultProfile][tc])??]
        [#return bootstrapProfiles[defaultProfile][tc]]
    [/#if]
    [#if (bootstrapProfiles[defaultProfile][type])??]
        [#return bootstrapProfiles[defaultProfile][type]]
    [/#if]
[/#function]

[#function getSecurityProfile profileName type engine="" ]

    [#local profile = (securityProfiles[profileName][type])!{} ]
    [#return profile[engine]!profile ]

[/#function]

[#function getNetworkEndpoints endpointGroups zone region ]
    [#local services = []]
    [#local networkEndpoints = {}]

    [#local regionObject = regions[region]]
    [#local zoneNetworkEndpoints = regionObject.Zones[zone].NetworkEndpoints ]

    [#list endpointGroups as endpointGroup ]
        [#if networkEndpointGroups[endpointGroup]?? ]
            [#list networkEndpointGroups[endpointGroup].Services as service ]
                [#if !services?seq_contains(service) ]
                    [#local services += [ service ]]
                [/#if]
            [/#list]
        [/#if]
    [/#list]

    [#list services as service ]
        [#list zoneNetworkEndpoints as zoneNetworkEndpoint ]
            [#if (zoneNetworkEndpoint.ServiceName!"")?ends_with(service) ]
                [#local networkEndpoints +=
                    {
                        service : zoneNetworkEndpoint
                    }]
            [/#if]
        [/#list]
    [/#list]

    [#return networkEndpoints]
[/#function]

[#function getDeploymentProfile occurrenceProfiles deploymentMode ]

    [#local deploymentProfileNames = []]

    [#list asArray(occurrenceProfiles![]) as profileName ]
        [#if ! deploymentProfileNames?seq_contains(profileName) ]
            [#local deploymentProfileNames += [ profileName ] ]
        [/#if]
    [/#list]

    [#if (environmentObject.Profiles.Deployment)?? ]
        [#list asArray(environmentObject.Profiles.Deployment) as profileName ]
            [#if ! deploymentProfileNames?seq_contains(profileName) ]
                [#local deploymentProfileNames += [ profileName ] ]
            [/#if]
        [/#list]
    [/#if]

    [#if (productObject.Profiles.Deployment)?? ]
        [#list asArray(productObject.Profiles.Deployment) as profileName ]
            [#if ! deploymentProfileNames?seq_contains(profileName) ]
                [#local deploymentProfileNames += [ profileName ] ]
            [/#if]
        [/#list]
    [/#if]

    [#if (accountObject.Profiles.Deployment)?? ]
        [#list asArray(accountObject.Profiles.Deployment) as profileName ]
            [#if ! deploymentProfileNames?seq_contains(profileName) ]
                [#local deploymentProfileNames += [ profileName ] ]
            [/#if]
        [/#list]
    [/#if]

    [#if (tenantObject.Profiles.Deployment)?? ]
        [#list asArray(tenantObject.Profiles.Deployment) as profileName ]
            [#if ! deploymentProfileNames?seq_contains(profileName) ]
                [#local deploymentProfileNames += [ profileName ] ]
            [/#if]
        [/#list]
    [/#if]

    [#local deploymentProfile = {} ]
    [#list deploymentProfileNames as deploymentProfileName ]
        [#local deploymentProfile = mergeObjects( deploymentProfile, (deploymentProfiles[deploymentProfileName])!{} )]
    [/#list]

    [#return mergeObjects( (deploymentProfile.Modes["*"])!{}, (deploymentProfile.Modes[deploymentMode])!{})  ]
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

[#function getDomainObjects certificateObject qualifiers...]
    [#local result = [] ]
    [#local primaryNotSeen = true]
    [#local lines = getObjectLineage(domains, certificateObject.Domain, qualifiers) ]
    [#list lines as line]
        [#local name = "" ]
        [#local role = DOMAIN_ROLE_PRIMARY ]
        [#list line as domainObject]
            [#local qualifiedDomainObject =
                getCompositeObject(
                    [
                        "InhibitEnabled", "Stem", "Name", "Zone",
                        {
                            "Names" : "Bare",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "Role",
                            "Type" : STRING_TYPE,
                            "Values" : [DOMAIN_ROLE_PRIMARY, DOMAIN_ROLE_SECONDARY]
                        }
                    ],
                    domainObject) ]
            [#if !(qualifiedDomainObject.Bare) ]
                [#local name = formatDomainName(
                                   contentIfContent(
                                       qualifiedDomainObject.Stem!"",
                                       contentIfContent(
                                           qualifiedDomainObject.Name!"",
                                           ""
                                       )
                                   ),
                                   name
                               ) ]
            [/#if]
            [#if qualifiedDomainObject.Role?has_content]
                [#local role = qualifiedDomainObject.Role]
            [/#if]
        [/#list]
        [#local result +=
            [
                {
                    "Name" : name,
                    "Role" : valueIfTrue(role, primaryNotSeen, DOMAIN_ROLE_SECONDARY)
                } +
                getCompositeObject( ["InhibitEnabled", "Zone"], line )
            ] ]
        [#local primaryNotSeen = primaryNotSeen && (role != DOMAIN_ROLE_PRIMARY) ]
    [/#list]

    [#-- Force first entry to primary if no primary seen --]
    [#if primaryNotSeen && (result?size > 0) ]
        [#local forcedResult = [ result[0] + { "Role" : DOMAIN_ROLE_PRIMARY } ] ]
        [#if (result?size > 1) ]
            [#local forceResult += result[1..] ]
        [/#if]
        [#local result = forcedResult]
    [/#if]

    [#-- Add any domain inclusions --]
    [#local includes = certificateObject.IncludeInDomain!{} ]
    [#if includes?has_content]
        [#local hostParts = certificateObject.HostParts ]
        [#local parts = [] ]

        [#list hostParts as part]
            [#if includes[part]!false]
                [#switch part]
                    [#case "Segment"]
                        [#local parts += [segmentName!""] ]
                        [#break]
                    [#case "Environment"]
                        [#local parts += [environmentName!""] ]
                        [#break]
                    [#case "Product"]
                        [#local parts += [productName!""] ]
                        [#break]
                [/#switch]
            [/#if]
        [/#list]

        [#local extendedResult = [] ]
        [#list result as entry]
            [#local extendedResult += [
                    entry +
                    {
                        "Name" : formatDomainName(parts, entry.Name)
                    }
                ] ]
        [/#list]
        [#local result = extendedResult]
    [/#if]

    [#return result]
[/#function]

[#function getCertificateObject start qualifiers...]

    [#local certificateObject =
        getCompositeObject(
            certificateChildConfiguration,
            asFlattenedArray(
                getObjectAndQualifiers((blueprintObject.CertificateBehaviours)!{}, qualifiers) +
                getObjectAndQualifiers((tenantObject.CertificateBehaviours)!{}, qualifiers) +
                getObjectAndQualifiers((productObject.CertificateBehaviours)!{}, qualifiers) +
                ((getObjectLineage(certificates, [productId, productName], qualifiers)[0])![]) +
                ((getObjectLineage(certificates, start, qualifiers)[0])![])
            )
        )
    ]
    [#return
        certificateObject +
        {
            "Domains" : getDomainObjects(certificateObject, qualifiers)
        }
    ]
[/#function]

[#function getHostName certificateObject occurrence]

    [#local core = occurrence.Core ]
    [#local includes = certificateObject.IncludeInHost!{} ]
    [#local hostParts = certificateObject.HostParts ]
    [#local parts = [] ]

    [#list hostParts as part]
        [#if includes[part]!true]
            [#switch part]
                [#case "Host"]
                    [#local parts += [certificateObject.Host!""] ]
                    [#break]
                [#case "Tier"]
                    [#local parts += [getTierName(core.Tier)] ]
                    [#break]
                [#case "Component"]
                    [#local parts += [getComponentName(core.Component)] ]
                    [#break]
                [#case "Instance"]
                    [#local parts += [core.Instance.Name!""] ]
                    [#break]
                [#case "Version"]
                    [#local parts += [core.Version.Name!""] ]
                    [#break]
                [#case "Segment"]
                    [#local parts += [segmentName!""] ]
                    [#break]
                [#case "Environment"]
                    [#local parts += [environmentName!""] ]
                    [#break]
                [#case "Product"]
                    [#local parts += [productName!""] ]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]
    [#return
        valueIfTrue(
            certificateObject.Host,
            certificateObject.Host?has_content && (!(includes.Host)),
            formatName(parts)
        )
    ]
]
[/#function]

[#-- Directory Structure for ContentHubs --]
[#function getContentPath occurrence pathObject={} ]

    [#local core = occurrence.Core ]
    [#local pathObject = pathObject?has_content?then(
                            pathObject,
                            occurrence.Configuration.Solution.Path)]
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

[#function getLBLink occurrence port ]

    [#assign core = occurrence.Core]
    [#assign targetTierId = (port.LB.Tier) ]
    [#assign targetComponentId = (port.LB.Component) ]
    [#assign targetLinkName = formatName(port.LB.LinkName) ]
    [#assign portMapping = contentIfContent(port.LB.PortMapping, port.Name)]

    [#-- Need to be careful to allow an empty value for --]
    [#-- Instance/Version to be explicitly provided and --]
    [#-- correctly handled in getLinkTarget.            --]
    [#--                                                --]
    [#-- Also note that the LinkName configuration      --]
    [#-- must be provided if more than one port is used --]
    [#-- (e.g. classic ELB) to avoid links overwriting  --]
    [#-- each other.                                    --]
    [#local targetLink =
        {
            "Id" : targetLinkName,
            "Name" : targetLinkName,
            "Tier" : targetTierId,
            "Component" : targetComponentId
        } +
        attributeIfTrue("Instance", port.LB.Instance??, port.LB.Instance!"") +
        attributeIfTrue("Version",  port.LB.Version??, port.LB.Version!"") +
        attributeIfContent("PortMapping",  portMapping)
    ]
    [@cfDebug listMode { targetLinkName : targetLink } false /]

    [#return { targetLinkName : targetLink } ]
[/#function]

[#function isDuplicateLink links link ]

    [#local linkKey = ""]
    [#list link as key,value]
        [#local linkKey = key]
        [#break]
    [/#list]

    [#return (links[linkKey])?? ]

[/#function]

[#-- Prologue/epilogue script creation --]

[#function syncFilesToBucketScript filesArrayName region bucket prefix]
    [#return
        [
            "case $\{STACK_OPERATION} in",
            "  delete)",
            "    deleteTreeFromBucket" + " " +
                   "\"" + region + "\"" + " " +
                   "\"" + bucket + "\"" + " " +
                   "\"" + prefix + "\"" + " " +
                   "|| return $?",
            "    ;;",
            "  create|update)",
            "    debug \"FILES=$\{" + filesArrayName + "[@]}\"",
            "    #",
            "    syncFilesToBucket" + " " +
                   "\"" + region         + "\"" + " " +
                   "\"" + bucket         + "\"" + " " +
                   "\"" + prefix         + "\"" + " " +
                   "\"" + filesArrayName + "\"" + " " +
                   "--delete || return $?",
            "    ;;",
            " esac",
            "#"
        ] ]
[/#function]

[#function findAsFilesScript filesArrayName settings]
    [#-- Create an array for the files --]
    [#local result = [] ]
    [#list settings as setting]
        [#if setting.AsFile?has_content]
            [#local result +=
                [
                    "addToArray" + " " +
                       "\"" + "filePathsToSync" + "\"" + " " +
                       "\"" + setting.AsFile    + "\""
                ] ]
        [/#if]
    [/#list]
    [#local result += ["#"] ]

    [#-- Locate where each file is --]
    [#return
        result +
        [
            "addToArray" + " " +
               "\"" + "dirsToCheck"                 + "\"" + " " +
               "\"" + "$\{ROOT_DIR}" + "\"",
            "addToArray" + " " +
               "\"" + "dirsToCheck"                 + "\"" + " " +
               "\"" + "$\{PRODUCT_APPSETTINGS_DIR}" + "\"",
            "addToArray" + " " +
               "\"" + "dirsToCheck"                 + "\"" + " " +
               "\"" + "$\{PRODUCT_CREDENTIALS_DIR}" + "\"",
            "#",
            "for f in \"$\{filePathsToSync[@]}\"; do",
            "  for d in \"$\{dirsToCheck[@]}\"; do",
            "    if [[ -f \"$\{d}/$\{f}\" ]]; then",
                   "addToArray" + " " +
                      filesArrayName + " " +
                      "\"$\{d}/$\{f}\"",
            "      break",
            "    fi",
            "  done",
            "done",
            "#"
        ] ]

[/#function]

[#function getBuildScript filesArrayName region registry product occurrence filename]
    [#return
        [
            "copyFilesFromBucket" + " " +
              region + " " +
              getRegistryEndPoint(registry, occurrence) + " " +
              formatRelativePath(
                getRegistryPrefix(registry, occurrence),
                product,
                getOccurrenceBuildUnit(occurrence),
                getOccurrenceBuildReference(occurrence)) + " " +
                "\"$\{tmpdir}\" || return $?",
            "#",
            "addToArray" + " " +
               filesArrayName + " " +
               "\"$\{tmpdir}/" + filename + "\"",
            "#"
        ] ]
[/#function]

[#function getLocalFileScript filesArrayName filepath filename=""]
    [#return
        valueIfContent(
            [
                "tmp_filename=\"" + filename + "\""
            ],
            filename,
            [
                "tmp_filename=\"$(fileName \"" + filepath + "\")\""
            ]
        ) +
        [
            "cp" + " " +
               "\"" + filepath                      + "\"" + " " +
               "\"" + "$\{tmpdir}/$\{tmp_filename}" + "\"",
            "#",
            "addToArray" + " " +
               filesArrayName + " " +
               "\"" + "$\{tmpdir}/$\{tmp_filename}" + "\"",
            "#"
        ] ]
[/#function]

[#function pseudoStackOutputScript description outputs filesuffix="" ]
    [#local outputString = ""]

    [#list getCFTemplateCoreOutputs(region, accountObject.AWSId) as  key,value ]
        [#if value?is_hash ]
            [#local outputs += { key, value.Value } ]
        [#else ]
            [#local outputs += { key, vaue } ]
        [/#if]
    [/#list]

    [#list outputs as key,value ]
        [#local outputString +=
          "\"" + key + "\" \"" + value + "\" "
        ]
    [/#list]

    [#return
        [
            "create_pseudo_stack" + " " +
            "\"" + description + "\"" + " " +
            "\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")" + (filesuffix?has_content)?then("-" + filesuffix, "") + "-pseudo-stack.json\" " +
            outputString + " || return $?"
        ]
    ]

[/#function]

[#function getResourceMetricDimensions resource resources]
    [#local resourceMetricAttributes = metricAttributes[resource.Type]!{} ]

    [#if resourceMetricAttributes?has_content ]
        [#local occurrenceDimensions = [] ]
        [#list resourceMetricAttributes.Dimensions as name,property ]
            [#list property as key,value ]
                [#switch key]
                    [#case "ResourceProperty" ]
                        [#local occurrenceDimensions += [{
                            "Name" : name,
                            "Value" : resource[value]
                        }]]
                        [#break]
                    [#case "OtherResourceProperty" ]
                        [#local otherResource = resources[value.Id]]
                        [#local occurrenceDimensions += [{
                            "Name" : name,
                            "Value" : otherResource[value.Property]
                        }]]
                        [#break]
                    [#case "Output" ]
                        [#local occurrenceDimensions += [{
                            "Name" : name,
                            "Value" : getReference(resource.Id, value)
                        }]]
                        [#break]
                    [#case "OtherOutput" ]
                        [#local otherResource = resources[value.Id]]
                        [#local occurrenceDimensions += [{
                            "Name" : name,
                            "Value" : getReference(otherResource.Id, value.Property)
                        }]]
                        [#break]
                    [#case "PseudoOutput" ]
                        [#local occurrenceDimensions += [{
                            "Name" : name,
                            "Value" : { "Ref" : value }
                        }]]
                        [#break]
                [/#switch]
            [/#list]
        [/#list]

        [#return occurrenceDimensions]
    [#else]
        [@cfException
            mode=listMode
            description="Dimensions not mapped for this resource"
            context=resource.Type
        /]
    [/#if]

[/#function]

[#function getResourceMetricNamespace resourceType ]
    [#local resourceTypeNameSpace = (metricAttributes[resourceType]).Namespace!"" ]

    [#if resourceTypeNameSpace?has_content ]
        [#switch resourceTypeNameSpace ]
            [#case "_productPath" ]
                [#return formatProductRelativePath()]
                [#break]

            [#default]
                [#return resourceTypeNameSpace]
        [/#switch]
    [#else]
        [@cfException
            mode=listMode
            description="Namespace not mapped for this resource"
            context=resource.Type
        /]
    [/#if]
[/#function]

[#function getMetricName metricName resourceType shortFullName ]

    [#-- For some metrics we need to append the resourceName to add a qualifier if they don't support dimensions --]
    [#switch resourceType]
        [#case AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE ]
            [#return formatName(metricName, shortFullName) ]
    [#break]

    [#default]
        [#return metricName]
    [/#switch]
[/#function]

[#function getMonitoredResources resources, resourceQualifier ]
    [#local monitoredResources = {} ]

    [#list resources as id,resource ]

        [#if !resource["Type"]?has_content && resource?is_hash]
            [#list resource as id,subResource ]
                [#local monitoredResources += getMonitoredResources({id : subResource}, resourceQualifier)]
            [/#list]

        [#else]

            [#if resourceQualifier.Id?has_content || resourceQualifier.Type?has_content ]

                [#if resourceQualifier.Id?has_content && resourceQualifier.Id == id  ]
                    [#local monitoredResources += {
                        id: resource
                    }]
                [/#if]

                [#if resourceQualifier.Type?has_content && resourceQualifier.Type == resource["Type"]  ]
                    [#local monitoredResources += {
                        id: resource
                    }]
                [/#if]

            [#else]

                [#if resource["Type"]?has_content]

                    [#if resource["Monitored"]!false ]
                        [#local monitoredResources += {
                            id : resource
                        }]
                    [/#if]
                [/#if]

            [/#if]
        [/#if]
    [/#list]
    [#return monitoredResources ]
[/#function]