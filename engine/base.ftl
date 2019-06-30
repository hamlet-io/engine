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

[#function mergeObjects current new]
    [#local result = current]
    [#list new as key,value]
        [#local newValue = value]
        [#if current[key]?? && current[key]?is_hash && value?is_hash]
            [#local newValue = mergeObjects(current[key], value)]
        [/#if]
        [#local result += {key : newValue}]
    [/#list]
    [#return result]
[/#function]

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

[#-- Format IPv4 - CIDR --]
[#function asCIDR value mask]
    [#local remainder = value]
    [#local result = []]
    [#list 0..3 as index]
        [#local result = [remainder % 256] + result]
        [#local remainder = (remainder / 256)?int ]
    [/#list]
    [#return [result?join("."), mask]?join("/")]
[/#function]

[#-- Determine mask bits per 8 bit part --]
[#function analyzeCIDR cidr ]
    [#-- Separate address and mask --]
    [#local re = cidr?matches(r"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})") ]
    [#if !re ]
        [#return {}]
    [/#if]
    [#local ip = re?groups[1] ]
    [#local mask = re?groups[2]?number ]

    [#-- Note that most significant part is at index 0 --]
    [#local parts = re?groups[1]?split(".") ]

    [#-- Determine how many of the mask bits affects each part --]
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

    [#-- Determine the offset value corresponding to the mask --]
    [#local base = [] ]
    [#list 0..3 as index]
        [#local partBits = partMasks[index] ]
        [#local partValue = parts[index]?number ]
        [#local baseValue = 0]
        [#-- reverse order as partMasks is a count of significant bits --]
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
            "Type" : "IPV4",
            "IP" : ip,
            "Mask" : mask,
            "Parts" : parts,
            "PartMasks" : partMasks,
            "Base" : base,
            "Offset" : offset
        }
    ]
[/#function]

[#-- Break CIDRs into collections of smaller CIDRs if they don't align to acceptable masks --]
[#-- Acceptable masks must be in increasing numeric order --]
[#function expandCIDR acceptableMasks cidrs... ]
    [#local result = [] ]
    [#list asFlattenedArray(cidrs) as cidr]

        [#local analyzedCIDR = analyzeCIDR(cidr) ]

        [#if !analyzedCIDR?has_content]
            [#continue]
        [/#if]
        [#list asFlattenedArray(acceptableMasks) as mask]
            [#if mask == analyzedCIDR.Mask]
                [#-- CIDR has an acceptable mask - use it as is --]
                [#local result += [cidr] ]
                [#break]
            [/#if]
            [#if mask > analyzedCIDR.Mask]
                [#local nextCIDROffset = analyzedCIDR.Offset ]
                [#local offsetIncrement = powersOf2[32 - mask] ]
                [#-- Generate individual entries for the nearest acceptable mask --]
                [#-- There could be quite a few depending on the increments in the acceptable masks --]
                [#list 0..powersOf2[mask - analyzedCIDR.Mask]-1 as entryIndex ]
                    [#local result += [asCIDR(nextCIDROffset, mask)] ]
                    [#local nextCIDROffset += offsetIncrement ]
                [/#list]
                [#break]
            [/#if]
        [/#list]
    [/#list]
    [#return result]
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

[#----------------------------
-- Dynamic macro invocation --
------------------------------]

[#function getFirstDefinedDirective directives=[] ]
    [#list asArray(directives) as directive]
        [#local macro = concatenate(directive, "_")]
        [#if (.vars[macro]!"")?is_directive]
            [#return macro]
        [/#if]
    [/#list]
    [#return ""]
[/#function]

[#-----------
-- Logging --
-------------]

[#assign DEBUG_LOG_LEVEL = 0]
[#assign TRACE_LOG_LEVEL = 1]
[#assign INFORMATION_LOG_LEVEL=3]
[#assign WARNING_LOG_LEVEL= 5]
[#assign ERROR_LOG_LEVEL = 7]
[#assign FATAL_LOG_LEVEL = 9]

[#assign logLevelDescriptions = [
    "debug",
    "trace",
    "",
    "info",
    "",
    "warn",
    "",
    "error",
    "",
    "fatal"
    ] ]

[#assign logMessages = [] ]

[#-- Set LogLevel variable to use a different log level --]
[#-- Can either be set as a number or as a string       --]
[#assign currentLogLevel = FATAL_LOG_LEVEL]
[#if logLevel?has_content]
    [#if logLevel?is_number]
        [#assign currentLogLevel = logLevel]
    [/#if]
    [#if logLevel?is_string]
        [#list logLevelDescriptions as value]
            [#if logLevel?lower_case?starts_with(value)]
                [#assign currentLogLevel = value?index]
                [#break]
            [/#if]
        [/#list]
    [/#if]
[/#if]

[#function getLogLevel ]
    [#return currentLogLevel]
[/#function]

[#function setLogLevel level]
    [#assign currentLogLevel = level]
    [#return getLogLevel()]
[/#function]

[#function willLog level ]
    [#return currentLogLevel <= level ]
[/#function]

[#macro logMessage severity message context={} detail={} enabled=false]
    [#if enabled && willLog(severity)]
        [#assign logMessages +=
            [
                {
                    "Timestamp" : .now?string["iso_ms"],
                    "Severity" : logLevelDescriptions[severity]!"unknown",
                    "Message" : message
                } +
                attributeIfContent("Context", context) +
                attributeIfContent("Detail", detail)
            ] ]
    [/#if]
[/#macro]

[#macro debug message context={} detail={} enabled=false]
    [@logMessage
        severity=DEBUG_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro trace message context={} detail={} enabled=false]
    [@logMessage
        severity=TRACE_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro info message context={} detail={} enabled=false]
    [@logMessage
        severity=INFORMATION_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro warn message context={} detail={} enabled=false]
    [@logMessage
        severity=WARNING_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro error message context={} detail={} enabled=false]
    [@logMessage
        severity=ERROR_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro fatal message context={} detail={} enabled=false]
    [@logMessage
        severity=FATAL_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro precondition function context={} detail={} enabled=false]
    [@fatal
        message="Precondition failed for " + function
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro postcondition function context={} detail={} enabled=false]
    [@fatal
        message="Postcondition failed for " + function
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

