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

[#assign frameworkObjectAttributes = [
    {
        "Names" : "Id",
        "Description" : "An instance idenfying value. Provides a default value for the Name",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "Name",
        "Description" : "Provides a default value for the Id",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "Title",
        "Description" : "A descriptive title for human consumption",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "Description",
        "Description" : "An object descriptor for human consumption",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "Enabled",
        "Description" : "Should this object configuration be considered as Enabled?",
        "Types" : BOOLEAN_TYPE
    }
]]

[#function getFrameworkObjectAttributes obj]
    [#return getObjectAttributes(
        obj,
        asFlattenedArray(frameworkObjectAttributes?map(a -> a.Names))
    )]
[/#function]

[#function getNonFrameworkObjectAttributes obj]
    [#return removeObjectAttributes(
        obj,
        asFlattenedArray(frameworkObjectAttributes?map(a -> a.Names))
    )]
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

[#assign frameworkObjectAttributes += [{
    "Names" : "Order",
    "Description" : "A list of attribute keys to be processed sequentially, prior to any absent the list",
    "Types" : ARRAY_OF_STRING_TYPE
}]]

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

[#assign frameworkObjectAttributes += [
    {
        "Names" : [ "Parent", "Parents" ],
        "Description" : "Enables organising objects into a family tree whilst preserving data type",
        "Types" : STRING_TYPE
    }
]]
