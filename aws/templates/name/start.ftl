[#ftl]

[#-- Format names --]

[#-- Names are largely for human consumption, such as in the AWS console --]

[#function formatName names...]
    [#return concatenate(names, "-")]
[/#function]

[#function formatNameExtension extensions...]
    [#return formatName(extensions)]
[/#function]

[#-- Format a component short name - based on ids not names --]
[#function formatComponentShortName tier component extensions...]
    [#return formatName(
                getTierId(tier),
                getComponentId(component),
                extensions)]
[/#function]

[#-- Format a component short name with type - based on ids not names --]
[#function formatComponentShortNameWithType tier component extensions...]
    [#return formatName(
                getTierId(tier),
                getComponentId(component),
                getComponentType(component),
                extensions)]
[/#function]

[#-- Format a component name --]
[#function formatComponentName tier component extensions...]
    [#return formatName(
                getTierName(tier),
                getComponentName(component),
                extensions)]
[/#function]

[#-- Format a component "short" full name - based on ids not names --]
[#function formatComponentShortFullName tier component extensions...]
    [#return formatName(
                productId,
                segmentId,
                getTierName(tier),
                getComponentName(component),
                extensions)]
[/#function]

[#-- Format a component full name --]
[#function formatComponentFullName tier component extensions...]
    [#return formatName(
                productName,
                segmentName,
                getTierName(tier),
                getComponentName(component),
                extensions)]
[/#function]

