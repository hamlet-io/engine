[#if getCLODeploymentUnit()?contains("directory") || (groupDeploymentUnits!false) ]

    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets=[ "deploymentcontract", "template" ] /]
    [/#if]

    [#if deploymentSubsetRequired("deploymentcontract", false)]
        [@addDefaultAWSDeploymentContract /]
    [/#if]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_CLOUDWATCH_SERVICE
        ]
        deploymentFramework=CLOUD_FORMATION_DEPLOYMENT_FRAMEWORK
    /]

    [#assign directoryLogPolicyId = formatAccountResourceId(AWS_CLOUDWATCH_LOG_RESOURCE_POLICY_RESOURCE_TYPE, "directory")]
    [#assign directoryLogPolicyName = formatName("account", "directory")]

    [#if deploymentSubsetRequired("lg", true) &&
            isPartOfCurrentDeploymentUnit(directoryLogPolicyId)]

        [@createLogResourcePolicy
            id=directoryLogPolicyId
            name=directoryLogPolicyName
            policyDocument={
                "Fn::Sub" : [
                    getJSON(
                        {
                            "Version": "2012-10-17",
                            "Statement": [
                                {
                                    "Effect": "Allow",
                                    "Principal": {
                                        "Service": "ds.amazonaws.com"
                                    },
                                    "Action": [
                                        "logs:CreateLogStream",
                                        "logs:PutLogEvents"
                                    ],
                                    "Resource": r'arn:aws:logs:${Region}:${AWSAccountId}:log-group:/aws/directoryservice/*'
                                }
                            ]
                        }
                    ),
                    {
                        "Region" : {
                            "Ref" : "AWS::Region"
                        },
                        "AWSAccountId" : {
                            "Ref" : "AWS::AccountId"
                        }
                    }
                ]
            }
        /]

    [/#if]
[/#if]
