[#ftl]
[#-------------------
-- Logic functions --
---------------------]

[#function valueIfTrue value condition otherwise={} ]
    [#return condition?then(value, otherwise) ]
[/#function]

[#function valueIfContent value content otherwise={} ]
    [#return valueIfTrue(value, content?has_content, otherwise) ]
[/#function]

[#function arrayIfTrue value condition otherwise=[] ]
    [#return condition?then(asArray(value), otherwise) ]
[/#function]

[#function arrayIfContent value content otherwise=[] ]
    [#return valueIfContent(asArray(value), content, otherwise) ]
[/#function]

[#function contentIfContent value otherwise={} ]
    [#return valueIfTrue(value, value?has_content, otherwise) ]
[/#function]

[#function attributeIfTrue attribute condition value ]
    [#return valueIfTrue({attribute : value}, condition) ]
[/#function]

[#function attributeIfContent attribute content value={} ]
    [#return attributeIfTrue(
        attribute,
        content?has_content,
        value?has_content?then(value, content)) ]
[/#function]

[#function numberAttributeIfContent attribute content value={}]
    [#return attributeIfTrue(
        attribute,
        content?has_content,
        value?has_content?then(
            value?number,
            content?has_content?then(
                content?number,
                ""
            )
        )
    )]
[/#function]

[#------------------------
-- Powers of 2 handling --
--------------------------]

[#assign powersOf2 = [1] ]
[#list 0..31 as index]
    [#assign powersOf2 += [2*powersOf2[index]] ]
[/#list]

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


[#-- finds the closest perfect sqaure of a given value with lowest value preferred --]
[#function intPerfectSquare value ]
    [#local lastPerfect = 1 ]
    [#list 1..100 as square]
        [#local multiple = square * square ]
        [#if multiple == value ]
            [#return square ]
        [/#if]
        [#local lastPerfect = square ]
        [#if multiple > value ]
            [#break]
        [/#if]
    [/#list]
    [#return lastPerfect ]
[/#function]

[#-------------------
-- String handling --
---------------------]

[#function replaceAlphaNumericOnly string delimeter=""]
    [#return string?replace("[^a-zA-Z\\d]", delimeter, "r" )]
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

[#function asSerialisableString arg]
    [#if arg?is_hash || arg?is_sequence ]
        [#return getJSON(arg) ]
    [#else]
        [#if arg?is_boolean || arg?is_number ]
            [#return arg?c]
        [#else]
            [#return arg ]
        [/#if]
    [/#if]
[/#function]

[#------------------
-- Array handling --
--------------------]

[#-- Recursively concatenate sequence of non-empty strings with a separator --]
[#function concatenate args separator]
    [#local content = []]
    [#list asFlattenedArray(args) as arg]
        [#local argValue = arg!"Hamlet:ERROR_INVALID_ARG_TO_CONCATENATE"]
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
                [#case "."]
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

[#function getArrayIntersection array1 array2]
    [#local result = []]
    [#local array2AsArray = asArray(array2)]
    [#list asArray(array1) as element]
        [#if array2AsArray?seq_contains(element)]
            [#local result += [element]]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#function firstContent alternatives=[] otherwise={}]
    [#list asArray(alternatives) as alternative]
        [#if alternative?has_content]
            [#return alternative]
        [/#if]
    [/#list]
    [#return otherwise ]
[/#function]

[#function removeValueFromArray array string ]
    [#local result = [] ]
    [#list array as item ]
        [#if item != string ]
            [#local result += [ item ] ]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#function splitArray array index]
    [#if array?has_content && (index < array?size)]
        [#return array[index..]]
    [/#if]
    [#return [] ]
[/#function]

[#-------------------
-- Object handling --
---------------------]

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

[#macro toJSON obj escaped=false]
    ${getJSON(obj, escaped)}[/#macro]

[#function filterObjectAttributes obj attributes removeAttributes=false]
    [#local result = {}]
    [#local atts = asFlattenedArray(attributes)]
    [#list obj as key,value]
        [#if atts?seq_contains(key)]
            [#if removeAttributes][#continue][/#if]
        [#else]
            [#if !removeAttributes][#continue][/#if]
        [/#if]
        [#local result += {key : value}]
    [/#list]
    [#return result]
[/#function]

[#function getObjectAttributes obj attributes]
    [#return filterObjectAttributes(obj, attributes, false)]
[/#function]

[#function removeObjectAttributes obj attributes]
    [#return filterObjectAttributes(obj, attributes, true)]
[/#function]

[#function findAttributeInObject obj keyPath  ]
    [#list keyPath as key ]
        [#if obj[key]?? ]
            [#if key?is_last ]
                [#return obj[key]]
            [#else]
                [#return findAttributeInObject(obj[key], keyPath[ (key?index +1) ..])]
            [/#if]
        [/#if]
        [#return ""]
    [/#list]
[/#function]

[#--------------------
-- Combine entities --
----------------------

Combine two entities into a single entity based on a "CombineBehaviour".

"replace" means the righthand value replaces the lefthand value.
"add" behaves the same as replace, but object or array values are added.
"merge" behaves the same as replace, but object values are merged.
"append" behaves the same as merge except that array values are added, with
the righthand value converted to an array.
"unique" behaves the same as append, except that only unique righthand values
are added.

--]

[#assign REPLACE_COMBINE_BEHAVIOUR = "replace"]
[#assign ADD_COMBINE_BEHAVIOUR = "add"]
[#assign MERGE_COMBINE_BEHAVIOUR = "merge"]
[#assign APPEND_COMBINE_BEHAVIOUR = "append"]
[#assign UNIQUE_COMBINE_BEHAVIOUR = "unique"]

[#function combineEntities left right behaviour=MERGE_COMBINE_BEHAVIOUR]

    [#-- Handle replace first --]
    [#if behaviour == REPLACE_COMBINE_BEHAVIOUR]
        [#return right ]
    [/#if]

    [#-- Default is to return the right value --]
    [#local result = right]

    [#if left?is_sequence || right?is_sequence]
        [#-- Handle arrays --]
        [#switch behaviour]
            [#case MERGE_COMBINE_BEHAVIOUR]
                [#local result = asArray(right) ]
                [#break]
            [#case ADD_COMBINE_BEHAVIOUR]
            [#case APPEND_COMBINE_BEHAVIOUR]
                [#local result = asArray(left) + asArray(right) ]
                [#break]
            [#case UNIQUE_COMBINE_BEHAVIOUR]
                [#local result = getUniqueArrayElements(left, right) ]
                [#break]
        [/#switch]
    [#else]
        [#if left?is_hash && right?is_hash]
            [#-- Handle objects --]
            [#switch behaviour]
                [#case ADD_COMBINE_BEHAVIOUR]
                    [#local result = left + right]
                    [#break]
                [#default]
                    [#-- For other behaviours, merge objects --]
                    [#local result = left]
                    [#list right as key,value]
                        [#local newValue = value]
                        [#if left[key]??]
                            [#local newValue = combineEntities(left[key], value, behaviour) ]
                        [/#if]
                        [#local result += { key : newValue } ]
                    [/#list]
                [#break]
            [/#switch]
        [/#if]
    [/#if]
    [#return result]
[/#function]

[#function mergeObjects objects...]
    [#local result = {} ]
    [#list asFlattenedArray(objects) as object]
        [#if object?index == 0]
            [#local result = object]
        [#else]
            [#local result = combineEntities(result, object) ]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#-----------------
-- Type handling --
-------------------]

[#assign OBJECT_TYPE = "object" ]
[#assign ARRAY_TYPE = "array" ]
[#assign STRING_TYPE = "string" ]
[#assign NUMBER_TYPE = "number" ]
[#assign BOOLEAN_TYPE = "boolean" ]
[#assign ANY_TYPE = "any" ]
[#assign UNKNOWN_TYPE = "unknown" ]
[#assign REF_TYPE = r"$ref"]
[#assign ARRAY_OF_OBJECT_TYPE  = [ARRAY_TYPE, OBJECT_TYPE] ]
[#assign ARRAY_OF_STRING_TYPE  = [ARRAY_TYPE, STRING_TYPE] ]
[#assign ARRAY_OF_NUMBER_TYPE  = [ARRAY_TYPE, NUMBER_TYPE] ]
[#assign ARRAY_OF_BOOLEAN_TYPE = [ARRAY_TYPE, BOOLEAN_TYPE] ]
[#-- Array of any is different to array in that value will be forced to an array --]
[#assign ARRAY_OF_ANY_TYPE     = [ARRAY_TYPE, ANY_TYPE] ]

[#function getBaseType arg]
    [#if arg?is_hash]
        [#return OBJECT_TYPE]
    [/#if]
    [#if arg?is_sequence]
        [#return ARRAY_TYPE]
    [/#if]
    [#if arg?is_string]
        [#return STRING_TYPE]
    [/#if]
    [#if arg?is_number]
        [#return NUMBER_TYPE]
    [/#if]
    [#if arg?is_boolean]
        [#return BOOLEAN_TYPE]
    [/#if]
    [#return UNKNOWN_TYPE]
[/#function]

[#function isOneOfTypes arg types]
    [#local typesArray = asArray(types) ]
    [#return
        typesArray?seq_contains(getBaseType(arg)) ||
        typesArray?seq_contains(ANY_TYPE) ]
[/#function]

[#function isArrayOfType types]
    [#local typesArray = asArray(types) ]
    [#return (typesArray?size > 1) && typesArray?seq_contains(ARRAY_TYPE) ]
[/#function]

[#function asType arg types]
    [#return valueIfTrue(asFlattenedArray(arg), isArrayOfType(types), arg) ]
[/#function]

[#function isOfType arg types]
    [#if isArrayOfType(types) ]
        [#-- Expecting an array of specific types --]
        [#list asType(arg, types) as element]
            [#if !isOneOfTypes(element, types) ]
                [#return false]
            [/#if]
        [/#list]
    [#else]
        [#-- Match against --]
        [#return isOneOfTypes(arg, types) ]
    [/#if]
    [#return true]
[/#function]

[#----------------------
-- IPv4 CIDR handling --
------------------------]

[#-- calculates the subnet mask requied to create enough networks
        based on the number of things in the provided sizes --]
[#function getSubnetMaskFromSizes networkCIDR sizes... ]
    [#local subnetMask = networkCIDR?split("/")[1]]
    [#list sizes as size ]
        [#if size > 0 && size < 32 ]
            [#-- must be an even size to find sqaure root which can be used --]
            [#local evenSize = (size / 2 )?round * 2 ]
            [#local subnetMask = subnetMask?number + intPerfectSquare(evenSize)?number ]
        [/#if]
    [/#list]
    [#return subnetMask]
[/#function]

[#-- given a network return the networks contained in it based on the subnetCIDR mask you want --]
[#function getSubnetsFromNetwork networkCIDR subnetCIDRMask ]
    [#return IPAddress__getSubNetworks(networkCIDR, subnetCIDRMask )?eval ]
[/#function]

[#function getHostsFromNetwork networkCIDR ]
    [#local networkIPs = getSubnetsFromNetwork(networkCIDR, 32)?map(cidr -> (cidr?split("/"))[0] )]

    [#-- networks with greater than 2 hosts ( i.e. above /31 ) --]
    [#-- reserve the first and last address and can't be used for hosts --]
    [#if networkIPs?size - 2 > 1 ]
        [#return networkIPs[1..(networkIPs?size - 2)]]
    [#else]
        [#return networkIPs]
    [/#if]
[/#function]

[#----------------------------
-- Dynamic template loading --
------------------------------]
[#assign includeOnceTemplates = {} ]

[#function includeTemplate template includeOnce=false relativeToCaller=false ]
    [#if relativeToCaller]
        [#local t = template?absolute_template_name(.caller_template_name)]
    [#else]
        [#local t = template?ensure_starts_with("/")]
    [/#if]
    [#if includeOnce && includeOnceTemplates[t]?? ]
        [#return true]
    [/#if]
    [#local templateStatus = .get_optional_template(t)]
    [#if templateStatus.exists]
        [@templateStatus.include /]
        [#if includeOnce]
            [#assign includeOnceTemplates += {t:{}} ]
        [/#if]
        [#return true]
    [/#if]
    [#return false]
[/#function]

[#-- Include multiple templates at once - ignore if not present --]
[#-- If the template is an array, a filename is assembled   --]
[#macro includeTemplates templates=[] includeOnce=true ]
    [#list templates as template]
        [#if template?is_sequence]
            [#local filename = concatenate(template, "/") + ".ftl"]
        [#else]
            [#local filename = template?ensure_ends_with(".ftl")]
        [/#if]
        [@debug
            message="Checking for template " + filename + "..."
            enabled=false
        /]
        [#if includeTemplate(filename, includeOnce)]
            [@debug
                message="Loaded template " + filename
                enabled=false
            /]
        [/#if]
    [/#list]
[/#macro]

[#--------------------------------
-- Dynamic directive invocation --
----------------------------------]

[#function getFirstDefinedDirective directives=[] ]
    [#list asArray(directives) as directive]
        [#if directive?is_sequence]
            [#local name = concatenate(directive, "_") ]
        [#elseif directive?is_string]
            [#local name = directive ]
        [#else]
            [@precondition
                function="getFirstDefinedDirective"
                context=directives
                detail="Directive must be an array or a string"
            /]
            [#return ""]
        [/#if]
        [#if (.vars[name]!"")?is_directive]
            [#return name]
        [/#if]
    [/#list]
    [#return ""]
[/#function]

[#function invokeFunction fn args...]

    [#if (.vars[fn]!"")?is_directive]
        [#return (.vars[fn])(asFlattenedArray(args)) ]
    [#else]
        [@debug
            message="Unable to invoke function"
            context=fn
            enabled=true
        /]
    [/#if]
    [#return {} ]
[/#function]

[#macro invokeMacro macro args...]

    [#if (.vars[macro]!"")?is_directive]
        [@(.vars[macro]) asFlattenedArray(args) /]
    [#else]
        [@debug
            message="Unable to invoke macro"
            context=macro
            enabled=false
        /]
    [/#if]
[/#macro]

[#function invokeFunctionOn fn targets args...]
    [#if targets?is_sequence]
        [#local result = [] ]
        [#list targets as target]
            [#local result += [invokeFunction(fn, target, args)] ]
        [/#list]
    [#elseif targets?is_hash]
        [#local result = {} ]
        [#list targets as key,value]
            [#local result +=
                {
                    key :
                        invokeFunction(
                            fn,
                            {
                                "Id" : key
                            } + value,
                            args
                        )
                } ]
        [/#list]
    [#else]
        [#local result = {} ]
        [@precondition
            function="invokeFunctionOn"
            context=targets
            detail="Targets must be provided as an array or an object"
        /]
    [/#if]
    [#return result ]
[/#function]

[#macro invokeMacroOn macro targets args...]
    [#if targets?is_sequence]
        [#list targets as target]
            [@invokeMacro macro target args /]
        [/#list]
    [#elseif targets?is_hash]
        [#local result = {} ]
        [#list targets as key,value]
            [@invokeMacro
                macro
                {
                    "Id" : key
                } + value
                args
            /]
        [/#list]
    [#else]
        [@precondition
            function="invokeMacroOn"
            context=targets
            detail="Targets must be provided as an array or an object"
        /]
    [/#if]

[/#macro]

[#--------------------------
-- Date/time manipulation --
----------------------------]

[#function datetimeAsString datetime ms=true utc=false]
    [#local format = "iso"]
    [#if utc]
        [#local format += "_utc"]
    [/#if]
    [#if ms]
        [#local format += "_ms"]
    [/#if]
    [#return datetime?string[format]]
[/#function]

[#function duration end start ]
    [#return (end?long - start?long)]
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
                    "PopulateMissingChildren" : true,
                    "AttributeSet" : "",
                    "Component" : ""
                } ]
            [#if normalisedAttribute.Names?seq_contains("InhibitEnabled") ]
                [#local inhibitEnabled = true ]
            [/#if]
            [#if attribute?is_hash ]
                [#local names = attribute.Names!"Hamlet:Missing" ]
                [#if (names?is_string) && (names == "Hamlet:Missing") ]
                    [@fatal
                        message="Attribute must have a \"Names\" attribute"
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
                        "PopulateMissingChildren" : attribute.PopulateMissingChildren!true,
                        "AttributeSet" : attribute.AttributeSet!"",
                        "Component" : attribute.Component!""
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
                        "PopulateMissingChildren" : true,
                        "AttributeSet" : "",
                        "Component" : ""
                    }
                ] +
                normalisedAttributes ]
        [/#if]
    [/#if]

    [#-- If attribute value is defined as an AttributeSet, evaluate --]
    [#-- it and use the result as the attribute's Children.         --]
    [#local evaluatedRefAttributes = []]
    [#list normalisedAttributes![] as attribute]
        [#if attribute.AttributeSet?has_content ]
            [#-- AttributeSet provides the child attributes --]
            [#local children = (attributeSetConfiguration[attribute.AttributeSet].Attributes)![] ]

            [#if !children?has_content ]
                [@fatal
                    message="Unable to determine child attributes from AttributeSet"
                    context=attribute
                /]
                [#-- Add a minimal child configuration to ensure processing completes --]
                [#local children = [{"Names" : "AttributeSet", "Types" : STRING_TYPE}] ]
            [/#if]

            [#local evaluatedRefAttributes += [ attribute + { "Children" : children } ] ]
        [#else]
            [#-- Attribute has no reference to evaluate, so add to results --]
            [#local evaluatedRefAttributes += [attribute]]
        [/#if]
    [/#list]

    [#-- Determine the attribute values --]
    [#local result = {} ]
    [#if evaluatedRefAttributes?has_content]
        [#list evaluatedRefAttributes as attribute]

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
                    candidates?has_content &&
                    ( ! attribute.DefaultProvided )]
                [@fatal
                    message="Mandatory attribute missing"
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
                [#-- There are three options for child content
                     - array of children (Type = ARRAY_OF_OBJECT_TYPE)
                     - children as subobjects (Subobjects = true)
                     - direct children (the default)
                --]

                [#-- First determine if any child content has been provided --]
                [#local childContent = [] ]
                [#list candidates as object]
                    [#if object[providedName]??]
                        [#local childContent += [object[providedName]] ]
                    [/#if]
                [/#list]

                [#if populateMissingChildren || childContent?has_content]
                    [#-- Something to work with --]

                    [#if isArrayOfType(attribute.Types)]
                        [#local attributeResult = [] ]
                        [#-- Handle array of objects          --]
                        [#-- TODO(mfl) Add duplicate handling --]
                        [#list childContent as childArray]
                            [#if !isOfType(childArray, attribute.Types)]
                                [@fatal
                                    message="One or more children not of an accepted type"
                                    context=childArray /]
                                [#continue]
                            [/#if]
                            [#list asArray(childArray) as childEntry]
                                [#if childEntry?is_hash]
                                    [#local attributeResult +=
                                        [
                                            getCompositeObject(attribute.Children, childEntry)
                                        ]
                                    ]
                                [#else]
                                    [#-- Include non-object content --]
                                    [#local attributeResult += [childEntry] ]
                                [/#if]
                            [/#list]
                        [/#list]
                    [#else]
                        [#local attributeResult = {} ]

                        [#if attribute.SubObjects ]
                            [#-- Handle subobjects --]
                            [#local subobjectKeys = [] ]
                            [#list childContent as childObject]
                                [#if childObject?is_hash]
                                    [#list childObject as key,value]
                                        [#if value?is_hash]
                                            [#local subobjectKeys += [key] ]
                                        [#else]
                                            [@fatal
                                                message="Subobject content is not a hash"
                                                context=childObject /]
                                        [/#if]
                                    [/#list]
                                [#else]
                                    [@fatal
                                        message="Child content is not a hash"
                                        context=childObject /]
                                [/#if]
                            [/#list]
                            [#list subobjectKeys as subobjectKey ]
                                [#if subobjectKey == "Configuration" ]
                                    [#continue]
                                [/#if]
                                [#local subobjectValues = [] ]
                                [#list childContent as childObject ]
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
                                                        "Types" : STRING_TYPE,
                                                        "Mandatory" : true
                                                    }
                                                ] +
                                                attribute.Children,
                                                [
                                                    {
                                                        "Id" : subobjectKey,
                                                        "Name" : subobjectKey
                                                    }
                                                ] +
                                                subobjectValues
                                            )
                                    }
                                ]
                            [/#list]
                        [#else]
                            [#-- Handle direct children --]
                            [#local attributeResult =
                                populateMissingChildren?then(
                                    {
                                        "Configured" : providedName?has_content
                                    },
                                    {}
                                ) +
                                getCompositeObject(attribute.Children, childContent)
                            ]
                        [/#if]
                    [/#if]
                    [#local result += { attribute.Names[0] : attributeResult } ]
                [/#if]
            [#else]
                [#-- Combine any provided and/or default values --]
                [#if providedName?has_content ]
                    [#-- Perform type conversion and type checking --]
                    [#local providedValue = asType(providedValue, attribute.Types) ]
                    [#if !isOfType(providedValue, attribute.Types) ]
                        [@fatal
                          message="Attribute is not of the correct type"
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
                                    [@fatal
                                      message="Attribute value is not one of the expected values"
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
                            "Types" : STRING_TYPE
                        }
                    ],
                    base
                ).Parent)!"" ]
        [#local parentIds =
                (getCompositeObject(
                    [
                        {
                            "Names" : "Parents",
                            "Types" : ARRAY_OF_STRING_TYPE
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

[#--------------------
-- Cache management --
----------------------]

[#function initialiseCache]
    [#return {} ]
[/#function]

[#-- Add content to a cache --]
[#function addToCache cache contents... ]
    [#return mergeObjects(cache, contents) ]
[/#function]

[#-- Add a specific section of the cache --]
[#function addToCacheSection cache path=[] content={} ]
    [#local cacheContent = content ]
    [#list path?reverse as key]
        [#local cacheContent = { key: cacheContent } ]
    [/#list]

    [#return addToCache(cache, cacheContent) ]
[/#function]

[#-- Clear one or more sections of a cache --]
[#function clearCache cache paths={} ]
    [#local result = {} ]

    [#if paths?keys?size > 0]
        [#-- Specific attributes provided for clearing --]
        [#list cache as key,value]
            [#if paths[key]??]
                [#if paths[key]?has_content]
                    [#-- Part of the cache to clear --]
                    [#local subContent = clearCache(value, paths[key]) ]
                    [#if subContent?has_content]
                        [#local result += { key : subContent } ]
                    [#else]
                        [#-- No subcontent so remove the key --]
                    [/#if]
                [#else]
                    [#-- The key and its contents are to be cleared --]
                [/#if]
            [#else]
                [#-- Leave cache intact --]
                [#local result += {key, value}]
            [/#if]
        [/#list]
    [#else]
        [#-- Clear the entire cache --]
    [/#if]
    [#return result]
[/#function]

[#-- Clear a specific section of the cache --]
[#function clearCacheSection cache path=[] ]
    [#local paths = {} ]
    [#list path?reverse as key]
        [#local paths = { key: paths } ]
    [/#list]

    [#return clearCache(cache, paths) ]
[/#function]

[#-- Get a specific section of the cache --]
[#function getCacheSection cache path=[] ]
    [#local result = cache ]
    [#list path as key]
        [#local result = result[key]!{} ]
    [/#list]

    [#return result ]
[/#function]

[#-------------------------
-- Dictionary management --
---------------------------]

[#function initialiseDictionary]
    [#return initialiseCache() ]
[/#function]

[#function addDictionaryEntry dictionary key=[] entry={} ]
    [#return addToCacheSection(dictionary, asArray(key) + ["Content"], entry) ]
[/#function]

[#function removeDictionaryEntry dictionary key=[] ]
    [#return clearCacheSection(dictionary, asArray(key) + ["Content"]) ]
[/#function]

[#function getDictionaryEntry dictionary key=[] ]
    [#return getCacheSection(dictionary, asArray(key) + ["Content"]) ]
[/#function]

[#--------------------
-- Stack management --
----------------------]

[#function initialiseStack]
    [#return [] ]
[/#function]

[#function pushOnStack stack content]
    [#return [content] + stack ]
[/#function]

[#function isStackNotEmpty stack]
    [#return stack?size > 0]
[/#function]

[#function isStackEmpty stack]
    [#return !isStackNotEmpty(stack) ]
[/#function]

[#function popOffStack stack]
    [#if isStackNotEmpty(stack)]
        [#return stack[1..] ]
    [/#if]
    [@fatal message="Attempt to pop empty stack" /]
    [#return [] ]
[/#function]

[#function getTopOfStack stack]
    [#if isStackNotEmpty(stack)]
        [#return stack[0] ]
    [/#if]
    [@fatal message="Attempt to get top of empty stack" /]
    [#return {} ]
[/#function]

[#---------
-- Paths --
-----------]

[#function formatPath absolute parts...]
    [#return
        absolute?then("/","") +
        concatenate(parts, "/")]
[/#function]

[#function formatAbsolutePath parts...]
    [#return formatPath(true, parts)]
[/#function]

[#function formatRelativePath parts...]
    [#return formatPath(false, parts)]
[/#function]

[#------------------
-- Semver support --
--------------------]

[#-- Comparisons/naming roughly aligned to https://github.com/npm/node-semver --]

[#--
Strip any leading "v" (note we handle leading = in semver_satisfies)
Convert any range indicators ("x" or "X" or "*") to 0
--]

[#function semverClean version]
    [#-- Handle the full format --]
    [#local match = version?matches(r"^v?(0|[1-9][0-9]*|x|X)\.(0|[1-9][0-9]*|x|X)\.(0|[1-9][0-9]*|x|X)(\-([^+]+))?(\+(.*))?$") ]
    [#if match]
        [#local major = match?groups[1]?replace("[x*]", "0", "ir")?number ]
        [#local minor = match?groups[2]?replace("[x*]", "0", "ir")?number ]
        [#local patch = match?groups[3]?replace("[x*]", "0", "ir")?number ]
        [#local pre   = match?groups[5] ]
        [#local build = match?groups[7] ]

        [#return
            [
                major + "." + minor + "." + patch +
                    valueIfContent(
                        "-" + pre,
                        pre,
                        ""
                    ) +
                    valueIfContent(
                        "+" + build,
                        build,
                        ""
                    ),
                major,
                minor,
                patch,
                pre,
                build
            ]
        ]
    [/#if]

    [#-- Handle major.minor --]
    [#local match = version?matches(r"^v?(0|[1-9][0-9]*|x|X)\.(0|[1-9][0-9]*|x|X)$") ]
    [#if match]
        [#local major = match?groups[1]?replace("[x*]", "0", "ir")?number ]
        [#local minor = match?groups[2]?replace("[x*]", "0", "ir")?number ]
        [#local patch = 0 ]
        [#return
            [
                major + "." + minor + "." + patch,
                major,
                minor,
                patch,
                "",
                ""
            ]
        ]
    [/#if]

    [#-- Handle major --]
    [#local match = version?matches(r"^v?(0|[1-9][0-9]*|x|X)$") ]
    [#if match]
        [#local major = match?groups[1]?replace("[x*]", "0", "ir")?number ]
        [#local minor = 0 ]
        [#local patch = 0 ]
        [#return
            [
                major + "." + minor + "." + patch,
                major,
                minor,
                patch,
                "",
                ""
            ]
        ]
    [/#if]

    [#return [] ]
[/#function]

[#assign SEMVER_GREATER_THAN = 1]
[#assign SEMVER_EQUAL = 0]
[#assign SEMVER_LESS_THAN = -1]
[#assign SEMVER_FORMAT_ERROR = -2]

[#function semverCompare version1 version2]

    [#local v1 = semverClean(version1) ]
    [#local v2 = semverClean(version2) ]

    [#if ! (v1?has_content && v2?has_content) ]
        [#-- format error --]
        [#return SEMVER_FORMAT_ERROR]
    [/#if]

    [#-- major, minor, patch comparison --]
    [#list 1..3 as index]
        [#if v1[index] < v2[index] ]
            [#return SEMVER_LESS_THAN]
        [/#if]
        [#if v1[index] > v2[index] ]
            [#return SEMVER_GREATER_THAN]
        [/#if]
    [/#list]

    [#-- prerelease should compare with the ASCII order --]
    [#if ! v1[4]?has_content && v2[4]?has_content ]
        [#return SEMVER_LESS_THAN]
    [/#if]
    [#if v1[4]?has_content && ! v2[4]?has_content ]
        [#return SEMVER_GREATER_THAN]
    [/#if]
    [#if v1[4]?has_content && v2[4]?has_content ]
        [#if v1[4] < v2[4] ]
            [#return SEMVER_LESS_THAN]
        [/#if]
        [#if v1[4] > v2[4] ]
            [#return SEMVER_GREATER_THAN]
        [/#if]
    [/#if]

    [#-- equal --]
    [#return SEMVER_EQUAL]
[/#function]

[#assign SEMVER_SATISFIED = 1]
[#assign SEMVER_NOT_SATISFIED = 0]

[#--
A range is a list of comparator sets joined by "||"" or "|", true if one of sets is true
A comparator set is a list of comparators, true if all comparators are true
A comparator is an operator and a version
--]
[#function semverSatisfies version range]

    [#-- First determine the comparator sets    --]
    [#-- Standardise on single "|" as separator --]
    [#local comparatorSets = range?replace("||", "|")?split("|") ]

    [#list comparatorSets as comparatorSet]

        [#-- assume all comparators will succeed --]
        [#local comparatorSetMatch = true ]

        [#-- determine the comparators for each set --]
        [#list comparatorSet?split(r"\s+","r") as comparator]

            [#-- determine the comparator operator and version --]
            [#local match = comparator?matches(r"^(<|<=|>|>=|=)(.+)$") ]
            [#if !match]
                [#return SEMVER_FORMAT_ERROR]
            [/#if]

            [#-- obtain the result of the version comparison --]
            [#local compareResult = semverCompare(version, match?groups[1]) ]
            [#if compareResult == SEMVER_FORMAT_ERROR]
                [#return SEMVER_FORMAT_ERROR]
            [/#if]

            [#-- check the provided operator against the version comparison result --]
            [#switch match?groups[1]]
                [#case r"<"]
                    [#if compareResult == SEMVER_LESS_THAN]
                        [#continue]
                    [/#if]
                    [#break]

                [#case r"<="]
                    [#if (compareResult == SEMVER_LESS_THAN) || (compareResult == SEMVER_EQUAL) ]
                        [#continue]
                    [/#if]
                    [#break]

                [#case r">"]
                    [#if compareResult == SEMVER_GREATER_THAN]
                        [#continue]
                    [/#if]
                    [#break]

                [#case r">="]
                    [#if (compareResult == SEMVER_GREATER_THAN) || (compareResult == SEMVER_EQUAL) ]
                        [#continue]
                    [/#if]
                    [#break]

                [#case r">"]
                    [#if compareResult == SEMVER_EQUAL]
                        [#continue]
                    [/#if]
                    [#break]

                [#default]
                    [#return SEMVER_FORMAT_ERROR]
            [/#switch]

            [#-- at least one comparison failed --]
            [#local comparatorSetMatch = false ]
            [#break]
        [/#list]

        [#if comparatorSetMatch]
            [#return SEMVER_SATISFIED]
        [/#if]
    [/#list]

    [#return SEMVER_NOT_SATISFIED]
[/#function]


[#------------------
-- Filter support --
--------------------]

[#--
A filter consists of one or more string values for each of one or more filter attributes.

{
    "Attribute1" : ["value1", "value2"],
    "Attribute2" : ["value3", "value4", "value5"]
}

The typical use of filters involves their comparison with a "Match Behaviour" controlling the
algorithm used. Algorithms are defined in terms of a

Current Filter - a filter representing current state, and
Match Filter - filter to be checked.

The "any" behaviour requires that at least one value of the "Any" attribute of the
Match Filter needs to match one value in any of the attributes of the Current Filter.

Current Filter
{
    "Environment" : ["prod"]
}

matches

Match Filter
{
    "Any" : ["prod"]
}

The "onetoone" behaviour requires that a value of each attribute of the Match Filter
must match a value of the same named attribute in the Current Filter. The Match
Filter is thus a subset of the Current Filter.

Current Filter
{
    "Product" : ["ics"],
    "Environment" : ["prod"]
    "Segment" : ["default"]
}

matches

Match Filter
{
    "Product" : ["ics"],
    "Environment" : ["prod"],
    "Segment" : ["e7", "default"]
}

but the Current Filter
{
    "Environment" : ["prod"]
    "Segment" : ["default"]
}

does not match.

The "exactonetoone" behaviour uses the same match logic as "onetoone", but
also checks that the Current Filter doesn't have any attributes that
are not included in the Match Filter

--]

[#assign ANY_FILTER_MATCH_BEHAVIOUR = "any"]
[#assign ONETOONE_FILTER_MATCH_BEHAVIOUR = "onetoone"]
[#assign EXACTLY_ONETOONE_FILTER_MATCH_BEHAVIOUR = "exactlyonetoone"]

[#function isValidFilter filter ]
    [#return filter?is_hash]
[/#function]

[#function isFilterAttribute filter attribute]
    [#return filter[attribute]??]
[/#function]

[#function getFilterAttribute filter attribute]
    [#return asArray(filter[attribute]![]) ]
[/#function]

[#function getFilterAttributePrimaryValue filter attribute]
    [#return (getFilterAttribute(filter,attribute)[0])!"" ]
[/#function]

[#-- Check for a match between a Current Filter and a Match Filter --]
[#function filterMatch currentFilter matchFilter matchBehaviour]

    [#switch matchBehaviour]
        [#case ANY_FILTER_MATCH_BEHAVIOUR]
            [#if !(matchFilter.Any??)]
                [#return true]
            [/#if]
            [#list currentFilter as key, value]
                [#if getArrayIntersection(value, matchFilter.Any)?has_content]
                    [#return true]
                [/#if]
            [/#list]
            [#break]

        [#case ONETOONE_FILTER_MATCH_BEHAVIOUR]
        [#case EXACTLY_ONETOONE_FILTER_MATCH_BEHAVIOUR]
            [#list matchFilter as key,value]
                [#if !(currentFilter[key]?has_content)]
                    [#return false]
                [/#if]
                [#if !getArrayIntersection(currentFilter[key],value)?has_content]
                    [#return false]
                [/#if]
            [/#list]
            [#-- Filters must have the same attributes --]
            [#if
                (matchBehaviour == EXACTLY_ONETOONE_FILTER_MATCH_BEHAVIOUR) &&
                removeObjectAttributes(currentFilter, matchFilter?keys)?has_content]
                [#return false]
            [/#if]
            [#return true]
            [#break]

            [#-- Unknown behaviour --]
            [#default]
            [#return false]
    [/#switch]

    [#-- Filters don't match --]
    [#return false]
[/#function]

[#---------------------
-- Qualifier support --
-----------------------]

[#--
Qualifiers allow the effective value of an entity to vary based on the value
of a Context Filter.

Each qualifier consists of a Filter, a MatchBehaviour, a Value and a
CombineBehaviour.

Filter - {"Environment" : "prod"}
MatchBehaviour - ONETOONE_FILTER_MATCH_BEHAVIOUR
Value - 50
CombineBehaviour - MERGE_COMBINE_BEHAVIOUR

The Filter acts as a Match Filter for comparison purposes with the provided
Context Filter.

Where the filters match, the qualifier Value is combined with the nominal
value of the entity based on the CombineBehaviour as defined by the
combineEntities() base function.

More than one qualifier may match, in which case the qualifiers are applied to
the nominal value in the order in which the qualifiers are defined.

One or more qualifiers can be added to any entity via a reserved "Qualifiers"
attribute. Where the entity to be qualified is not itself an object, the
desired entity must be wrapped in an object in order that the "Qualifiers" attribute
can be attached. Note thet the  type of the result will be that of the provided
value.

There is a long form and a short form value for Qualifiers.

In the long form, the "Qualifiers" attribute value is a list of qualifier objects.

Each qualifier object must have a "Filter" attribute and a "Value" attribute, as well
as optional "MatchBehaviour" and "DefaultBehaviour" attributes. By default, the
MatchBehaviour is ONETOONE_FILTER_MATCH_BEHAVIOUR and the Combine Behaviour is
MERGE_COMBINE_BEHAVIOUR.

The long form gives full control over the qualification process and the order
in which qualifiers are applied. In the following example, the nominal value is 100,
but 50 will be used assuming the Environment is prod;

{
    "Value" : 100,
    "Qualifiers : [
        {
            "Filter" : {"Environment" : "prod"},
            "MatchBehaviour" : ONETOONE_FILTER_MATCH_BEHAVIOUR,
            "Value" : 50,
            "CombineBehaviour" : MERGE_COMBINE_BEHAVIOUR
        }
    ]
}

In the short form, the "Qualifiers" attribute value is an object.

Each attribute of the attribute value represents a qualifier. The attribute key
is the value of  the "Any" attribute of the Match Filter, the MatchBehaviour is
ANY_FILTER_MATCH_BEHAVIOUR, and the CombineBehaviour is MERGE_COMBINE_BEHAVIOUR.
The attribute value is the value of the attribute.

Because object attribute processing is not ordered, the short form does not provide fine
control in the situation where multiple qualifiers match - effectively they need
to be independent. For consistency, attributes are sorted alphabetically before processing.

The short form is useful for simple situations such as setting variation based
on environment. Assuming environment values are unique, the long form example
could be simplified to

{
  "Value" : 100,
  "Qualifiers" : { "prod" : 50}
}

Equally

{
  "Value" : 100,
  "Qualifiers" : { "prod" : 50, "industry" : 23}
}

is the equivalent of

{
    "Value" : 100,
    "Qualifiers : [
        {
            "Filter" : {"Any" : "prod"},
            "MatchBehaviour" : ANY_FILTER_MATCH_BEHAVIOUR,
            "Value" : 50,
            "CombineBehaviour" : MERGE_COMBINE_BEHAVIOUR
        },
        {
            "Filter" : {"Any" : "industry"},
            "MatchBehaviour" : ANY_FILTER_MATCH_BEHAVIOUR,
            "Value" : 23,
            "CombineBehaviour" : MERGE_COMBINE_BEHAVIOUR
        }
    ]
}

and if both prod and industry matched, the effective value would be 23.

Qualifiers can be nested, so processing is recursive.
--]

[#function qualifyEntity entity filter]

    [#-- Qualify each element of the array --]
    [#if entity?is_sequence ]
        [#local result = [] ]
        [#list entity as element]
            [#local result += [qualifyEntity(element, filter)] ]
        [/#list]
        [#return result]
    [/#if]

    [#-- Only qualifiable entity is an object --]
    [#if !entity?is_hash ]
        [#return entity]
    [/#if]


    [#if entity.Qualifiers??]
        [#local qualifiers = entity.Qualifiers]

        [#-- Determine the nominal value --]
        [#if entity.Value??]
            [#local result = entity.Value]
        [#else]
            [#local result = removeObjectAttributes(entity, "Qualifiers")]
        [/#if]

        [#-- Qualify the nominal value --]
        [#local result = qualifyEntity(result, filter) ]

        [#if qualifiers?is_hash ]
            [#local anyFilters = qualifiers?keys?sort]
            [#list anyFilters as anyFilter]
                [#if filterMatch(filter, {"Any" : anyFilter}, ANY_FILTER_MATCH_BEHAVIOUR)]
                    [#local result = combineEntities(result, qualifyEntity(qualifiers[anyFilter], filter), MERGE_COMBINE_BEHAVIOUR) ]
                [/#if]
            [/#list]
        [/#if]

        [#if qualifiers?is_sequence]
            [#list qualifiers as qualifier]
                [#if qualifier.Filter?? && isValidFilter(qualifier.Filter) && qualifier.Value?? ]
                    [#if filterMatch(filter, qualifier.Filter, qualifier.MatchBehaviour!ONETOONE_FILTER_MATCH_BEHAVIOUR) ]
                        [#local result = combineEntities(result, qualifyEntity(qualifier.Value, filter), qualifier.CombineBehaviour!MERGE_COMBINE_BEHAVIOUR) ]
                    [/#if]
                [/#if]
            [/#list]
        [/#if]

    [#else]
        [#-- Qualify attributes --]
        [#local result = {} ]
        [#list entity as key, value]
            [#local result += { key, qualifyEntity(value, filter) } ]
        [/#list]
    [/#if]

    [#return result]
[/#function]
