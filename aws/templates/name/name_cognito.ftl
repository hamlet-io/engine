[#-- Cognito User Pool --]

[#function formatUserPoolName occurrence extensions...]
    [#return formatSegmentFullName(occurrence.Core.Name, extensions) ]
[/#function]

[#function formatUserPoolClientName occurrence extensions...]
    [#return formatSegmentFullName(occurrence.Core.Name, extensions) ]
[/#function]

[#function formatIdentityPoolName occurrence extensions...]
    [#return formatSegmentFullName(occurrence.Core.Name, extensions) ]
[/#function]