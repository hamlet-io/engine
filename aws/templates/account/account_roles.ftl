[#-- Account level roles --]
[#if deploymentUnit?contains("roles")]
    [#if resourceCount > 0],[/#if]
    [#assign cloudWatchId = formatAccountRoleId("cloudwatch")]
    [#assign apiAccountId = formatAccountResourceId("apiAccount","cloudwatch")]

    [#switch accountListMode]
        [#case "definition"]
            [@role
                cloudWatchId,
                [
                    "apigateway.amazonaws.com"
                ],
                [
                    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
                ]
            /],
            "${apiAccountId}" : {
              "Type" : "AWS::ApiGateway::Account",
              "Properties" : {
                "CloudWatchRoleArn" : 
                    { "Fn::GetAtt" : ["${cloudWatchId}", "Arn"] }
              }
            }
            [#break]
        
        [#case "outputs"]
            [@output cloudWatchId /],
            [@outputArn cloudWatchId /]
            [#break]

    [/#switch]        
    [#assign resourceCount += 1]
[/#if]

