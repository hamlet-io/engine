[#-- Account level roles --]
[#if deploymentUnit?contains("apigateway")]
    [#if resourceCount > 0],[/#if]
    [#assign cloudWatchRoleId = formatAccountRoleId("cloudwatch")]
    [#assign apiAccountId = formatAccountResourceId("apiAccount","cloudwatch")]

    [#switch accountListMode]
        [#case "definition"]
            [@role
                id=cloudWatchRoleId
                trustedServices=
                    [
                        "apigateway.amazonaws.com"
                    ]
                managedArns=
                    [
                        "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
                    ]
            /],
            "${apiAccountId}" : {
              "Type" : "AWS::ApiGateway::Account",
              "Properties" : {
                "CloudWatchRoleArn" : 
                    { "Fn::GetAtt" : ["${cloudWatchRoleId}", "Arn"] }
              }
            }
            
            [#break]
        
        [#case "outputs"]
            [@output cloudWatchRoleId /],
            [@outputArn cloudWatchRoleId /]
            [#break]

    [/#switch]        
    [#assign resourceCount += 1]
[/#if]

