[#ftl strip_text=true strip_whitespace=true ]
[#include "setContext.ftl" ]

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

[#function getMDHeading heading level=2 ]
    [#return [
        ""?left_pad(level, "#") + " " + heading,
        "\n"
    ]]
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
    [#local headerLevel = currentLevel ]

    [#if attribute?is_string ]
        [#local attribute = {
            "Name" : attribute
        }]
    [/#if]

    [#if (attribute.Children![])?has_content ]
    
        [#local result = getMDList(
                            "**" + (attribute.Name!"Unkown Name") + "**", 
                            false,
                            headerLevel)]
        [#local headerLevel++ ]
        [#list attribute.Children as childAttribute ]
            [#local result += 
                getAttributeDetails(childAttribute, headerLevel)]
        [/#list]
    
    [#else]

        [#list attribute as key,value ]
            [#local name = [] ]
            [#local details = []]
            [#switch key ]
                [#case "Name" ]
                [#case "Names" ]    
                    [#if value?is_sequence  ]
                        [#if value?size > 1 ] 
                            [#local name += 
                                getMDList(
                                    "**" + value[0] + "**", 
                                    false, 
                                    headerLevel 
                                ) +
                                getMDList(
                                    "**Alternate Names** - " + value[1..]?join(", "), 
                                    false,
                                    (headerLevel + 2))
                                ] 
                        [#else]
                            [#local name += 
                                getMDList(
                                    "**" + value[0] + "**", 
                                    false, 
                                    headerLevel 
                                )]
                        [/#if]
                    [#else]
                        [#local result += 
                            getMDList(
                                "**" + value + "**", 
                                false,
                                headerLevel )]
                    [/#if]
                    [#break]
                [#case "Children" ]
                    [#break]

                [#case "Type"]
                    [#if value?is_sequence ]
                        [#local details += [
                            getMDList( 
                                "**" + key + "** - " + getMDString(value[0]) + " of " + getMDString(value[1]), 
                                false,
                                (headerLevel + 2)) ]]
                        ]]
                    [#else]
                        [#local details += [
                            getMDList( 
                                "**" + key + "** - " + getMDString(value), 
                                false,
                                (headerLevel + 2)) ]]
                    [/#if]
                    [#break]
                
                [#default]
                    [#local details += [
                        getMDList( 
                            "**" + key + "** - " + getMDString(value), 
                            false,
                            (headerLevel + 2)) ]]
            [/#switch]

            [#local result += 
                        name + 
                        details ]
        [/#list]
    [/#if]

    [#return result]
[/#function]

[#function getMDCodeJSON obj depth=0 ]
    [#local result = []]
    [#local line = "" ]

    [#if obj?is_hash]
        [#local line += "\{" ]]
        [#local result += [ line ] ]
        [#local line = "" ]
    
        [#local depth++ ]
    
        [#list obj as key,value]
            [#local line = ""?left_pad(depth, "\t") +  "\"" + key  + "\" : " ]
            [#if value?is_hash ]
                [#local line += "\{" ]
                [#local result += [ line ]]
                [#local line = "" ]
                [#local depth ++ ]
                [#local result += getMDCodeBlock(value, depth ) ]
            
            [#elseif value?is_sequence ]

                [#local line += "[" ]
                [#local result += [ line ]]
                [#local line = "" ]
                [#local depth ++ ]
                [#local result += getMDCodeBlock(value, depth ) ]

            [#elseif value?is_number || value?is_boolean ]
                [#local line += "\"" + value?c + "\"" ]
                [#local result += [ line ]]
                [#local line = ""]

            [#else ]
                [#local line += "\"" + value + "\"" ]
                [#local result += [ line ]]
                [#local line = ""]
            [/#if]


            [#sep][#local line += "," ][/#sep]
            [#local result += [ line ]]
            [#local line = ""]
        [/#list]
        [#local result += [ "}"]]
        [#local depth-- ]
    [#else]
        [#if obj?is_sequence]

            [#local depth++ ]
            [#list obj as entry]
                [#local line = ""?left_pad(depth, "\t") +  "\"" + entry  + "\""]
                [#sep][#local line += [ "," ]][/#sep]
            [/#list]
            [#local depth--]

        [#else]
            [#if obj?is_string]
                [#local result = [ ""?left_pad(depth, "\t") + "\"" + obj + "\""]]
            [#else]
                [#local result = [ ""?left_pad(depth, "\t") + obj?c ]]
            [/#if]
        [/#if]
    [/#if]
    [#return result ]
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
            getMDHeading("Component Format", 2) +
            getMDCodeBlock(
                getMDCodeJSON(component.Attributes), 
                "json" )]

        [#assign attributes =
            getMDHeading("Attribute Reference", 2)]
        
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
            [#assign notes = getMDHeading("Notes", 2 ) + notes ]
        [/#if]

        [#if deploymentProperties?has_content ]
            [#assign deploymentProperties = getMDHeading("Deployment Properties", 2) + getMDList(deploymentProperties) + [ "\n" ]] 
        [/#if]

        [#if subComponents?has_content ]
            [#assign subComponents = getMDHeading("Sub Components", 2 ) + subComponents]
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
getJSON(line)
[/#if]
[/#list]