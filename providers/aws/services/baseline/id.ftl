[#ftl]

[#function formatS3BaselineId role ]
    [#return formatSegmentResourceId(AWS_S3_RESOURCE_TYPE, role)]
[/#function]

[#function formatS3OperationsId]
    [#return
        migrateToResourceId(
            formatSegmentS3Id("ops"),
            formatSegmentS3Id("operations"),
            formatSegmentS3Id("logs")
        )]
[/#function]

[#function formatS3DataId]
    [#return
        migrateToResourceId(
            formatSegmentS3Id("data"),
            formatSegmentS3Id("application"),
            formatSegmentS3Id("backups")
        )]
[/#function]
