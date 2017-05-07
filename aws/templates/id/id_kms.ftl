[#-- KMS --]

[#-- Resources --]

[#function formatSegmentCMKId ]
    [#return formatSegmentResourceId(
                "cmk",
                "cmk")]
[/#function]

[#-- Attributes --]

[#function formatSegmentCMKArnId ]
    [#return formatArnAttributeId(
                formatSegmentCMKId())]
[/#function]

[#-- Attributes --]
