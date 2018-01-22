[#-- SNS --]

[#function getSnsStatement actions id="" principals="" conditions=""]
    [#local result = [] ]
    [#if id?has_content]
        [#local result +=
            [
                getPolicyStatement(
                    actions,
                    getReference(id, ARN_ATTRIBUTE_TYPE),
                    principals,
                    conditions)
            ]
        ]
    [#else]
        [#local result +=
            [
                getPolicyStatement(
                    actions,
                    "*",
                    principals
                    conditions
                )
            ]
        ]
    [/#if]
    
    [return result]
[/#function]

[#function snsAdminPermission id=""]
    [#return
        getSnsStatement(
            "sns:*",
            id)]
[/#function]

[#function snsPublishPermission id="" ] 
    [#return
        getSnsStatement(
            "sns:publish",
            id)]
[/#function]