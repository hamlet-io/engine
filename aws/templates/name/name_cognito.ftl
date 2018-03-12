[#-- Cognito User Pool --]

[#function formatUserPoolName occurrence extensions... ]
    [#return formatName(
        formatComponentFullName(
            occurrence.Core.Tier,
            occurrence.Core.Component,
            occurrence,
            extensions))]
[/#function]

[#function formatUserPoolClientName occurrence extensions... ]
    [#return formatName( 
        formatComponentFullName(
            occurrence.Core.Tier,
            occurrence.Core.Component,
            occurrence,
            extensions))]
[/#function]

[#function formatIdentityPoolName occurrence extensions... ]
    [#return formatId(
        productName,
        segmentName,
        occurrence.Core.Tier,
        occurrence.Core.Component,
        extensions)]
[/#function]