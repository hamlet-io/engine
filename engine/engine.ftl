[#ftl]

[#-- Configuration Engine - managing configuration in CodeOnTap --]

[#-- Configuration Objects

Hamlet reflects each concept present in a typical IT landscape as a
configuration object.

Each object has a set of attributes. Framework specific attributes of
configuration objects always use title case, so it is recommended to use
lowercase letters for attributes in user provided data to avoid clashes or
incorrect processing.

Framework attributes common to all objects include Type, Id, Name, Title,
Description and Type.

The Id acts as a default for the Name if the Name is not provided, and vica-versa.

Title and Description are entirely for human consumption and targetted at
the automated generation of documentation.
--]

[#assign frameworkObjectAttributes = ["Type", "Id", "Name", "Title", "Description"]]

[#function getFrameworkObjectAttributes obj]
    [#return getObjectAttributes(obj, frameworkObjectAttributes)]
[/#function]

[#function getNonFrameworkObjectAttributes obj]
    [#return removeObjectAttributes(obj, frameworkObjectAttributes)]
[/#function]

[#function getObjectType obj]
    [#return obj.Type!""]
[/#function]

[#function getObjectId obj]
    [#return obj.Id!obj.Name!""]
[/#function]

[#function getObjectName obj]
    [#return obj.Name!obj.Id!""]
[/#function]

[#function getObjectTitle obj]
    [#return obj.Title!""]
[/#function]

[#function getObjectDescription obj]
    [#return obj.Description!""]
[/#function]

[#--
The Type determines the accepted structure of the configuration object. For each
concept, there is a singular and a plural type, for instance "Tenant"
and "Tenants". Type values are title cased.

Plural types are normally formed by adding an "s" to the singular type. The
exceptions to this rule are listed below.
--]

[#-- Object types --]
[#assign objectTypeConfiguration = {
    "Storage" : {
        "Singular" : "StorageProfile"
    },
    "CertificateBehaviours" : {
        "Plural" : "CertBehaviours"
    }
}]

[#function getObjectTypeConfiguration entity]
    [#if entity?is_hash]
        [#return (objectTypeConfiguration[getObjectType(entity)])!{}]
    [/#if]
    [#if entity?is_string]
        [#return (objectTypeConfiguration[entity])!{}]
    [/#if]
    [#return {}]
[/#function]

[#function isKnownType entity]
    [#return getObjectTypeConfiguration(entity)?has_content]
[/#function]

[#function isSingular entity]
    [#return (getObjectTypeConfiguration(entity).Plural)?has_content]
[/#function]

[#function isPlural entity]
    [#return (getObjectTypeConfiguration(entity).Singular)?has_content]
[/#function]

[#function getSingularType entity]
    [#return (getObjectTypeConfiguration(entity).Singular)!""]
[/#function]

[#function getPluralType entity]
    [#return (getObjectTypeConfiguration(entity).Plural)!""]
[/#function]

[#function needsNewContext obj]
    [#return getObjectTypeConfiguration(obj).NewContext!true]
[/#function]


[#--
An object with an Id attribute is called an object instance. Object instances
always have a singular type and represent specific objects.
--]

[#function isObjectInstance obj]
    [#return isSingular(obj) && getObjectId(obj)?has_content]
[/#function]


[#--
An object without an Id and with a singular type is called an object template.
Object templates provide overridable default attributes and values to all object
instances of the same type.
--]

[#function isObjectTemplate obj]
    [#return isSingular(obj) && (!(getObjectId(obj)?has_content))]
[/#function]


[#--
An object with a plural type is called an object set, and each non-framework
attribute of the object set represents an object instance of the equivalent
singular type. It is usual but not required that the key of each attribute of
the object set matches the Id attribute of the corresponding object instance.
Where an object instance in an object set is not provided with an explicit Id,
the attribute key is used as the Id.
--]

[#function isObjectSet obj]
    [#return isPlural(obj)]
[/#function]

[#function addObjectSetIds set]
    [#local result = set]
    [#list set as key,value]
        [#if !(value.Id??)]
            [#local result = mergeObjects(result, {key: {"Id" : key}})]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#--
An object set may have an optional "Order" framework attribute that defines the
order in which the objects of the set should be processed. It contains a list of
attribute keys of the object instances within the object set. Any attribute keys
not in the Order list are processed AFTER those in the Order list.
--]

[#assign frameworkObjectAttributes += ["Order"]]

[#function addToObjectSet set obj]
    [#local id = getObjectId(obj)]
    [#local order = set.Order![]]
    [#if !(order?seq_contains(id))]
        [#local order += [id]]
    [/#if]
    [#return set + {id : mergeObjects(set[id]!{}, obj), "Order" : order}]
[/#function]

[#function getObjectSetOrder set]
    [#local order = asArray((set.Order)![])]
    [#list getNonFrameworkObjectAttributes(set)?keys as key]
        [#if order?seq_contains(key)]
            [#continue]
        [/#if]
        [#local order += [key]]
    [/#list]
    [#return order]
[/#function]


[#--
The object Id is used to build unique ids for object instances. Ids are intended
for consumption by automated processes and so are kept short (typically around 3
to 5 characters) and limited to alphanumeric characters. Ids are
concatenated using the "X" character to form unique ids.
--]

[#function formatId ids...]
    [#return concatenate(ids, "X")?replace("[-_/]", "X", "r")?replace(",", "")]
[/#function]

[#--
The object Name is used to build labels for object instances intended for human
consumption, such as those that appear in UIs or directory layouts, and
typically are used for sorting. They are thus still limited to alphanumeric
characters but will typically use full words rather than abbreviations. Names
are concatenated with the "-" character" to form unique names.

Environments occasionally constrain the length of unique names. In this case,
the "short" name can be used, which is formed by using object Ids rather than
names.
--]

[#function formatName names...]
    [#return concatenate(names, "-")]
[/#function]

[#function getMatchingNamespaces namespaces prefixes alternatives endingsToRemove=[] ]
    [#local matches = [] ]
    [#local candidates = [] ]

    [#-- ## Matching namespace rules ## --]
    [#-- Last Prefix is preferred over the first Prefix --]
    [#-- Exact match within a prefix is preferred over a Partial match --]
    [#local matchPreference = [ "partial", "exact" ]]

    [#-- Preprocess the namespaces to permit sorting --]
    [#list asArray(namespaces) as namespace]
        [#local key = namespace?lower_case]

        [#-- Remove namespace endings if required --]
        [#list asArray(endingsToRemove) as endingToRemove]
            [#local key = key?remove_ending(endingToRemove)]
        [/#list]

        [#local candidates += [ {"Namespace" : namespace, "Key" : key} ] ]
    [/#list]

    [#-- Longer matches are ordered later in the match list --]
    [#local candidates = candidates?sort_by("Key") ]

    [@debug message=
        {
            "Method" : "getMatchingNamespaces",
            "Namespaces" : namespaces,
            "Prefixes" : prefixes,
            "Alternatives" : alternatives,
            "EndingsToRemove" :  endingsToRemove,
            "Candidates" : candidates
        }
        enabled=false
    /]

    [#-- Prefixes listed in increasing priority --]
    [#list prefixes as prefix]
        [#list matchPreference as match ]
            [#list candidates as candidate]

                [#local key = candidate.Key]

                [#-- Alternatives listed in increasing priority --]
                [#list alternatives as alternative]
                    [#local alternativeKey = formatName(prefix, alternative.Key) ]
                    [@debug
                        message=alternative.Match + " comparison of " + key + " to " + alternativeKey
                        enabled=false
                    /]
                    [#local alternativeMatched = false]

                    [#if alternative.Match == match ]
                        [#switch match ]
                            [#case "exact" ]
                                [#if alternativeKey == key ]
                                    [#local alternativeMatched = true]
                                [/#if]
                                [#break]

                            [#case "partial" ]
                                [#if alternativeKey?starts_with(key) ]
                                    [#local alternativeMatched = true]
                                [/#if]
                                [#break]
                        [/#switch]

                        [#if alternativeMatched ]
                            [#local matches += [candidate.Namespace] ]
                            [#break]
                        [/#if]
                    [/#if]
                [/#list]
            [/#list]
        [/#list]
    [/#list]
    [@debug message=
        {
            "Method" : "getMatchingNamespaces",
            "Matches" : matches
        }
        enabled=false /]

    [#return matches]
[/#function]

[#--
Whenever a type is used for an attribute key to create a reference from one
object to another, the singular form implies one reference value is provided,
and an empty value or absence of the attribute indicates that no reference
has been provided. The plural form implies zero or more reference values may be
provided. Where the plural form is expected, processing will also accept the
singular form, but not vica-versa.

In general, types should be used to create references where the intent is
unambiguous.
--]


[#-- Family Trees
To permit objects of a particular type to be organised into a "family" tree,
the special attributes "Parent" and "Parents" are used. They operate in the same
way as types, but the referenced object(s) are assumed to be of the same
type as the referencing object.
--]

[#assign frameworkObjectAttributes += ["Parent", "Parents"]]


[#-- Configuration Management Database (CMDB)

Configuration is persisted in a Configuration Management Database or CMDB for short.

The term CMDB is borrowed from the ITIL world. To date in ITIL practice, CMDBs
have tended to be afterthoughts populated AFTER systems are operational. CodeOnTap
aims to achieve the full intention of CMDBs with the contents of the CMDB driving
what is deployed. Put another way, nothing appears operationally unless it is first
captured in the CMDB, consistent with "infrastructure as code" approaches.

In order to support appropriate access and maintenance strategies for configuration
information, a single logical CMDB may physically be represented as multiple smaller
CMDBs, and these smaller CMDBs combined during processing.

Each CMDB has a version, which reflects the layout of the configuration
information in the CMDB, and permits automated upgrades and removal of deprecated
configuration elements.

It is sometimes necessary to provide a value for an object Id or Name in order to
satisfy the rules of the formats used in the CMDB, even though the value should
not be included in unique Ids or Names for object instances. Examples might be
an attribute key in a JSON object or a directory name in a directory tree.

CodeOnTap thus reserves the value "default" for this purpose. When encountered,
CodeonTap will not include this value in any generated unique Ids or Names, but
can use it during processing to differentiate object instances.
--]


[#-- Configuration items

The CMDB is represented in memory as a hierarchy of "contexts". To create this
hierarchy, the persisted CMDB is read in as an item stream. An item stream
is a list of configuration objects and/or item streams. Order within a stream
determines processing order.

[#-- Item Categories --]
[#assign CONFIGURATION_ITEM_STREAM_TYPE = "stream"]
[#assign CONFIGURATION_ITEM_INSTANCE_TYPE = "instance"]
[#assign CONFIGURATION_ITEM_TEMPLATE_TYPE = "template"]
[#assign CONFIGURATION_ITEM_SET_TYPE = "set"]
[#assign CONFIGURATION_ITEM_UNKNOWN_TYPE = "unknown"]

[#function getConfigurationItemType item]
    [#if item?is_sequence]
        [#return CONFIGURATION_ITEM_STREAM_TYPE]
    [/#if]
    [#if item?is_hash]
        [#if isObjectInstance(item)]
            [#return CONFIGURATION_ITEM_INSTANCE_TYPE]
        [/#if]
        [#if isObjectTemplate(item)]
            [#return CONFIGURATION_ITEM_TEMPLATE_TYPE]
        [/#if]
        [#if isObjectSet(item)]
            [#return CONFIGURATION_ITEM_SET_TYPE]
        [/#if]
    [/#if]
    [#return CONFIGURATION_ITEM_UNKNOWN_TYPE]
[/#function]


[#-- Configuration contexts

Whenever a new stream is encountered, processing of configuration items
within the stream continues as if the boundary of the new stream didn't exist, but
the scope of any searches to determine context boundaries is limited to the end
of the new stream.

A new context is created

1) on processing initiation

This is referred to as the "root" context and is the starting point for processing
once the CMDB is in memory.

2) each time an object instance is encountered

The object instance is always added to the object set for the corresponding plural
type in the current context. In addition, if the object type is flagged as
needing a new context, a new context is created and added to the list of
subcontexts.

The set of items to be processed as part of the new context is determined
either

1) by the occurrence of the next object instance of the same type in the current
stream, or
2) the end of the current item stream.

The nesting of item streams thus provides a mechanism to provide fine
grained control over the selection of items for a particular context.

The Type of the object instance that triggered the context creation is
added to the filter of the current context, the result becoming the filter for
the new context. The Id and Name (if different from the Id) are used as the
filter attribute values.

Any object template encountered is merged with any existing object template with
the same singular type to become the template for the object type within the
current context.

Any object set encountered is merged with any existing object set with the
same plural type within the current context.

A context thus logically contains

1) the instance that triggered the context creation
2) the filter corresponding to the context
3) For each singular type, the (possibly empty) corresponding object template
4) For each plural type, the (possibly empty) corresponding object set
5) the (possibly empty) list of subcontexts
--]

[#function createContextFromStream currentContext stream]
    [#local context =
        mergeObjects(
            {
                "Instance" : {},
                "Filter" : {},
                "Templates" : {},
                "Sets" : {},
                "Contexts" : []
            },
            currentContext
        )]
    [#local lastIndex = stream?size - 1]
    [#local nextIndexToProcess = -1]

    [#list stream as item]
        [#-- Skip items already processed as part of an object instance --]
        [#local index = item?index]
        [#if nextIndexToProcess > index]
            [#continue]
        [/#if]

        [#switch getConfigurationItemType(item)]
            [#case CONFIGURATION_ITEM_STREAM_TYPE]
                [#-- Change stream scope --]
                [#local context = createContext(context, item)]
                [#break]

            [#case CONFIGURATION_ITEM_INSTANCE_TYPE]

                [#local objectId = getObjectId(item)]
                [#local objectName = getObjectName(item)]
                [#local objectType = getObjectType(item)]
                [#local pluralType = getPluralType(item)]

                [#-- Add to object set --]
                [#local context =
                    mergeObjects(
                        context,
                        {
                            "Sets" : {
                                pluralType :
                                    addToObjectSet((context.Sets[pluralType])!{}, item)
                            }
                        }
                    )
                ]

                [#if needsNewContext(item)]
                    [#local newContextStream = []]
                    [#-- Find end of stream for current object instance --]
                    [#local startIndex = index + 1]
                    [#if (lastIndex >= startIndex)]
                        [#list stream[startIndex..] as nextItem]
                            [#if
                                (getConfigurationItemType(nextItem) == CONFIGURATION_ITEM_INSTANCE_TYPE) &&
                                (getObjectType(nextItem) == objectType)]
                                [#local nextIndexToProcess = startIndex + nextItem?index]
                                [#local endIndex = nextIndexToProcess - 1]
                                [#if (endIndex >= startIndex)]
                                    [#local newContextStream = stream[startIndex..endIndex]]
                                [/#if]
                                [#break]
                            [/#if]
                            [#if nextItem?is_last]
                                [#local nextIndexToProcess = lastIndex + 1]
                                [#local newContextStream = stream[startIndex..]]
                            [/#if]
                        [/#list]
                    [/#if]

                    [#-- Add subcontext --]
                    [#local filter =
                        (context.Filter!{}) +
                        {
                            objectType :
                                [objectId] +
                                (objectId != objectName)?then([objectName], [])
                        }]
                    [#local context +=
                        {
                            "Contexts" :
                                (context.Contexts![]) +
                                [
                                    createContext(
                                        {
                                            "Instance" : item,
                                            "Filter" : filter
                                        },
                                        newContextStream
                                    )
                                ]
                        }]
                [/#if]
                [#break]

            [#case CONFIGURATION_ITEM_TEMPLATE_TYPE]
                [#-- Merge new value --]
                [#local context =
                    mergeObjects(context, {"Templates" : {getObjectType(item) : item}})]
                [#break]

            [#case CONFIGURATION_ITEM_SET_TYPE]
                [#-- Merge new value --]
                [#local context =
                    mergeObjects(context, {"Sets" : {getObjectType(item) : item}})]
                [#break]
        [/#switch]
    [/#list]
    [#return context]
[/#function]

[#function qualifyContext context filter]

    [#-- Ignore context if it doesn't match the filter --]
    [#if !filterMatch(context.Filter, filter, FILTER_ONETOONE_MATCH_BEHAVIOUR)]
        [#return {}]
    [/#if]

    [#-- Check for more specific qualifiers --]
    [#local templates = {}]
    [#list context.Templates as type,template]
        [#local templates += {type : qualifyEntity(template, filter)}]
    [/#list]

    [#local sets = {}]
    [#list context.Sets as type,set]
        [#local qualifiedSet = {}]
        [#list set as key,value]
            [#local qualifiedSet += {key : qualifyEntity(value, filter)}]
        [/#list]
        [#local sets += {type, qualifiedSet}]
    [/#list]

    [#local childContexts = []]
    [#list context.Contexts as childContext]
        [#local qualifiedChildContext = qualifyContext(childContext, filter)]
        [#if qualifiedChildContext?has_content]
            [#local childContexts += [qualifiedChildContext]]
        [/#if]
    [/#list]

    [#return
        {
            "Instance" : context.Instance,
            "Filter" : context.Filter,
            "Templates" : templates,
            "Sets" : sets,
            "Contexts" : childContexts
        }]

[/#function]


[#-- Overrides

Overrides leverage the context hierarchy to allow object instances in one context
to inherit configuration from ancestor contexts, but optionally "override" the
inherited values.

The effective value of a configuration object at a given level in the hierarchy is
the result of merging any template(s) then instance of the object at each context
from the root to the given level. Attribute values in an object instance take
precedence over values from the template(s), and child contexts take precedence
over ancestor contexts.

As an example, the default AWS region for product deployments might be defined
in the Product object template at the Tenant level context, but then overridden
in the object instance for each product.

A simple way to think about overrides and qualifiers is that overrides provide
vertical variation, while qualifiers provide horizontal variation.
--]

[#function inheritFromParentContext parentContext context]
    [#local templates = mergeObjects(parentContext.Templates!{}, context.Templates)]
    [#local sets = mergeObjects(parentContext.Sets!{}, context.Sets)]

    [#list sets as type,set]
        [#local objectTemplate = templates[getSingularType(type)]!{}]
        [#if objectTemplate?has_content]
            [#local templatedSet = {}]
            [#list set as key,value]
                [#local templatedSet += {key : mergeObjects(objectTemplate, value)}]
            [/#list]
            [#local sets += {type : templatedSet}]
        [/#if]
    [/#list]

    [#local result =
       {
            "Instance" : context.Instance,
            "Filter" : context.Filter,
            "Templates" : templates,
            "Sets" : sets
        }]

    [#local childContexts = []]
    [#list context.Contexts as childContext]
        [#local childContexts += [inheritFromParentContext(result, childContext)]]
    [/#list]

    [#return
        result +
        {
            "Contexts" : childContexts
        }]

[/#function]

[#function overrideContext context]
    [#return inheritFromParentContext({}, context)]
[/#function]
