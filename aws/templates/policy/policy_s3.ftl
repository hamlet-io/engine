[#-- S3 --]

[#macro s3Statement actions bucket key="" object=""]
    [@policyStatement
        actions
        "arn:aws:s3:::" + 
            bucket +
            key?has_content?then("/" + key, "") +
            object?has_content?then("/" + object, "")
    /]
[/#macro]

[#macro s3ReadStatement bucket key="" object="*"]
    [@s3Statement "s3:GetObject" bucket key object /]
[/#macro]

[#macro s3WriteStatement bucket key="" object="*"]
    [@s3Statement "s3:PutObject" bucket key object /]
[/#macro]

[#macro s3ListStatement bucket key="" object=""]
    [@s3Statement "s3:List*" bucket key object /]
[/#macro]


