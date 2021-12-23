[#ftl]
[#-------------------------------------
-- Internal error handling functions --
---------------------------------------]

[#--
This relies on the Freemarker behaviour where if a null value is
provided for parameter, it will receive whatever has been
configured as the default.

For any argument where a value is expected, set the default to
"Hamlet:Null".
--]


[#-- Detect null values --]
[#function hasNullContent entity="Hamlet:Null"]

    [#-- Passed a null --]
    [#if entity?is_string && (entity == "Hamlet:Null") ]
        [#return true]
    [/#if]

    [#if entity?is_hash]
        [#list entity as key, value]
            [#if hasNullContent(value) ]
                [#return true]
            [/#if]
        [/#list]
    [/#if]

    [#if entity?is_sequence]
        [#list entity as element]
            [#if hasNullContent(element) ]
                [#return true]
            [/#if]
        [/#list]
    [/#if]

    [#return false]
[/#function]

[#-- Remove null values --]
[#function makeEntityNullSafe entity="Hamlet:Null"]

    [#if entity?is_hash]
        [#local result = {} ]
        [#list entity as key, value]
            [#local result += { key : makeEntityNullSafe(value) } ]
        [/#list]
        [#return result]
    [/#if]

    [#if entity?is_sequence]
        [#local result = [] ]
        [#list entity as element]
            [#local result += [ makeEntityNullSafe(element) ] ]
        [/#list]
        [#return result]
    [/#if]

    [#-- If a null is passed, "Hamlet:Null" will be returned --]
    [#-- as the default argument value logic will kick in    --]
    [#return entity]
[/#function]

[#-- Helper routines to simplify reporting of bad arguments --]
[#function isNullDetectionEnabled]
    [#-- TODO(mfl): Add a cli flag to control null detection --]
    [#-- It is very cpu intensive                            --]
    [#return false]
[/#function]

[#function findNullArguments fn args caller]
    [#local result = {} ]

    [#list args as key, value]
        [#if hasNullContent(value) ]
            [#local result += { key : makeEntityNullSafe(value) } ]
        [/#if]
    [/#list]

    [#if result?has_content ]
        [@fatalstop
            message='Internal error - invalid argument(s) to ${fn}()'
            context={ "Caller" : caller } + result
        /]
    [/#if]

    [#-- Only get here if no problems --]
    [#return {}]
[/#function]

[#-------------------
-- Logic functions --
---------------------]

[#function valueIfTrue value="Hamlet:Null" condition="Hamlet:Null" otherwise={} ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "valueIfTrue",
                {
                    "value" : value,
                    "condition" : condition,
                    "otherwise" : otherwise
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return condition?then(value, otherwise) ]
[/#function]

[#function valueIfContent value="Hamlet:Null" content="Hamlet:Null" otherwise={} ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "valueIfContent",
                {
                    "value" : value,
                    "content" : content,
                    "otherwise" : otherwise
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return valueIfTrue(value, content?has_content, otherwise) ]
[/#function]

[#function arrayIfTrue value="Hamlet:Null" condition="Hamlet:Null" otherwise=[] ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "arrayIfTrue",
                {
                    "value" : value,
                    "condition" : condition,
                    "otherwise" : otherwise
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return condition?then(asArray(value), otherwise) ]
[/#function]

[#function arrayIfContent value="Hamlet:Null" content="Hamlet:Null" otherwise=[] ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "arrayIfContent",
                {
                    "value" : value,
                    "content" : content,
                    "otherwise" : otherwise
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return valueIfContent(asArray(value), content, otherwise) ]
[/#function]

[#function contentIfContent value="Hamlet:Null" otherwise={} ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "contentIfContent",
                {
                    "value" : value,
                    "otherwise" : otherwise
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return valueIfTrue(value, value?has_content, otherwise) ]
[/#function]

[#function attributeIfTrue attribute="Hamlet:Null" condition="Hamlet:Null" value="Hamlet:Null" ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "attributeIfTrue",
                {
                    "attribute" : attribute,
                    "condition" : condition,
                    "value" : value
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return valueIfTrue({attribute : value}, condition) ]
[/#function]

[#function attributeIfContent attribute="Hamlet:Null" content="Hamlet:Null" value={} ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "attributeIfContent",
                {
                    "attribute" : attribute,
                    "content" : content,
                    "value" : value
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return attributeIfTrue(
        attribute,
        content?has_content,
        value?has_content?then(value, content)) ]
[/#function]

[#function numberAttributeIfContent attribute="Hamlet:Null" content="Hamlet:Null" value={}]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "numberAttributeIfContent",
                {
                    "attribute" : attribute,
                    "content" : content,
                    "value" : value
                },
                .caller_template_name
            )
        ]
    [/#if]

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
[#function concatenate args="Hamlet:Null" separator="Hamlet:Null" callToSelf=false]

    [#if ! callToSelf]
        [#-- Internal error detection --]
        [#if isNullDetectionEnabled() ]
            [#local nullArguments =
                findNullArguments(
                    "concatenate",
                    {
                        "args" : args,
                        "separator" : separator
                    },
                    .caller_template_name
                )
            ]
        [/#if]
    [/#if]

    [#local content = []]
    [#list asFlattenedArray(args) as arg]
        [#local argValue = arg]
        [#if argValue?is_hash]
            [#switch separator]
                [#case "X"]
                    [#if (argValue.Core.Internal.IdExtensions)??]
                        [#local argValue = concatenate(
                                            argValue.Core.Internal.IdExtensions,
                                            separator,
                                            true)]
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
                                            separator,
                                            true)]
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

[#function asArray arg="Hamlet:Null" flatten=false ignoreEmpty=false callToSelf=false]

    [#if !callToSelf]
        [#-- Internal error detection --]
        [#if isNullDetectionEnabled() ]
            [#local nullArguments =
                findNullArguments(
                    "asArray",
                    {
                        "arg" : arg,
                        "flatten" : flatten,
                        "ignoreEmpty" : ignoreEmpty
                    },
                    .caller_template_name
                )
            ]
        [/#if]
    [/#if]

    [#local result = [] ]
    [#if arg?is_sequence]
        [#if flatten]
            [#list arg as element]
                [#local result += asArray(element, flatten, ignoreEmpty, true) ]
            [/#list]
        [#else]
            [#if ignoreEmpty]
                [#list arg as element]
                   [#local elementResult = asArray(element, flatten, ignoreEmpty, true) ]
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

[#function asFlattenedArray arg="Hamlet:Null" ignoreEmpty=false]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "asFlattenedArray",
                {
                    "arg" : arg,
                    "ignoreEmpty" : ignoreEmpty
                },
                .caller_template_name
            )
        ]
    [/#if]

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

[#function getArrayIntersection array1="Hamlet:Null" array2="Hamlet:Null" regexSupport=false]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "getArrayIntersection",
                {
                    "array1" : array1,
                    "array2" : array2,
                    "regexSupport" : regexSupport
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#local result = []]
    [#local array2AsArray = asArray(array2)]
    [#list asArray(array1) as element]
        [#if regexSupport]
            [#list array2AsArray as regex]
                [#if element?matches(regex) ]
                    [#local result += [element]]
                [/#if]
            [/#list]
        [#else]
            [#if array2AsArray?seq_contains(element)]
                [#local result += [element]]
            [/#if]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#function firstContent alternatives="Hamlet:Null" otherwise={}]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "firstContent",
                {
                    "alternatives" : alternatives,
                    "otherwise" : otherwise
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#list asArray(alternatives) as alternative]
        [#if alternative?has_content]
            [#return alternative]
        [/#if]
    [/#list]
    [#return otherwise ]
[/#function]

[#function removeValueFromArray array="Hamlet:Null" string="Hamlet:Null" ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "removeValueFromArray",
                {
                    "array" : array,
                    "string" : string
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#local result = [] ]
    [#list array as item ]
        [#if item != string ]
            [#local result += [ item ] ]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#function splitArray array="Hamlet:Null" index="Hamlet:Null"]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "splitArray",
                {
                    "array" : array,
                    "index" : index
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#if array?has_content && (index < array?size)]
        [#return array[index..]]
    [/#if]
    [#return [] ]
[/#function]

[#-------------------
-- Object handling --
---------------------]

[#-- Output object as JSON --]
[#function getJSON obj escaped=false pretty=false indent=2 depth=0 ]
    [#local result = ""]
    [#if obj?is_hash]
        [#local result += "{" + pretty?then("\n", "")]
        [#local depth = depth + indent ]
        [#list obj as key,value]
            [#local result += pretty?then(""?left_pad(depth, " "), "") + "\"" + key + "\": " + getJSON(value, escaped, pretty, indent, depth )]
            [#sep][#local result += "," + pretty?then("\n", "") ][/#sep]
        [/#list]
        [#local result += pretty?then("\n", "") + pretty?then(""?left_pad(depth - indent, " "), "") + "}"]
    [#else]
        [#if obj?is_sequence]
            [#local result += "[" + obj?has_content?then(pretty?then("\n", ""), "") ]
            [#list obj as entry]
                [#local result += pretty?then(""?left_pad((depth + indent), " "), "") + getJSON(entry, escaped, pretty, indent, ( depth + indent) )]
                [#sep][#local result += "," + pretty?then("\n", "")][/#sep]
            [/#list]
            [#local result += obj?has_content?then(pretty?then("\n", ""), "") + obj?has_content?then(pretty?then(""?left_pad(depth, " "), ""),"") + "]"]
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

[#function filterObjectAttributes obj="Hamlet:Null" attributes="Hamlet:Null" removeAttributes=false]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "splitArray",
                {
                    "obj" : obj,
                    "attributes" : attributes,
                    "removeAttributes" : removeAttributes
                },
                .caller_template_name
            )
        ]
    [/#if]

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

[#function getObjectAttributes obj attributes ]
    [#-- Rely on filterObjectAttributes for internal error detection --]
    [#return filterObjectAttributes(obj, attributes, false)]
[/#function]

[#function removeObjectAttributes obj attributes]
    [#-- Rely on filterObjectAttributes for internal error detection --]
    [#return filterObjectAttributes(obj, attributes, true)]
[/#function]

[#function findAttributeInObject obj="Hamlet:Null" keyPath="Hamlet:Null" callToSelf=false]

    [#if ! callToSelf]
        [#-- Internal error detection --]
        [#if isNullDetectionEnabled() ]
            [#local nullArguments =
                findNullArguments(
                    "findAttributeInObject",
                    {
                        "obj" : obj,
                        "keyPath" : keyPath
                    },
                    .caller_template_name
                )
            ]
        [/#if]
    [/#if]

    [#list keyPath as key ]
        [#if obj[key]?? ]
            [#if key?is_last ]
                [#return obj[key]]
            [#else]
                [#return
                    findAttributeInObject(
                        obj[key],
                        keyPath[ (key?index +1) ..],
                        true
                    ) ]
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

[#function combineEntities left="Hamlet:Null" right="Hamlet:Null" behaviour=MERGE_COMBINE_BEHAVIOUR callToSelf=false]

    [#if ! callToSelf]
        [#-- Internal error detection --]
        [#if isNullDetectionEnabled() ]
            [#local nullArguments =
                findNullArguments(
                    "combineEntities",
                    {
                        "left" : left,
                        "right" : right,
                        "behaviour" : behaviour
                    },
                    .caller_template_name
                )
            ]
        [/#if]
    [/#if]

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
                            [#local newValue = combineEntities(left[key], value, behaviour, true) ]
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

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "mergeObjects",
                {
                    "objects" : objects
                },
                .caller_template_name
            )
        ]
    [/#if]

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

[#function isOneOfTypes arg="Hamlet:Null" types="Hamlet:Null"]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "isOneOfTypes",
                {
                    "arg" : arg,
                    "types" : types
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#local typesArray = asArray(types) ]
    [#return
        typesArray?seq_contains(getBaseType(arg)) ||
        typesArray?seq_contains(ANY_TYPE) ]
[/#function]

[#function isArrayOfType types="Hamlet:Null"]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "isArrayOfType",
                {
                    "types" : types
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#local typesArray = asArray(types) ]
    [#return (typesArray?size > 1) && typesArray?seq_contains(ARRAY_TYPE) ]
[/#function]

[#function asType arg="Hamlet:Null" types="Hamlet:Null" ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "asType",
                {
                    "arg" : arg,
                    "types" : types
                },
                .caller_template_name
            )
        ]
    [/#if]

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

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "getFirstDefinedDirective",
                {
                    "directives" : directives
                },
                .caller_template_name
            )
        ]
    [/#if]

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

[#function addDateTime dateTime unit amount]
    [#switch unit]
        [#case "dd"]
            [#local offset=1000*60*60*24]
            [#break]
        [#case "hh"]
            [#local offset=1000*60*60]
            [#break]
        [#case "mm"]
            [#local offset=1000*60]
            [#break]
    [/#switch]
    [#local retval = (dateTime?datetime?long + amount?long*offset?long)?number_to_datetime]
    [#return retval ]
[/#function]

[#function showDateTime dateTime format timezone="UTC" ]
    [#local old_time_zone = .time_zone]
    [#setting time_zone = timezone]
    [#local retval = dateTime?datetime?string(format)]

    [#setting time_zone = old_time_zone]
    [#return retval ]
[/#function]

[#function convertDayOfWeek2DateTime dayOfWeek timeofDay="00:00" timeZone="UTC"]
    [#--
    The explicit dates below are used to convert a "dayOfWeek" to a date to allow for date and
    TimeZone manipulations.
    Any date sufficiently far away from leap year impacts can be used
    --]
    [#switch dayOfWeek]
        [#case "Monday"]
            [#local startTime = "05-JUL-2021 "+timeofDay+":00 "+timeZone ]
            [#break]
        [#case "Tuesday"]
            [#local startTime = "06-JUL-2021 "+timeofDay+":00 "+timeZone ]
            [#break]
        [#case "Wednesday"]
            [#local startTime = "07-JUL-2021 "+timeofDay+":00 "+timeZone ]
            [#break]
        [#case "Thursday"]
            [#local startTime = "08-JUL-2021 "+timeofDay+":00 "+timeZone ]
            [#break]
        [#case "Friday"]
            [#local startTime = "09-JUL-2021 "+timeofDay+":00 "+timeZone ]
            [#break]
        [#case "Saturday"]
            [#local startTime = "10-JUL-2021 "+timeofDay+":00 "+timeZone ]
            [#break]
        [#case "Sunday"]
            [#local startTime = "11-JUL-2021 "+timeofDay+":00 "+timeZone ]
            [#break]
    [/#switch]
    [#local retval = startTime?datetime("dd-MMM-yyyy HH:mm:ss z") ]
    [#return retval ]
[/#function]

[#function testMaintenanceWindow maintWindow requireDay=true requireTime=true requireTZ=true]
    [#return !(maintWindow.Configured!false) ||
        (!requireDay || maintWindow.DayOfTheWeek?has_content) &&
        (!requireTime || maintWindow.TimeOfDay?has_content) &&
        (!requireTZ || maintWindow.TimeZone?has_content)
    ]
[/#function]

[#function getCompositeObject attributes=[] objects...]
    [#return getCompositeObjectResult("object+logs", attributes, objects) ]
[/#function]

[#-- Formulate a composite object based on                                            --]
[#--   * order precedence - lowest to highest, then                                   --]
[#--   * qualifiers - less specific to more specific                                  --]
[#-- If no attributes are provided, simply combine the qualified objects              --]
[#-- It is also possible to define an attribute with a name of "*" which will trigger --]
[#-- the combining of the objects in addition to any attributes already created       --]
[#function getCompositeObjectResult mode="object+logs" attributes=[] objects...]

    [#-- Gather messages locally --]
    [#local messages = [] ]

    [#-- Ignore any candidate that is not a hash --]
    [#local candidates = [] ]
    [#list asFlattenedArray(objects) as element]
        [#if element?is_hash]
            [#local candidates += [element] ]
        [/#if]
    [/#list]

    [#local expandedAttributes = expandCompositeConfiguration(attributes)]
    [#local normalisedAttributes = normaliseCompositeConfiguration(expandedAttributes)]

    [#-- Determine the values for explicitly listed attributes --]
    [#local result = {} ]
    [#local explicitAttributes = [] ]
    [#local attributeWildcardSeen = false ]

    [#if normalisedAttributes?has_content]
        [#list normalisedAttributes as attribute]

            [#-- Ignore any inhibit enabled marker --]
            [#if ! attribute?is_hash]
                [#continue]
            [/#if]

            [#local populateMissingChildren = attribute.PopulateMissingChildren ]

            [#-- TODO(mfl) Should all name alternatives be processed? Doing so would represent a change in behaviour --]
            [#-- Look for the first name alternative --]
            [#local providedName = ""]
            [#local providedValue = ""]
            [#local providedCandidate = {}]
            [#list attribute.Names as attributeName]
                [#if attributeName == "*"]
                    [#local providedName = "*"]
                [/#if]
                [#-- Previous name already seen --]
                [#if providedName?has_content]
                    [#break]
                [#else]
                    [#list candidates?reverse as object]
                        [#if object[attributeName]??]
                            [#-- Found a match - look for this name on all candidates --]
                            [#local providedName = attributeName ]
                            [#local providedValue = object[attributeName] ]
                            [#local providedCandidate = object ]

                            [#-- Remember which attributes have been explicitly listed --]
                            [#local explicitAttributes += [attributeName] ]
                            [#break]
                        [/#if]
                    [/#list]
                [/#if]
            [/#list]


            [#-- Attribute wildcard seen - include any attributes not explicitly defined --]
            [#if providedName == "*"]
                [#local attributeWildcardSeen = true ]
                [#continue]
            [/#if]

            [#-- Throw an exception if a mandatory attribute is missing      --]
            [#-- If no candidates, assume we are entirely populating missing --]
            [#-- children so ignore mandatory check                          --]
            [#if attribute.Mandatory &&
                    ( !(providedName?has_content) ) &&
                    candidates?has_content &&
                    ( ! attribute.DefaultProvided )]
                [#local messages +=
                    [
                        {
                            "Severity" : "fatal",
                            "Message" : "Mandatory attribute missing",
                            "Context" : {
                                "ExpectedNames" : attribute.Names,
                                "CandidateObjects" : objects
                            }
                        }
                    ]
                ]

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
                                [#local messages +=
                                    [
                                        {
                                            "Severity" : "fatal",
                                            "Message" : "One or more children not of an accepted type",
                                            "Context" : childArray
                                        }
                                    ]
                                ]
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
                                            [#local messages +=
                                                [
                                                    {
                                                        "Severity" : "fatal",
                                                        "Message" : "Subobject content is not a hash",
                                                        "Context" : {
                                                            "InvalidValue" : value,
                                                            "Object" : childObject,
                                                            "Attribute" : attribute
                                                        }
                                                    }
                                                ]
                                            ]
                                        [/#if]
                                    [/#list]
                                [#else]
                                    [#local messages +=
                                        [
                                            {
                                                "Severity" : "fatal",
                                                "Message" : "Child content is not a hash",
                                                "Context" : childObject
                                            }
                                        ]
                                    ]
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
                        [#local messages +=
                            [
                                {
                                    "Severity" : "fatal",
                                    "Message" : "Attribute is not of the correct type",
                                    "Context" : {
                                        "Name" : providedName,
                                        "Value" : providedValue,
                                        "ExpectedTypes" : attribute.Types,
                                        "Candidate" : providedCandidate
                                    }
                                }
                            ]
                        ]
                    [#else]
                        [#if attribute.Values?has_content]
                            [#list asArray(providedValue) as value]
                                [#if !(attribute.Values?seq_contains(value)) ]
                                    [#local messages +=
                                        [
                                            {
                                                "Severity" : "fatal",
                                                "Message" : "Attribute value is not one of the expected values",
                                                "Context" : {
                                                    "Name" : providedName,
                                                    "Value" : value,
                                                    "ExpectedValues" : attribute.Values,
                                                    "Candidate" : providedCandidate
                                                }
                                            }
                                        ]
                                    ]
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
        [#if !attributeWildcardSeen]
            [#if mode?contains("messages") ]
                [#return messages]
            [/#if]
            [#if mode?contains("logs") ]
                [#list messages as message]
                    [#switch message.Severity]
                        [#case "fatal"]
                        [#default]
                            [@fatal
                                message=message.Message
                                context=message.Context!{}
                                detail=message.Detail!{}
                            /]
                            [#break]
                    [/#switch]
                [/#list]
            [/#if]
            [#return result ]
        [/#if]
    [/#if]

    [#-- Either no attribute configuration has been provided or a name wildcard was encountered --]
    [#list candidates as object]
        [#-- Previously object addition was used to generate the result but this was changed  --]
        [#-- to a merge to permit multiple candidates to contribute to the value of top level --]
        [#-- attribute that have object values                                                --]
        [#local result = mergeObjects(result, removeObjectAttributes(object, explicitAttributes)) ]
    [/#list]

    [#if mode?contains("messages") ]
        [#return messages]
    [/#if]
    [#if mode?contains("logs") ]
        [#list messages as message]
            [#switch message.Severity]
                [#case "fatal"]
                [#default]
                    [@fatal
                        message=message.Message
                        context=message.Context!{}
                        detail=message.Detail!{}
                    /]
                    [#break]
            [/#switch]
        [/#list]
    [/#if]
    [#return result ]

[/#function]

[#function compressCompositeConfiguration attributes ]
    [#-- Collapes the array of composites to reduce duplicates when processing --]

    [#local result = []]
    [#list attributes as attribute ]
        [#if attribute?is_hash]
            [#list asArray(attribute.Names) as name]

                [#if result?has_content ]

                    [#if result?is_sequence && asFlattenedArray(result?map(x -> x.Names ))?seq_contains(name)]
                        [#local mergedAttribute = result?filter(x -> asArray(x.Names)?seq_contains(name) )?first ]

                        [#local mergedAttribute = mergeObjects(mergedAttribute, attribute)]
                        [#local mergedAttribute += {
                            "Names" : combineEntities(mergedAttribute.Names, attribute.Names, UNIQUE_COMBINE_BEHAVIOUR),
                            "Values" : combineEntities(mergedAttribute.Values, attribute.Values, UNIQUE_COMBINE_BEHAVIOUR),
                            "Types" : combineEntities(mergedAttribute.Types, attribute.Types, UNIQUE_COMBINE_BEHAVIOUR)
                        } +
                        attributeIfContent(
                            "Children",
                            attribute.Children,
                            asFlattenedArray(compressCompositeConfiguration((attribute.Children)![]))
                        )]
                        [#local result = combineEntities(result?filter(x -> ! asArray(x.Names)?seq_contains(name)), [ mergedAttribute], APPEND_COMBINE_BEHAVIOUR) ]
                    [#else]
                        [#local result = combineEntities(result, [ attribute ], APPEND_COMBINE_BEHAVIOUR)]
                    [/#if]
                [#else]
                    [#local result = combineEntities(result, [ attribute ], APPEND_COMBINE_BEHAVIOUR)]
                [/#if]
            [/#list]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#function expandCompositeConfiguration attributes ]

    [#-- If attribute value is defined as an AttributeSet, evaluate --]
    [#-- it and use the result as the attribute's Children.         --]
    [#local evaluatedRefAttributes = []]
    [#if attributes?has_content]
        [#list asFlattenedArray(attributes) as attribute]
            [#if attribute?is_hash ]
                [#if attribute.AttributeSet?has_content && !(attribute.Children?has_content)]
                    [#-- AttributeSet provides the child attributes --]
                    [#local children = (getAttributeSet(attribute.AttributeSet).Attributes)![] ]

                    [#if !children?has_content ]
                        [@fatal
                            message="Unable to determine child attributes from AttributeSet"
                            context=attribute
                        /]
                        [#-- Add a minimal child configuration to ensure processing completes --]
                        [#local children = [{"Names" : "AttributeSet", "Types" : STRING_TYPE}] ]
                    [/#if]

                    [#local evaluatedRefAttributes += [ attribute + { "Children" : expandCompositeConfiguration(children) } ] ]
                [#else]
                    [#-- Attribute has no reference to evaluate, so add to results --]
                    [#local evaluatedRefAttributes += [attribute]]
                [/#if]
            [#else]
                [#local evaluatedRefAttributes += [attribute]]
            [/#if]
        [/#list]
    [/#if]
    [#return evaluatedRefAttributes ]
[/#function]

[#function normaliseCompositeConfiguration attributes ]
    [#-- Normalise attributes --]
    [#local normalisedAttributes = [] ]
    [#local inhibitEnabled = false]
    [#local explicitEnabled = false]
    [#if attributes?has_content]
        [#list asFlattenedArray(attributes) as attribute]
            [#local names = [] ]
            [#if attribute?is_string]
                [#if attribute == "InhibitEnabled" ]
                    [#local inhibitEnabled = true ]
                    [#continue]
                [/#if]

                [#-- Defaults if only the attribute name is provided --]
                [#local normalisedAttribute =
                    {
                        "Names" : [attribute],
                        "Types" : [ANY_TYPE],
                        "Mandatory" : false,
                        "DefaultBehaviour" : "ignore",
                        "DefaultProvided" : false,
                        "Values" : [],
                        "Children" : [],
                        "SubObjects" : false,
                        "PopulateMissingChildren" : true,
                        "AttributeSet" : "",
                        "Component" : "",
                        "Description" : ""
                    }
                ]
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
                        "Values" : asArray(attribute.Values![]),
                        "Children" : normaliseCompositeConfiguration(
                            asArray(attribute.Children![])
                        ),
                        "SubObjects" : attribute.SubObjects!attribute.Subobjects!false,
                        "PopulateMissingChildren" : attribute.PopulateMissingChildren!true,
                        "AttributeSet" : attribute.AttributeSet!"",
                        "Component" : attribute.Component!"",
                        "Description" : attribute.Description!""
                    } +
                    attributeIfTrue(
                        "Default",
                        attribute.Default??,
                        attribute.Default!""
                    )
                ]
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
                        "Component" : "",
                        "Description" : ""
                    }
                ] +
                normalisedAttributes ]
        [/#if]
    [/#if]

    [#return normalisedAttributes + arrayIfTrue("InhibitEnabled", inhibitEnabled) ]
[/#function]

[#macro validateCompositeObject attributes=[] objects=[] ]

    [#-- Common Parameters that are used throughout        --]
    [#-- but are as-yet unaccounted for in the             --]
    [#-- composite object definitions.                     --]
    [#-- TODO(rossmurr4y): add commonParams to definitions --]
    [#local commonParams = [
        "multiAZ", "MultiAZ"]
    ]

    [#local attributes = normaliseCompositeConfiguration(attributes)]

    [#local validKeys = asFlattenedArray(attributes?map(c -> (c?is_hash && c.Names??)?then(c.Names, c)))]
    [#list asFlattenedArray(objects) as object]
        [#list object?keys as key]
            [#if !(validKeys?seq_contains("*")) &&
                    !(validKeys?seq_contains(key)) &&
                    !(commonParams?seq_contains(key))]

                [@fatal
                    message="Invalid Attribute Found."
                    context=
                        {
                            "InvalidAttribute" : key,
                            "ValidAttributes" : validKeys,
                            "InvalidObject" : object
                        }
                /]
            [/#if]
        [/#list]
    [/#list]
[/#macro]

[#function addPrefixToAttributes attributes prefix prefixNames=true prefixValues=true prefixDefault=false maxDepth=1 disablePrefix="shared:" depth=0  ]

    [#local prefix = prefix?ensure_ends_with(":")]

    [#if depth gte maxDepth ]
        [#local prefixNames = false ]
        [#local prefixValues = false ]
        [#local prefixDefault = false ]
    [/#if]

    [#local result = []]
    [#list attributes as attribute ]
        [#local prefixedNames = [] ]
        [#local prefixedValues = [] ]
        [#local prefixedDefault = "" ]

        [#if ((attribute.Names)![])?has_content ]
            [#local prefixedNames = asArray(attribute.Names)?map(
                                        x -> x?is_string?then(
                                            x?starts_with(disablePrefix)?then(
                                                x?remove_beginning(disablePrefix),
                                                prefixNames?then( x?ensure_starts_with(prefix), x)
                                            ),
                                            x)
                                        )]
        [/#if]

        [#if ((attribute.Values)![])?has_content ]
            [#local prefixedValues = asArray(attribute.Values)?map(
                                        x -> x?is_string?then(
                                                            x?starts_with(disablePrefix)?then(
                                                                x?remove_beginning(disablePrefix),
                                                                prefixValues?then( x?ensure_starts_with(prefix), x)
                                                            ),
                                                            x
                                                        )
                                        )]
        [/#if]

        [#if ((attribute.Default)!"")?has_content ]
            [#if (attribute.Default)?is_string ]
                [#local prefixedDefault = prefixDefault?then(
                                            attribute.Default?ensure_starts_with(prefix),
                                            attribute.Default
                                        )]
            [#else]
                [#local prefixedDefault = attribute.Default ]
            [/#if]
        [/#if]

        [#if ((attribute.Children)![])?has_content ]
            [#local prefixedChildren = addPrefixToAttributes(
                                            attribute.Children,
                                            prefix,
                                            prefixNames,
                                            prefixValues,
                                            prefixDefault,
                                            maxDepth,
                                            disablePrefix,
                                            (depth + 1)
                                        )]

            [#local result +=  [
                attribute +
                {
                    "Children" : prefixedChildren,
                    "Names" : prefixedNames
                }
            ]]
        [#else]
            [#local result +=
                [
                    attribute +
                    {
                        "Names" : prefixedNames,
                        "Values" : prefixedValues,
                        "Default" : prefixedDefault
                    }
                ]
            ]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#-- Wraps the getCompositeObject function, adding     --]
[#-- the FrameworkObjectAttributes to valid Attributes --]
[#-- where applicable.                                 --]
[#function getBluePrintObject attributes=[] objects...]
    [#local result = addFrameworkAttributes(attributes) ]
    [#return getCompositeObject(result, objects)]
[/#function]

[#-- Walks an Attribute / Children structure and    --]
[#-- adds the Framework Attributes as necessary.    --]
[#function addFrameworkAttributes attributes=[]]
    [#local result = []]
    [#list asFlattenedArray(attributes) as attribute]
        [#if attribute?is_hash && attribute.Children??]
            [#local attrChildren = addFrameworkAttributes(attribute.Children)]
            [#local result += [
                mergeObjects(
                    attribute,
                    {
                        "Children" : attrChildren
                    }
                )
            ]]
        [#else]
            [#local result += [attribute]]
        [/#if]
    [/#list]
    [#return combineEntities(frameworkObjectAttributes, result, ADD_COMBINE_BEHAVIOUR)]
[/#function]

[#-- Check if a configuration item with children is present --]
[#function isPresent configuration={} ]
    [#return (configuration.Configured!false) && (configuration.Enabled!false) ]
[/#function]

[#function getObjectLineage collection end ]
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
        [#local parentId =
                (getCompositeObject(
                    [
                        {
                            "Names" : "Parent",
                            "Types" : STRING_TYPE
                        }
                    ],
                    endingObject
                ).Parent)!"" ]
        [#local parentIds =
                (getCompositeObject(
                    [
                        {
                            "Names" : "Parents",
                            "Types" : ARRAY_OF_STRING_TYPE
                        }
                    ],
                    endingObject
                ).Parents)!arrayIfContent(parentId, parentId) ]

        [#if parentIds?has_content]
            [#list parentIds as parentId]
                [#local lines = getObjectLineage(collection, parentId) ]
                [#list lines as line]
                    [#local result += [ line + [endingObject] ] ]
                [/#list]
            [/#list]
        [#else]
            [#local result += [ [endingObject] ] ]
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

[#function addDictionaryEntry dictionary="Hamlet:Null" key="Hamlet:Null" entry={} ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "addDictionaryEntry",
                {
                    "dictionary" : dictionary,
                    "key" : key,
                    "entry" : entry
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return addToCacheSection(dictionary, asArray(key) + ["Content"], entry) ]
[/#function]

[#function removeDictionaryEntry dictionary="Hamlet:Null" key="Hamlet:Null" ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "removeDictionaryEntry",
                {
                    "dictionary" : dictionary,
                    "key" : key
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return clearCacheSection(dictionary, asArray(key) + ["Content"]) ]
[/#function]

[#function getDictionaryEntry dictionary="Hamlet:Null" key="Hamlet:Null" ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "getDictionaryEntry",
                {
                    "dictionary" : dictionary,
                    "key" : key
                },
                .caller_template_name
            )
        ]
    [/#if]

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

[#---------------------
-- Ids, Names, Paths --
-----------------------]

[#--
Ids are intended for consumption by automated processes and so are
kept short (typically around 3 to 5 characters) and limited to
alphanumeric characters. Ids are concatenated using the "X" character
to form unique ids.
--]

[#function formatId ids...]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "formatId",
                {
                    "ids" : ids
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return concatenate(ids, "X")?replace("[-_/]", "X", "r")?replace(",", "")]
[/#function]

[#--
Names are intended for human consumption, such as those that appear in UIs
or directory layouts, and typically are used for sorting. They are thus still
limited to alphanumeric characters but will typically use full words rather
than abbreviations. Names are concatenated with the "-" character" to form
unique names.

Environments occasionally constrain the length of unique names. In this case,
the "short" name can be used, which is formed by using object Ids rather than
names.
--]

[#function formatName names...]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "formatName",
                {
                    "names" : names
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return concatenate(names, "-")]
[/#function]

[#--
Paths are commonly used for storage
--]
[#function formatPath absolute="Hamlet:Null" parts...]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "formatPath",
                {
                    "absolute" : absolute,
                    "parts" : parts
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return
        absolute?then("/","") +
        concatenate(parts, "/")]
[/#function]

[#function formatAbsolutePath parts...]
    [#-- Rely on formatPath for internal error detection --]
    [#return formatPath(true, parts)]
[/#function]

[#function formatRelativePath parts...]
    [#-- Rely on formatPath for internal error detection --]
    [#return formatPath(false, parts)]
[/#function]

[#---------------------
-- Namespace support --
-----------------------]

[#function getMatchingNamespaces namespaces="Hamlet:Null" prefixes="Hamlet:Null" alternatives="Hamlet:Null" endingsToRemove=[] ]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "getMatchingNamespaces",
                {
                    "namespaces" : namespaces,
                    "prefixes" : prefixes,
                    "alternatives" : alternatives,
                    "endingsToRemove" : endingsToRemove
                },
                .caller_template_name
            )
        ]
    [/#if]

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

[#function isFilterAttribute filter attribute]
    [#return filter[attribute]??]
[/#function]

[#function getFilterAttribute filter="Hamlet:Null" attribute="Hamlet:Null"]

    [#-- Internal error detection --]
    [#if isNullDetectionEnabled() ]
        [#local nullArguments =
            findNullArguments(
                "getFilterAttribute",
                {
                    "filter" : filter,
                    "attribute" : attribute
                },
                .caller_template_name
            )
        ]
    [/#if]

    [#return asArray(filter[attribute]![]) ]
[/#function]

[#function getFilterAttributePrimaryValue filter attribute]
    [#return (getFilterAttribute(filter,attribute)[0])!"" ]
[/#function]

[#function getMatchingFilterAttributeValues filter attribute values...]
    [#return
        getArrayIntersection(
            getFilterAttribute(filter, attribute),
            asFlattenedArray(values),
            true
        )
    ]
[/#function]

[#function filterAttributeContainsValue filter attribute values...]
    [#return
        getMatchingFilterAttributeValues(
            filter,
            attribute,
            values
        )?has_content
    ]
[/#function]

[#function getEnrichedFilter filter enrichmentFilter]
    [#local result = {} ]
    [#list filter as id, value]
        [#local result +=
            {
                id :
                    getUniqueArrayElements(
                        value,
                        getFilterAttribute(enrichmentFilter, id)
                    )
            }
        ]
    [/#list]
    [#return result]
[/#function]


[#-- Check for a match between a Current Filter and a Match Filter --]
[#function filterMatch currentFilter matchFilter matchBehaviour]

    [#switch matchBehaviour]
        [#case ANY_FILTER_MATCH_BEHAVIOUR]
            [#if !(matchFilter.Any??)]
                [#return true]
            [/#if]
            [#list currentFilter as key, value]
                [#if getArrayIntersection(value, matchFilter.Any, true)?has_content]
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
                [#if !getArrayIntersection(currentFilter[key],value, true)?has_content]
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
            [@fatal
                message="Unknown filter match behaviour \"" + matchBehaviour + "\" encountered"
                stop=true
            /]
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

Where the filters match, the qualifier Value is combined with the default
value of the entity based on the CombineBehaviour as defined by the
combineEntities() base function.

More than one qualifier may match, in which case the qualifiers are applied to
the default value in the order in which the qualifiers are defined.

One or more qualifiers can be added to any entity via the reserved "Qualifiers"
(legacy) or "qualifier:Rules" attribute.

Where the entity to be qualified is not itself an object, the
desired entity must be wrapped in an object in order that the reserved attribute
can be attached. Note that the  type of the result will be that of the provided
value.

There is a long form and a short form expression for Qualifiers.

In the long form, the "qualifier:Rules" attribute value is a list of qualifier objects,
and the default value can be provided by a "qualifier:Default" attribute.

Each qualifier object must have a "Filter" attribute and a "Value" attribute, as well
as optional "MatchBehaviour" and "DefaultBehaviour" attributes. By default, the
MatchBehaviour is ONETOONE_FILTER_MATCH_BEHAVIOUR and the Combine Behaviour is
MERGE_COMBINE_BEHAVIOUR.

The long form gives full control over the qualification process and the order
in which qualifiers are applied. In the following example, the default value is 100,
but 50 will be used assuming the Environment is prod;

{
    "qualifier:Default" : 100,
    "qualifier:Rules" : [
        {
            "Filter" : {"Environment" : "prod"},
            "MatchBehaviour" : ONETOONE_FILTER_MATCH_BEHAVIOUR,
            "Value" : 50,
            "CombineBehaviour" : MERGE_COMBINE_BEHAVIOUR
        }
    ]
}

In the short form, the "Qualifiers" attribute is used and has a value of an object.
Any default value is provided by a "Value" attribute.

If detected, the long form takes precedence and any "Qualifier" or "Value" attribute
are be treated the same as any other attribute.

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
    "qualifier:Default" : 100,
    "qualifier:Rules : [
        {
            "Filter" : {"Any" : "industry"},
            "MatchBehaviour" : ANY_FILTER_MATCH_BEHAVIOUR,
            "Value" : 23,
            "CombineBehaviour" : MERGE_COMBINE_BEHAVIOUR
        },
        {
            "Filter" : {"Any" : "prod"},
            "MatchBehaviour" : ANY_FILTER_MATCH_BEHAVIOUR,
            "Value" : 50,
            "CombineBehaviour" : MERGE_COMBINE_BEHAVIOUR
        }
    ]
}

and if both prod and industry matched, the effective value would be 50
since "prod" comes after "industry".

Qualifiers can be nested, so processing is recursive.

NOTE: The short form is deprecated in favour of the more precise
expression format provided by the long form.
--]

[#function getQualifierChildren filterAttributes=[] ]
    [#local filterChildren = ["InhibitEnabled"] ]
    [#list filterAttributes as filterAttribute]
        [#local filterChildren +=
            [
                {
                    "Names" : filterAttribute,
                    "Type" : ARRAY_OF_STRING_TYPE
                }
            ]
        ]
    [/#list]
    [#return
        [
            {
                "Names" : "Filter",
                "Mandatory" : true,
                "PopulateMissingChildren" : false,
                "Children" : filterChildren
            },
            {
                "Names" : "MatchBehaviour",
                "Type" : STRING_TYPE,
                "Values" : [
                    ANY_FILTER_MATCH_BEHAVIOUR,
                    ONETOONE_FILTER_MATCH_BEHAVIOUR,
                    EXACTLY_ONETOONE_FILTER_MATCH_BEHAVIOUR
                ],
                "Default" : ONETOONE_FILTER_MATCH_BEHAVIOUR
            },
            {
                "Names" : "Value",
                "Type" : ANY_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "CombineBehaviour",
                "Type" : STRING_TYPE,
                "Values" : [
                    REPLACE_COMBINE_BEHAVIOUR,
                    ADD_COMBINE_BEHAVIOUR,
                    MERGE_COMBINE_BEHAVIOUR,
                    APPEND_COMBINE_BEHAVIOUR,
                    UNIQUE_COMBINE_BEHAVIOUR
                ],
                "Default" : MERGE_COMBINE_BEHAVIOUR
            }
        ]
    ]
[/#function]

[#function qualifyEntity entity filter qualifierChildren=[] mode="strip" ]

    [#-- Qualify each element of the array --]
    [#if entity?is_sequence ]
        [#local result = [] ]
        [#list entity as element]
            [#local result += [qualifyEntity(element, filter, qualifierChildren, mode)] ]
        [/#list]
        [#return result]
    [/#if]

    [#-- Only qualifiable entity is an object --]
    [#if !entity?is_hash ]
        [#return entity]
    [/#if]

    [#-- "Qualifiers" is for legacy support. qualifier:Rules is the preferred attribute --]
    [#local ruleAttributes = ["qualifier:Rules", "Qualifiers"] ]
    [#local defaultAttributes = ["qualifier:Default", "Value"] ]
    [#local qualifiers = {} ]
    [#list ruleAttributes as attribute ]
        [#if entity[attribute]?? ]
            [#local rulesAttribute = attribute ]
            [#local defaultAttribute = defaultAttributes[attribute?index] ]

            [#local qualifiers = entity[rulesAttribute] ]
            [#if entity[ defaultAttribute ]??]
                [#local defaultValue = true]
                [#local result = entity[ defaultAttribute ] ]
            [#else]
                [#local result = removeObjectAttributes(entity, rulesAttribute) ]
            [/#if]
            [#break]
        [/#if]
    [/#list]

    [#if qualifiers?has_content ]

        [#-- Qualify the default value --]
        [#local result = qualifyEntity(result, filter, qualifierChildren, mode) ]

        [#if qualifiers?is_hash ]
            [#local annotatedQualifiers = {} ]
            [#list qualifiers?keys?sort as key]
                [#local match = filterMatch(filter, {"Any" : key}, ANY_FILTER_MATCH_BEHAVIOUR) ]
                [#switch mode]
                    [#case "annotate"]
                        [#local annotatedQualifiers +=
                            {
                                key : {
                                    "qualifier:Result": qualifyEntity(qualifiers[key], filter, qualifierChildren, mode),
                                    "qualifier:Match" : match?c
                                } +
                                qualifiers[key]?is_hash?then(qualifiers[key], { "qualifier:Original" : qualifiers[key] } )
                            }
                        ]
                        [#break]
                    [#default]
                        [#if match]
                            [#local result =
                                combineEntities(
                                    result,
                                    qualifyEntity(qualifiers[key], filter, qualifierChildren, mode),
                                    MERGE_COMBINE_BEHAVIOUR
                                )
                            ]
                        [/#if]
                        [#break]
                [/#switch]
            [/#list]
        [/#if]

        [#if qualifiers?is_sequence]
            [#local annotatedQualifiers = [] ]
            [#if !qualifierChildren?has_content]
                [@fatal
                    message="Can't validate long form qualifier without children definition"
                    context=entity
                    detail=filter
                /]
            [#else]
                [#list qualifiers as qualifierEntry]
                    [#-- Validate the qualifier structure --]
                    [#local qualifier = getCompositeObject(qualifierChildren, qualifierEntry) ]

                    [#if qualifier.Filter?? && qualifier.Value?? ]
                        [#local match = filterMatch(filter, qualifier.Filter, qualifier.MatchBehaviour) ]
                        [#switch mode]
                            [#case "annotate"]
                                [#local annotatedQualifiers +=
                                    [
                                        qualifier +
                                        {
                                            "qualifier:Annotated" : qualifyEntity(qualifier.Value, filter, qualifierChildren, mode),
                                            "qualifier:Match" : match?c
                                        }
                                    ]
                                ]
                                [#break]
                            [#default]
                                [#if match]
                                    [#local result =
                                        combineEntities(
                                            result,
                                            qualifyEntity(qualifier.Value, filter, qualifierChildren, mode),
                                            qualifier.CombineBehaviour
                                        )
                                    ]
                                [/#if]
                                [#break]
                        [/#switch]
                    [#else]
                        [#if mode == "annotate"]
                            [#local annotatedQualifiers +=
                                [
                                    qualifierEntry +
                                    {
                                        "qualifier:Valid" : false
                                    }
                                ]
                            ]
                        [/#if]
                    [/#if]
                [/#list]
            [/#if]
        [/#if]
        [#if annotatedQualifiers?has_content]
            [#local result =
                entity +
                {
                    "qualifier:Result" : result,
                    "qualifier:Annotated" : annotatedQualifiers
                }
            ]
        [/#if]

    [#else]
        [#-- Qualify attributes --]
        [#local result = {} ]
        [#list entity as key, value]
            [#local result += { key, qualifyEntity(value, filter, qualifierChildren, mode ) } ]
        [/#list]
    [/#if]

    [#return result]
[/#function]

[#function getEntityToDepth entity depth=1 ]
    [#if depth > 0]
        [#if entity?is_sequence]
            [#local result = [] ]
            [#list entity as element]
                [#local result += [getEntityToDepth(element, depth - 1)] ]
            [/#list]
            [#return result]
        [/#if]

        [#if entity?is_hash]
            [#local result = {} ]
            [#list entity as key,value]
                [#local result += {key: getEntityToDepth(value, depth - 1)} ]
            [/#list]
            [#return result]
        [/#if]
    [#else]
        [#if entity?is_sequence]
            [#return "..."] ]
        [/#if]

        [#if entity?is_hash]
            [#return "..." ]
        [/#if]
    [/#if]

    [#-- Primitive --]
    [#return entity]
[/#function]
