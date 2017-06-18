[#-- Account level roles --]
[#if deploymentUnit?contains("apigateway")]
    [#assign cloudWatchRoleId = formatAccountRoleId("cloudwatch")]
    [#assign apiAccountId = formatAccountResourceId("apiAccount","cloudwatch")]

    [#switch accountListMode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
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
            [@resourcesCreated /]
            [#break]
        
        [#case "outputs"]
            [@output cloudWatchRoleId /]
            [@outputArn cloudWatchRoleId /]
            [#break]

    [/#switch]        
[/#if]

