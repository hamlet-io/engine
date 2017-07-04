[#-- Certificate --]

[#-- Resources --]

[#function formatCertificateId ids...]
    [#return formatResourceId(
                "certificate",
                ids)]
[/#function]

[#function formatDependentCertificateId resourceId extensions...]
    [#return formatDependentResourceId(
                "certificate",
                resourceId,
                extensions)]
[/#function]

[#function formatComponentCertificateId tier component extensions...]
    [#return formatComponentResourceId(
                "certificate",
                tier,
                component,
                extensions)]
[/#function]

[#-- Attributes --]
