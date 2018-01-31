[#-- Cognito User Pool --]

[#function formatUserPoolName tier component userpool ]
    [#return formatName(
                "userpoool",
                formatComponentFullName(
                    tier,
                    component,
                    userpool))]
[/#function]

[#function formatUserPoolClientName tier component userpool ]
    [#return formatName( 
        "userpoolclient",
        formatComponentFullName(
            tier,
            component
            userpool))]
[/#function]

[#function formatUserPoolIdentityPoolName tier component userpool ]
    [#return formatNameSeperator(
        "_"
        "identitypool",
        productName,
        segmentName,
        getTierName(tier),
        getComponentName(component)
        userpool)]
[/#function]