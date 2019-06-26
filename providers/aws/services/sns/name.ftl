[#ftl]

[#function formatMobileNotifierLogGroupName engine name="" failure=false]

    [#return
        {
            "Fn::Join" : [
                "/",
                [
                    "sns",
                    { "Ref" : "AWS::Region" },
                    { "Ref" : "AWS::AccountId" }
                ] +
                valueIfTrue(
                    ["DirectPublishToPhoneNumber"],
                    engine == MOBILENOTIFIER_SMS_ENGINE,
                    ["app", engine, name]
                ) +
                arrayIfTrue(
                    [ "Failure" ],
                    failure
                )
            ]
        } ]
[/#function]

