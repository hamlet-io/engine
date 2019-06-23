[#ftl]

[#-- Resources --]
[#assign AWS_CMK_RESOURCE_TYPE = "cmk" ]
[#assign AWS_CMK_ALIAS_RESOURCE_TYPE = "cmkalias" ]

[#function formatSegmentCMKId ]
    [#return
        migrateToResourceId(
            formatSegmentResourceId(AWS_CMK_RESOURCE_TYPE),
            formatSegmentResourceId(AWS_CMK_RESOURCE_TYPE, "cmk")
        )]
[/#function]

[#function formatSegmentCMKTemplateId ]
    [#return
        getExistingReference(
            formatSegmentResourceId(AWS_CMK_RESOURCE_TYPE,"cmk"))?has_content?then(
                "cmk",
                formatSegmentResourceId(AWS_CMK_RESOURCE_TYPE)
            )]
[/#function]

[#function formatSegmentCMKAliasId cmkId]
    [#return
      (cmkId == "cmk")?then(
        formatDependentResourceId("alias", cmkId),
        formatDependentResourceId(AWS_CMK_ALIAS_RESOURCE_TYPE, cmkId))]
[/#function]

[#function formatProductCMKId ]
    [#return
        migrateToResourceId(
            formatProductResourceId(AWS_CMK_RESOURCE_TYPE),
            formatProductResourceId(AWS_CMK_RESOURCE_TYPE, "cmk")
        )]
[/#function]

[#function formatProductCMKTemplateId ]
    [#return
        getExistingReference(
            formatProductResourceId(AWS_CMK_RESOURCE_TYPE, "cmk"))?has_content?then(
                "cmk",
                formatProductResourceId(AWS_CMK_RESOURCE_TYPE)
            )]
[/#function]

[#function formatProductCMKAliasId cmkId]
    [#return formatDependentResourceId(AWS_CMK_ALIAS_RESOURCE_TYPE, cmkId)]
[/#function]

