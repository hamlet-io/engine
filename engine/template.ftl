[#ftl]

[#-- Support routines for template generation --]

[#-- Text based template --]

[#assign textTemplate = [] ]

[#macro initialiseTextTemplate]
    [#assign textTemplate = [] ]
[/#macro]

[#function getTextTemplate]
    [#return textTemplate]
[/#function]

[#macro addToTextTemplate lines=[] ]
    [#assign textTemplate += asFlattenedArray(lines)]
[/#macro]

[#macro serialiseTextTemplate]
    [#list textTemplate as line]
        ${line}
    [/#list]
[/#macro]

[#-- JSON object based template --]
[#assign jsonTemplate = {} ]

[#macro initialiseJsonTemplate]
    [#assign jsonTemplate = {} ]
[/#macro]

[#function getJsonTemplate]
    [#return jsonTemplate]
[/#function]

[#macro mergeWithJsonTemplate object={} ]
    [#assign jsonTemplate = mergeObjects(jsonTemplate, object)]
[/#macro]

[#macro addToJsonTemplate object={} ]
    [#assign jsonTemplate = jsonTemplate + object]
[/#macro]

[#macro serialiseJsonTemplate]
    [@toJSON jsonTemplate /]
[/#macro]
