[#-- API Gateway --]
[#if getDeploymentUnit()?contains("apigateway") || (allDeploymentUnits!false) ]
    [#assign cloudWatchRoleId = formatAccountRoleId("cloudwatch")]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets="template" /]
    [/#if]

    [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(cloudWatchRoleId)]
        [@createRole
            id=cloudWatchRoleId
            trustedServices=["apigateway.amazonaws.com"]
            managedArns=["arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"]
        /]
    [/#if]

    [#if deploymentSubsetRequired("apigateway", true)]
        [#assign apiAccountId = formatAccountResourceId("apiAccount","cloudwatch")]

        [@cfResource
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
