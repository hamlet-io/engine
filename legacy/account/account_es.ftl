[#if getCLODeploymentUnit()?contains("es") || (groupDeploymentUnits!false) ]

    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets=[ "template" ] /]
    [/#if]

    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[
            AWS_CLOUDWATCH_SERVICE
        ]
        deploymentFramework=CLOUD_FORMATION_DEPLOYMENT_FRAMEWORK
    /]

    [#assign esLogPolicyId = formatAccountResourceId(AWS_CLOUDWATCH_LOG_RESOURCE_POLICY_RESOURCE_TYPE, "es")]
    [#assign esLogPolicyName = formatName("account", "es")]

    [#if deploymentSubsetRequired("lg", true) &&
            isPartOfCurrentDeploymentUnit(esLogPolicyId)]

        [@createLogResourcePolicy
            id=esLogPolicyId
            name=esLogPolicyName
            policyDocument={
                "Fn::Sub" : [
                    getJSON(
                        {
                            "Version": "2012-10-17",
                            "Statement": [
                                {
                                    "Effect": "Allow",
                                    "Principal": {
                                        "Service": "es.amazonaws.com"
                                    },
                                    "Action": [
                                        "logs:CreateLogStream",
                                        "logs:PutLogEvents"
                                    ],
                                    "Resource": [
                                        r'arn:aws:logs:${Region}:${AWSAccountId}:log-group:/elasticsearch/*'
                                    ]
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
