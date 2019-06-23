[#ftl]

[#function formatWAFIPSetName group extensions...]
    [#return formatName(
                group,
                extensions)]
[/#function]

[#function formatComponentWAFAclName tier component extensions...]
    [#return formatComponentFullName(
                tier,
                component,
                extensions)]
[/#function]
