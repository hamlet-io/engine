[#-- Account level roles --]
[#if deploymentUnit?contains("roles")]
    [#if resourceCount > 0],[/#if]
    [#assign cloudWatchRoleId = formatAccountRoleId("cloudwatch")]
    [#assign apiAccountId = formatAccountResourceId("apiAccount","cloudwatch")]
    [#assign automationRoleId = formatAccountRoleId("automation")]
    [#assign administratorRoleId = formatAccountRoleId("administrator")]
    [#assign viewerRoleId = formatAccountRoleId("viewer")]

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
            
            [#if accountObject.Access??]
                [#assign accessAccounts=[]]
                [#list accountObject.Access?values as accessAccount]
                    [#if accessAccount?is_hash]
                        [#assign accessAccounts += [accessAccount.AWSId]]
                    [/#if]
                [/#list]
                ,[@role
                    id=automationRoleId
                    name="codeontap-automation"
                    trustedAccounts=accessAccounts
                    managedArns=
                        [
                            "arn:aws:iam::aws:policy/AdministratorAccess"
                        ]
                /],
                [@role
                    id=administratorRoleId
                    name="codeontap-administrator"
                    trustedAccounts=accessAccounts
                    managedArns=
                        [
                            "arn:aws:iam::aws:policy/AdministratorAccess"
                        ]
                    multiFactor=true
                /],
                [@role
                    id=viewerRoleId
                    name="codeontap-viewer"
                    trustedAccounts=accessAccounts
                    managedArns=
                        [
                            "arn:aws:iam::aws:policy/ReadOnlyAccess"
                        ]
                    multiFactor=true
                /]
            [/#if]
            [#break]
        
        [#case "outputs"]
            [@output cloudWatchRoleId /],
            [@outputArn cloudWatchRoleId /]
            [#if accountObject.Access??]
                ,[@output automationRoleId /],
                [@outputArn automationRoleId /],
                [@output administratorRoleId /],
                [@outputArn administratorRoleId /],
                [@output viewerRoleId /],
                [@outputArn viewerRoleId /]
            [/#if]
            [#break]

    [/#switch]        
    [#assign resourceCount += 1]
[/#if]

