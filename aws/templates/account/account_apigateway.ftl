[#-- Account level roles --]
[#if deploymentUnit?contains("apigateway")]
    [#if deploymentSubsetRequired("apigateway", true)]
        [#assign cloudWatchRoleId = formatAccountRoleId("cloudwatch")]
        [#assign apiAccountId = formatAccountResourceId("apiAccount","cloudwatch")]
        
        [@createRole
            mode=listMode
            id=cloudWatchRoleId
            trustedServices=["apigateway.amazonaws.com"]
            managedArns=["arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"]
        /]
        
        [@cfResource
            mode=listMode
            id=apiAccountId
            type="AWS::ApiGateway::Account"
            properties=
                {
                    "CloudWatchRoleArn" : getReference(cloudWatchRoleId, ARN_ATTRIBUTE_TYPE)
                }
            outputs={}
        /]
    [/#if]
[/#if]

