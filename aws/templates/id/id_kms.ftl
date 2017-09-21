[#-- KMS --]

[#assign CMK_RESOURCE_TYPE = "cmk" ]
[#assign CMK_ALIAS_RESOURCE_TYPE = "cmkalias" ]

[#-- Resources --]

[#function formatSegmentCMKId ]
    [#return
        migrateToResourceId(
            formatSegmentResourceId(CMK_RESOURCE_TYPE),
            formatSegmentResourceId(CMK_RESOURCE_TYPE, "cmk")
        )]
[/#function]

[#function formatSegmentCMKTemplateId ]
    [#return 
        getExistingReference(
            formatSegmentResourceId(CMK_RESOURCE_TYPE,"cmk"))?has_content?then(
                "cmk",
                formatSegmentResourceId(CMK_RESOURCE_TYPE)
            )]
[/#function]

[#function formatSegmentCMKAliasId cmkId]
    [#return formatDependentResourceId(CMK_ALIAS_RESOURCE_TYPE, cmkId)]
[/#function]

[#function formatProductCMKId ]
    [#return
        migrateToResourceId(
            formatProductResourceId(CMK_RESOURCE_TYPE),
            formatProductResourceId(CMK_RESOURCE_TYPE, "cmk")
        )]
[/#function]

[#function formatProductCMKTemplateId ]
    [#return
        getExistingReference(
            formatProductResourceId(CMK_RESOURCE_TYPE, "cmk"))?has_content?then(
                "cmk",
                formatProductResourceId(CMK_RESOURCE_TYPE)
            )]
[/#function]

[#function formatProductCMKAliasId cmkId]
    [#return formatDependentResourceId(CMK_ALIAS_RESOURCE_TYPE, cmkId)]
[/#function]

[#-- Attributes --]

[#function formatSegmentCMKArnId ]
    [#return formatArnAttributeId(
                formatSegmentCMKId())]
[/#function]

