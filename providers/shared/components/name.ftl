[#ftl]

[#-- Format names --]

[#-- Names are largely for human consumption, such as in the AWS console --]

[#function formatDomainName parts...]
    [#return concatenate(parts, ".")]
[/#function]

[#function splitDomainName name]
    [#return name?split(".")]
[/#function]

[#function formatNameExtension extensions...]
    [#return formatName(extensions)]
[/#function]

[#-- Format segment short name --]
[#function formatSegmentShortName extensions...]
    [#return formatName(getDistrictShortNameParts(getInputFilter()), extensions) ]
[/#function]

[#-- Format segment name --]
[#function formatSegmentFullName extensions...]
    [#return formatName(getDistrictFullNameParts(getInputFilter()),  extensions) ]
[/#function]

[#-- Format environment name --]
[#function formatEnvironmentFullName extensions...]
    [#return formatName(getDistrictFullNameParts(getInputFilter())[0..1],  extensions) ]
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
    [#return formatSegmentShortName(
                getTierName(tier),
                getComponentName(component),
                extensions)]
[/#function]

[#-- Format a component full name --]
[#function formatComponentFullName tier component extensions...]
    [#return formatSegmentFullName(
                getTierName(tier),
                getComponentName(component),
                extensions)]
[/#function]

[#-- Format a segment path --]
[#function formatSegmentPath absolute extensions...]
    [#return formatPath(absolute, getDistrictFullNameParts(getInputFilter()), extensions)]
[/#function]

[#function formatSegmentRelativePath extensions...]
    [#return formatSegmentPath(false, extensions)]
[/#function]

[#function formatSegmentAbsolutePath extensions...]
    [#return formatSegmentPath(true, extensions)]
[/#function]

[#function formatProductPath absolute extensions... ]
    [#return formatPath(
                absolute
                tenantName,
                productName,
                extensions)]
[/#function]

[#function formatProductRelativePath extensions...]
    [#return formatProductPath(false, extensions)]
[/#function]

[#function formatProductAbsolutePath extensions...]
    [#return formatProductPath(true, extensions)]
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
