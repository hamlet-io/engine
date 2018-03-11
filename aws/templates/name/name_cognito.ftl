[#-- Cognito User Pool --]

[#function formatUserPoolName tier component extensions... ]
    [#return formatName(
        formatComponentFullName(
            tier,
            component))]
[/#function]

[#function formatUserPoolClientName tier component extensions... ]
    [#return formatName( 
        formatComponentFullName(
            tier,
            component))]
[/#function]

[#function formatIdentityPoolName tier component extensions... ]
    [#return formatId(
        productName,
        segmentName,
        getTierId(tier),
        getComponentId(component)
    )]
[/#function]