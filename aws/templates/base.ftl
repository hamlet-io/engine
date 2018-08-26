[#ftl]
[#-------------------
-- Logic functions --
---------------------]

[#function valueIfTrue value condition otherwise={}]
    [#return condition?then(value, otherwise) ]
[/#function]

[#function valueIfContent value content otherwise={}]
    [#return valueIfTrue(value, content?has_content, otherwise) ]
[/#function]

[#function arrayIfContent value content otherwise=[]]
    [#return valueIfContent(asArray(value), content, otherwise) ]
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
        [#return arg ]
    [/#if]
[/#function]

[#------------------
-- Array handling --
--------------------]

[#-- Recursively concatenate sequence of non-empty strings with a separator --]
[#function concatenate args separator]
    [#local content = []]
    [#list asFlattenedArray(args) as arg]
        [#local argValue = arg!"COT:ERROR_INVALID_ARG_TO_CONCATENATE"]
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

[#-----------------
-- Object handling --
-------------------]

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
[#assign ARRAY_OF_OBJECT_TYPE  = [ARRAY_TYPE, OBJECT_TYPE] ]
[#assign ARRAY_OF_STRING_TYPE  = [ARRAY_TYPE, STRING_TYPE] ]
[#assign ARRAY_OF_NUMBER_TYPE  = [ARRAY_TYPE, NUMBER_TYPE] ]
[#assign ARRAY_OF_BOOLEAN_TYPE = [ARRAY_TYPE, BOOLEAN_TYPE] ]
[#-- Array of any if different to array in that value will be forced to an array --]
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

[#-----------------
-- CIDR handling --
-------------------]

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

