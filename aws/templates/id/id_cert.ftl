[#-- Certificate --]

[#-- Resources --]

[#function formatCertificateId region ids...]
    [#return formatResourceId(
                "certificate",
                ids,
                region?replace("-","X"))]
[/#function]

[#function formatDependentCertificateId region resourceId extensions...]
    [#return formatDependentResourceId(
                "certificate",
                resourceId,
                extensions,
                region?replace("-","X"))]
[/#function]

[#function formatComponentCertificateId region tier component extensions...]
    [#return formatComponentResourceId(
                "certificate",
                tier,
                component,
                extensions,
                region?replace("-","X"))]
[/#function]

[#-- Attributes --]
