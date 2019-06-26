[#ftl]

[#function formatSegmentBucketName segmentSeed extensions...]
    [#return
        formatName(
            valueIfTrue(
                (tenantObject.Name)!"",
                (segmentObject.S3.IncludeTenant)!false,
                ""),
            formatSegmentFullName(extensions),
            segmentSeed)]
[/#function]

[#function formatOccurrenceBucketName occurrence extensions...]
    [#return
        formatName(
            valueIfTrue(
                (tenantObject.Name)!"",
                (segmentObject.S3.IncludeTenant)!false,
                ""),
            formatComponentFullName(
                occurrence.Core.Tier,
                occurrence.Core.Component,
                occurrence
                extensions),
            segmentSeed)]
[/#function]
