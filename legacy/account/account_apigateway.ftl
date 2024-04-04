[#-- API Gateway --]
[#if getCLODeploymentUnit()?contains("apigateway") || (groupDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets=["deploymentcontract", "template"] /]
    [/#if]

    [#if deploymentSubsetRequired("deploymentcontract", false)]
        [@addDefaultAWSDeploymentContract /]
    [/#if]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[AWS_IDENTITY_SERVICE ]
        deploymentFramework=getCLODeploymentFramework()
    /]

    [#assign cloudWatchRoleId = formatAccountRoleId("cloudwatch")]

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
