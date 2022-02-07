[#if getCLODeploymentUnit()?contains("directory") || (groupDeploymentUnits!false) ]

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

    [#assign directoryLogPolicyId = formatAccountResourceId("logpolicy", "directory")]
    [#assign directoryLogPolicyName = formatName("account", "directory")]

    [#if deploymentSubsetRequired("lg", true) &&
            isPartOfCurrentDeploymentUnit(directoryLogPolicyId)]

        [@cfResource
            id=directoryLogPolicyId
            type="AWS::Logs::ResourcePolicy"
            properties=
                {
                  "PolicyName" : directoryLogPolicyName,
                  "PolicyDocument" : {
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
                }
            outputs={}
        /]

    [/#if]
[/#if]
