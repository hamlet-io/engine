[#ftl strip_text=true strip_whitespace=true ]
[#include "/setContext.ftl" ]

[#assign listMode = "reference"]

[#assign referenceTemplate = [] ]

[#macro MDSection
    title
    content ]

    [#assign referenceTemplate += [
        "# " + title,
        "\n"
    ] +
        asFlattenedArray(content) +
    [ "\n",
        "* * *"
    ]]
[/#macro]

[#function getMDNotification content severity="info" ]
    [#local result =  [
        "!!! " + severity
    ]]

    [#list content as line ]
        [#local result += [
            "    " + line
        ]]
    [/#list]
    [#return result]
[/#function]

[#function getMDList content ordered=false level=0 ]
    [#local result = []]

    [#local spacing = (level == 0)?then("", (""?left_pad(level + 2, " ")))]
    [#list asArray(content) as line ]
        [#if ordered ]
            [#local result += [
                spacing + line?counter + ". " + line
            ]]
        [#else]
            [#local result += [
                spacing + "- " + line
            ]]
        [/#if]
    [/#list]

    [#return result]
[/#function]

[#function getMDHeading heading level=2 newLine=true]
    [#local result = []]
    [#list asArray(heading) as line ]
        [#local result += [
            ""?left_pad(level, "#") + " " + heading + newLine?then("\n", "  ")
        ]]
    [/#list]
    [#return result]
[/#function]

[#function getMDCodeBlock content language ]
    [#local result =
        [
            "\n",
            "```" + language
        ] +
            asArray(content) +
        [
            "```",
            "\n"
        ]]
    [#return result]
[/#function]

[#function getMDString value ]
    [#local result = "" ]

    [#if value?is_sequence ]
        [#if value?has_content ]
            [#local result = value?join(", ")]
        [#else]
            [#local result = "[]" ]
        [/#if]
    [#elseif value?is_hash ]
        [#if value?has_content]
            [#local result = getJSON("value")]
        [#else]
            [#local result = "\{}"]
        [/#if]
    [#elseif value?is_number || value?is_boolean ]
        [#local result = value?c ]
    [#else]
        [#local result = value ]
    [/#if]

    [#if !result?has_content ]
        [#local result = "null" ]
    [/#if]
    [#return result]
[/#function]

[#function getAttributeDetails attribute currentLevel ]
    [#local result = [] ]
    [#local headerLevel = currentLevel]

    [#if attribute?is_string ]
        [#local attribute = {
            "Names" : attribute
        }]
    [/#if]

    [#if (attribute.Children![])?has_content ]

        [#local nameArray = asArray(attribute.Names)]
        [#local name = "[" + nameArray[0] + "](#" + nameArray[0] + ")"  ]

        [#if nameArray?size > 1 ]
            [#local name += " (_" + nameArray[1..]?join(", ") + "_)" ]
        [/#if]

        [#local result += getMDList(
                                name,
                                false,
                                headerLevel)]

        [#local headerLevel++ ]
        [#list attribute.Children as childAttribute ]
            [#local result +=
                getAttributeDetails(childAttribute, headerLevel)]
        [/#list]

    [#else]

        [#local name = "" ]
        [#local default = ""]
        [#local type = ""]
        [#local mandatory = false ]
        [#local requiredValue = ""]

        [#local hasDefault = false]

        [#local details = []]

        [#list attribute as key,value ]

            [#switch key ]
                [#case "Names" ]
                    [#local nameArray = asArray(value)]

                    [#local name += "[" + nameArray[0] + "](#" + nameArray[0] + ")"  ]

                    [#if nameArray?size > 1 ]
                        [#local name += " _(" + nameArray[1..]?join(", ") + ")_" ]
                    [/#if]
                    [#break]

                [#case "Mandatory" ]
                    [#local mandatory = value ]
                    [#break ]

                [#case "Default" ]
                    [#if value?has_content ]
                        [#local default +=  "__" + key + ":__ " + "`" + getMDString(value) + "`"]
                    [/#if]
                    [#break]

                [#case "Children" ]
                    [#break]

                [#case "Type"]
                    [#if value?is_sequence ]
                        [#local type += "__" + key + ":__ " + getMDString(value[0]) + " of " + getMDString(value[1])]
                    [#else]
                        [#local type +=  "__" + key + ":__ " + getMDString(value)]
                    [/#if]
                    [#break]

                [#case "Values"]
                    [#local details += [ "__Possible Values:__ `[" + getMDString(value) + "]`" ]]
                    [#break]

                [#default]
                    [#if value?has_content ]
                        [#local details += [ "__" + key + ":__ " + getMDString(value) ]  ]
                    [/#if]
            [/#switch]
        [/#list]

        [#local requiredValue = mandatory?then(
                                    "Required",
                                    "Optional")]

        [#local keydetails = name + " - " +
                                requiredValue +
                                (type?has_content)?then(
                                        " - " + type,
                                        "" ) +
                                (default?has_content)?then(
                                        " - " + default,
                                        "") + "  " ]

        [#local extradetails = details?has_content?then(
                            details?join("  "),
                            "")]

        [#local result += getMDList(
                                keydetails,
                                false,
                                headerLevel)]

        [#if extradetails?has_content ]
            [#local result += [ ""?left_pad(headerLevel * 8, " ") + extradetails ]]
        [/#if]
    [/#if]

    [#return result]
[/#function]

[#function getJSONEndingToLine content isLast ]
    [#if !isLast && content?size gt 1 ]
        [#local line = content[(content?size - 1)]]
        [#local line += "," ]
        [#local content = content[0..(content?size - 2)] + [ line ]]
    [/#if]

    [#return content]
[/#function]

[#function getNonEmptyArray array ]
    [#local result = [] ]
    [#list array as item ]
        [#if item?has_content ]
            [#local result += [ item ] ]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#function getMDCodeJSON obj depth=0 ]
    [#local result = [ "" ]]
    [#if depth == 0 ]
        [#if obj?is_hash ]
            [#local result += [ "\{" ]]
        [#else]
            [#local result += [ "[" ]]
        [/#if]
        [#local depth++ ]
    [/#if]

    [#local line = "" ]
    [#if obj?is_hash]
        [#list obj as key,value]
            [#local line = ""?left_pad(depth, "\t") +  "\"" + key  + "\" : " ]
            [#if value?is_hash ]
                [#if value?has_content ]
                    [#local line += line?has_content?then("\{", ""?left_pad(depth, "\t") + "\{" )]
                    [#local result += [ line ]]
                    [#local line = "" ]
                    [#local depth ++ ]
                    [#local result += getMDCodeJSON(value, depth ) ]
                    [#local depth -- ]
                [#else]
                    [#local line += "\{}" ]
                    [#local result += [ line ]]
                    [#local line = ""]
                [/#if]

            [#elseif value?is_sequence ]
                [#if value?has_content ]
                    [#local line += line?has_content?then("[", ""?left_pad(depth, "\t") + "[" )]
                    [#local result += [ line ]]
                    [#local line = "" ]
                    [#local depth ++ ]
                    [#local result += getMDCodeJSON(value, depth ) ]
                    [#local depth -- ]
                [#else]
                    [#local line += "[]" ]
                    [#local result += [ line ]]
                    [#local line = ""]
                [/#if]

            [#elseif value?is_number || value?is_boolean ]
                [#local line += value?c  ]
                [#local result += [ line ]]
                [#local line = ""]

            [#else ]
                [#local line += "\"" + value + "\"" ]
                [#local result += [ line ]]
                [#local line = ""]
            [/#if]
            [#local result = getJSONEndingToLine(result, key?is_last)]
            [#local result += [ line ]]
            [#local line = ""]
        [/#list]
        [#local depth -- ]
        [#local result += [ ""?left_pad(depth, "\t") + "}"]]
    [#else]
        [#if obj?is_sequence]
            [#list obj as entry]
                [#local result += getMDCodeJSON(entry, depth )]
                [#local result = getJSONEndingToLine(result, entry?is_last)]
            [/#list]
            [#local depth -- ]
            [#if depth > 0 ]
                [#local result += [ ""?left_pad(depth, "\t") + "]" ]]
            [/#if]
        [#else]
            [#if obj?is_string]
                [#local result = [ ""?left_pad(depth, "\t") + "\"" + obj + "\""]]
            [#elseif obj?is_boolean || obj?is_number]
                [#local result = [ ""?left_pad(depth, "\t") + obj?c ]]
            [/#if]
            [#local depth -- ]
        [/#if]
    [/#if]
    [#return result ]
[/#function]

[#function getComponentExample componentAttributes ]
    [#local result = {}]
    [#list componentAttributes as attribute ]
        [#if attribute?is_hash ]
            [#local attributeName = attribute.Names!"COTException: Attribute does not have a name" ]
            [#local name = attributeName?is_sequence?then(
                                attributeName[0],
                                attributeName
            )]

            [#if attribute.Default?has_content ]
                [#local value = attribute.Default ]
            [#elseif attribute.Children?has_content && attribute.Subobjects?has_content ]
                [#local value = { "example" : getComponentExample(attribute.Children) }]

            [#elseif attribute.Children?has_content && !attribute.Subobjects?has_content ]
                [#local value = getComponentExample(attribute.Children) ]
            [#else]
                [#local attributeType = attribute.Type!UNKNOWN_TYPE ]
                [#local value = "<" +  attributeType?is_sequence?then(
                                        attributeType?join(" of "),
                                        attributeType ) + ">" ]
            [/#if]
            [#local result += {
                name : value
            }]
        [#else]
            [#local result += {
                attribute : UNKNOWN_TYPE
            }]
        [/#if]
    [/#list]

    [#return result]
[/#function]

[#function getComponentSubExample componentSubComponents ]
    [#local result = {} ]
    [#list componentSubComponents as subComponent ]

        [#local result += {
            subComponent.Component : {
                "example" : "< instance of " + subComponent.Type + ">"
            }
        }]

    [/#list]
    [#return result]
[/#function]

[#list componentConfiguration as type,component ]

    [#if component?is_hash ]
        [#assign componentProperties = component.Properties![]]
        [#assign componentAttributes = component.Attributes![]]
        [#assign componentSubComponents = component.Components![]]

        [#assign description = []]
        [#assign deploymentProperties = [] ]
        [#assign notes = []]
        [#assign subComponents = []]

        [#assign attributeJson =
            [ "\n", "**Component Format**", "\n" ] +
            getMDCodeBlock(
                getNonEmptyArray(
                    getMDCodeJSON(
                        {
                            type :  getComponentExample(componentAttributes) +
                                    getComponentSubExample(componentSubComponents)
                        }
                    )
                ),
                "json" )]

        [#assign attributes =
            [ "\n", "**Attribute Reference**", "\n"]]

        [#list componentProperties as property ]
            [#switch property.Type!"Description" ]

                [#case "Description" ]
                    [#assign description +=
                        asArray(property.Value)]
                    [#break]

                [#case "Providers" ]
                    [#assign deploymentProperties +=
                            [ "**Available Providers** - " + getMDString(property.Value)  ]]
                    [#break]

                [#case "ComponentLevel" ]
                    [#assign deploymentProperties +=
                          [  "**Component Level** - " + getMDString(property.Value) ]]
                    [#break]

                [#case "Note" ]
                    [#assign notes +=
                        getMDNotification(
                            asArray(property.Value),
                            property.Severity!"info")]
                    [#break]
            [/#switch]
        [/#list]

        [#list componentAttributes as attribute ]
            [#assign attributes +=
                getAttributeDetails(attribute, 0)]
        [/#list]

        [#list componentSubComponents as subComponent ]
            [#assign subComponents +=
                getMDList( "[" + subComponent.Type + "](#" + getMDString(subComponent.Type) + ")" ) +
                getMDList( "**Component Attribute** - " + getMDString(subComponent.Component), false, 1  ) +
                getMDList( "**Link Attribute** - " + getMDString(subComponent.Link) , false, 1)
            ]
        [/#list]

        [#if notes?has_content ]
            [#assign notes = [ "\n", "**Notes**", "\n" ] + notes ]
        [/#if]

        [#if deploymentProperties?has_content ]
            [#assign deploymentProperties = [ "\n", "**Deployment Properties**", "\n" ] + getMDList(deploymentProperties) + [ "\n" ]]
        [/#if]

        [#if subComponents?has_content ]
            [#assign subComponents = [ "\n", "**Sub Components**", "\n" ] + subComponents]
        [/#if]

        [@MDSection
            title=type?lower_case
            content=
                description +
                deploymentProperties +
                notes +
                subComponents +
                attributeJson +
                attributes
        /]
    [/#if]
[/#list]

[#list referenceTemplate as line]
[#if line?is_string]
${line}
[#else]
${getJSON(line)}
[/#if]
[/#list]