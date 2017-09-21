[#ftl]

[#-- Format ids --]

[#-- Largely used for cloud formation resource ids which have severe character constraints --]

[#function formatId ids...]
    [#return concatenate(ids, "X") ]
[/#function]

[#function formatIdExtension extensions]
    [#return concatenate(extensions, "X") ]
[/#function]

[#-- Component --]

[#function formatComponentId tier component extensions...]
    [#return
        formatId(
            getTierId(tier),
            getComponentId(component),
            extensions) ]
[/#function]

[#-- Resource id = type + ids --]

[#function getResourceType resourceId]
    [#return resourceId?split("X")[0] ]
[/#function]

[#function formatResourceId type ids...]
    [#return
        formatId(
            type,
            ids) ]
[/#function]

[#function formatDependentResourceId type resourceId extensions...]
    [#return
        formatResourceId(
            type,
            resourceId,
            extensions) ]
[/#function]

[#-- TODO: Remove when use of "container" is removed --]
[#function formatContainerResourceId type extensions...]
    [#return
        formatResourceId(
            type,
            "container",
            extensions) ]
[/#function]

[#function formatSegmentResourceId type extensions...]
    [#return
        formatResourceId(
            type,
            "segment",
            extensions) ]
[/#function]

[#function formatTierResourceId type tier extensions...]
    [#return
        formatResourceId(
            type,
            getTierId(tier),
            extensions) ]
[/#function]

[#function formatZoneResourceId type tier zone extensions...]
    [#return
        formatResourceId(
            type,
            getTierId(tier),
            getZoneId(zone),
            extensions) ]
[/#function]

[#function formatComponentResourceId type tier component extensions...]
    [#return
        formatResourceId(
            type,
            getTierId(tier),
            getComponentId(component),
            extensions) ]
[/#function]

[#function formatProductResourceId type extensions...]
    [#return
        formatResourceId(
            type,
            "product",
            extensions) ]
[/#function]

[#function formatAccountResourceId type extensions...]
    [#return
        formatResourceId(
            type,
            "account",
            extensions) ]
[/#function]

[#-- Attribute id = resourceId + attribute type --]

[#assign ARN_ATTRIBUTE_TYPE = "arn" ]
[#assign URL_ATTRIBUTE_TYPE = "url" ]
[#assign DNS_ATTRIBUTE_TYPE = "dns" ]
[#assign NAME_ATTRIBUTE_TYPE = "name" ]
[#assign IP_ADDRESS_ATTRIBUTE_TYPE = "ip" ]
[#assign ALLOCATION_ATTRIBUTE_TYPE = "id" ]
[#assign CERTIFICATE_ATTRIBUTE_TYPE = "certificate" ]
[#assign QUALIFIER_ATTRIBUTE_TYPE = "qualifier" ]
[#assign ROOT_ATTRIBUTE_TYPE = "root" ]
[#assign PORT_ATTRIBUTE_TYPE = "port" ]
[#assign USERNAME_ATTRIBUTE_TYPE = "username" ]
[#assign PASSWORD_ATTRIBUTE_TYPE = "password" ]
[#assign DATABASENAME_ATTRIBUTE_TYPE = "databasename" ]
[#assign TOPICNAME_ATTRIBUTE_TYPE = "topicname" ]

[#-- special attribute type to handle references --]
[#assign REFERENCE_ATTRIBUTE_TYPE = "ref" ]

[#function formatAttributeId resourceId attributeType]
    [#return
        formatId(
            resourceId,
            attributeType) ]
[/#function]

[#function formatArnAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            ARN_ATTRIBUTE_TYPE) ]
[/#function]

[#function formatUrlAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            URL_ATTRIBUTE_TYPE) ]
[/#function]

[#function formatDnsAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            DNS_ATTRIBUTE_TYPE) ]
[/#function]

[#function formatIPAddressAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            IP_ADDRESS_ATTRIBUTE_TYPE) ]
[/#function]

[#function formatAllocationAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            ALLOCATION_ATTRIBUTE_TYPE) ]
[/#function]

[#function formatCertificateAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            CERTIFICATE_ATTRIBUTE_TYPE) ]
[/#function]

[#function formatQualifierAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            QUALIFIER_ATTRIBUTE_TYPE) ]
[/#function]

[#function formatRootAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            ROOT_ATTRIBUTE_TYPE) ]
[/#function]

[#function formatPortAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            PORT_ATTRIBUTE_TYPE) ]
[/#function]

[#function formatUsernameAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            USERNAME_ATTRIBUTE_TYPE) ]
[/#function]

[#function formatPasswordAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            PASSWORD_ATTRIBUTE_TYPE) ]
[/#function]

[#function formatDatabaseNameAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            DATABASENAME_ATTRIBUTE_TYPE) ]
[/#function]

[#function formatTopicNameAttributeId resourceId]
    [#return
        formatAttributeId(
            resourceId,
            TOPICNAME_ATTRIBUTE_TYPE) ]
[/#function]
