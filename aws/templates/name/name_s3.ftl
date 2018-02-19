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

[#function formatComponentBucketName tier component extensions...]
    [#return
        formatName(
            valueIfTrue(
                (tenantObject.Name)!"",
                (segmentObject.S3.IncludeTenant)!false,
                ""),
            formatComponentFullName(tier, component, extensions),
            vpc?remove_beginning("vpc-"))]
[/#function]
