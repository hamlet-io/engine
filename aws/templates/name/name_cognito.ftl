[#-- Cognito User Pool --]

[#function formatUserPoolName tier component ]
    [#return formatName(
        formatComponentFullName(
            tier,
            component))]
[/#function]

[#function formatUserPoolClientName tier component ]
    [#return formatName( 
        formatComponentFullName(
            tier,
            component))]
[/#function]

[#function formatIdentityPoolName tier component ]
    [#return formatId(
        productName,
        segmentName,
        getTierId(tier),
        getComponentId(component)
    )]
[/#function]