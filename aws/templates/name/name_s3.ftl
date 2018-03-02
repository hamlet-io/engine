[#-- S3 --]

[#-- Resources --]

[#function formatSegmentBucketName extensions...]
    [#return
        formatName(
            valueIfTrue(
                (tenantObject.Name)!"",
                (segmentObject.S3.IncludeTenant)!false,
                ""),
            formatSegmentFullName(extensions),
            vpc?remove_beginning("vpc-"))]
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
            vpc?remove_beginning("vpc-"))]
[/#function]
