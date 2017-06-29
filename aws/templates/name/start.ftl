[#ftl]

[#-- Format names --]

[#-- Names are largely for human consumption, such as in the AWS console --]

[#function formatName names...]
    [#return concatenate(names, "-")]
[/#function]

[#function formatPath absolute names...]
    [#return
        absolute?then("/","") +
        concatenate(names, "/")]
[/#function]

[#function formatAbsolutePath names...]
    [#return formatPath(true, names)]
[/#function]

[#function formatRelativePath names...]
    [#return formatPath(false, names)]
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

[#-- Format a segment path --]
[#function formatSegmentPath absolute extensions...]
    [#return formatPath(
                absolute,
                productName,
                segmentName,
                extensions)]
[/#function]

[#function formatSegmentRelativePath extensions...]
    [#return formatSegmentPath(false, extensions)]
[/#function]

[#function formatSegmentAbsolutePath extensions...]
    [#return formatSegmentPath(true, extensions)]
[/#function]

[#-- Format a file prefix path --]
[#function formatSegmentPrefixPath type extensions...]
    [#return formatRelativePath(
                type,
                formatSegmentRelativePath(extensions))]
[/#function]

[#-- Format a component full path --]
[#function formatComponentAbsoluteFullPath tier component extensions...]
    [#return formatAbsolutePath(
                formatSegmentRelativePath(
                    getTierName(tier),
                    getComponentName(component),
                    extensions))]
[/#function]
