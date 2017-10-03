[#-- Standard set of buckets for a segment --]

[#if componentType == "s3" &&
        deploymentSubsetRequired("s3", true)]

    [#assign s3OperationsId = formatS3OperationsId()]
    [#assign s3DataId = formatS3DataId()]

    [#-- TODO Remove "Template" variants once legacy naming not longer being used --]
    [#assign s3OperationsTemplateId = formatS3OperationsTemplateId()]
    [#assign s3OperationsPolicyTemplateId = formatDependentBucketPolicyId(s3OperationsTemplateId)]
    [#assign s3DataTemplateId = formatS3DataTemplateId()]

    [@createS3Bucket
        mode=segmentListMode
        id=s3OperationsTemplateId
        name=operationsBucket
        lifecycleRules=
            operationsExpiration?is_number?then(
                getS3LifecycleExpirationRule(operationsExpiration, "AWSLogs") +
                    getS3LifecycleExpirationRule(operationsExpiration, "CLOUDFRONTLogs") +
                    getS3LifecycleExpirationRule(operationsExpiration, "DOCKERLogs"),
                []
            )
        outputId=s3OperationsId
    /]
    
    [@createBucketPolicy
        mode=segmentListMode
        id=s3OperationsPolicyTemplateId
        bucket=operationsBucket
        statements=
            s3WritePermission(
                operationsBucket,
                "AWSLogs",
                "*",
                {
                    "AWS": "arn:aws:iam::" + regionObject.Accounts["ELB"] + ":root"
                }
            ) +
            s3ReadBucketACLPermission(
                operationsBucket,
                { "Service": "logs." + regionId + ".amazonaws.com" }
            ) +
            s3WritePermission(
                operationsBucket,
                "",
                "*",
                { "Service": "logs." + regionId + ".amazonaws.com" },
                { "StringEquals": { "s3:x-amz-acl": "bucket-owner-full-control" } }
            )
        dependencies=s3OperationsTemplateId
    /]
    
    [@createS3Bucket
        mode=segmentListMode
        id=s3DataTemplateId
        name=dataBucket
        lifecycleRules=
            dataExpiration?is_number?then(
                getS3LifecycleExpirationRule(dataExpiration),
                []
            )
        outputId=s3DataId
    /]
    
    
    [#-- Legacy naming --]
    [#-- TODO: Remove --]
    [@cfOutput
        mode=segmentListMode
        id=formatSegmentS3Id("ops", "template")
        value=s3OperationsTemplateId
    /]
    [@cfOutput
        mode=segmentListMode
        id=formatSegmentS3Id("data", "template")
        value=s3DataTemplateId
    /]
    [#if s3OperationsId != s3OperationsTemplateId ]
        [@cfOutput
            mode=segmentListMode
            id=formatSegmentS3Id("ops")
            value=
                {
                    "Ref" : s3OperationsTemplateId
                }
        /]
    [/#if]
    [#if s3DataId != s3DataTemplateId ]
        [@cfOutput
            mode=segmentListMode
            id=formatSegmentS3Id("data")
            value=
                {
                    "Ref" : s3DataTemplateId
                }
        /]
    [/#if]
[/#if]

