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

[#function formatAccountCMKTemplateId ]
    [#return
        getExistingReference(
            formatAccountResourceId(AWS_CMK_RESOURCE_TYPE,"cmk"))?has_content?then(
                "cmk",
                formatAccountResourceId(AWS_CMK_RESOURCE_TYPE)
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
