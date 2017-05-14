[#ftl]

[#-- Format ids --]

[#-- Largely used for cloud formation resource ids which have severe character constraints --]

[#function formatId ids...]
    [#return concatenate(ids, "X")]
[/#function]

[#function formatIdExtension extensions]
    [#return concatenate(extensions, "X")]
[/#function]

[#-- Component --]

[#function formatComponentId tier component extensions...]
    [#return formatId(
                getTierId(tier),
                getComponentId(component),
                extensions)]
[/#function]

[#-- Resource id = type + ids --]

[#function formatResourceId type ids...]
    [#return formatId(
                type,
                ids)]
[/#function]

[#function formatDependentResourceId type resourceId extensions...]
    [#return formatResourceId(
                type,
                resourceId,
                extensions)]
[/#function]

[#-- TODO: Remove when use of "container" is removed --]
[#function formatContainerResourceId type extensions...]
    [#return formatResourceId(
                type,
                "container",
                extensions)]
[/#function]

[#function formatSegmentResourceId type extensions...]
    [#return formatResourceId(
                type,
                "segment",
                extensions)]
[/#function]

[#function formatZoneResourceId type tier zone extensions...]
    [#return formatResourceId(
                type,
                getTierId(tier),
                getZoneId(zone),
                extensions)]
[/#function]

[#function formatComponentResourceId type tier component extensions...]
    [#return formatResourceId(
                type,
                getTierId(tier),
                getComponentId(component),
                extensions)]
[/#function]

[#function formatProductResourceId type extensions...]
    [#return formatResourceId(
                type,
                "product",
                extensions)]
[/#function]

[#function formatAccountResourceId type extensions...]
    [#return formatResourceId(
                type,
                "product",
                extensions)]
[/#function]

[#-- Attribute id = resourceId + attribute id --]

[#function formatAttributeId resourceId attributeId]
    [#return formatId(
                resourceId,
                attributeId)]
[/#function]

[#function formatArnAttributeId resourceId]
    [#return formatAttributeId(
                resourceId,
                "arn")]
[/#function]

[#function formatUrlAttributeId resourceId]
    [#return formatAttributeId(
                resourceId,
                "url")]
[/#function]

[#function formatDnsAttributeId resourceId]
    [#return formatAttributeId(
                resourceId,
                "dns")]
[/#function]

[#function formatIPAddressAttributeId resourceId]
    [#return formatAttributeId(
                resourceId,
                "ip")]
[/#function]

[#function formatAllocationAttributeId resourceId]
    [#return formatAttributeId(
                resourceId,
                "id")]
[/#function]

[#function formatCertificateAttributeId resourceId]
    [#return formatAttributeId(
                resourceId,
                "certificate")]
[/#function]

[#function formatQualifierAttributeId resourceId]
    [#return formatAttributeId(
                resourceId,
                "qualifier")]
[/#function]

[#function formatRootAttributeId resourceId]
    [#return formatAttributeId(
                resourceId,
                "root")]
[/#function]

[#function formatPortAttributeId resourceId]
    [#return formatAttributeId(
                resourceId,
                "port")]
[/#function]

[#function formatUsernameAttributeId resourceId]
    [#return formatAttributeId(
                resourceId,
                "username")]
[/#function]

[#function formatPasswordAttributeId resourceId]
    [#return formatAttributeId(
                resourceId,
                "password")]
[/#function]

[#function formatDatabaseNameAttributeId resourceId]
    [#return formatAttributeId(
                resourceId,
                "databasename")]
[/#function]
