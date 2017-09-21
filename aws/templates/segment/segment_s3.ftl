[#-- Standard set of buckets for a segment --]

[#if componentType == "s3" &&
        deploymentSubsetRequired("s3", true)]

    [#-- TODO: Should be using formatSegmentS3Id() not formatS3Id() --]
    [#-- TODO: Can then remove alternate ids for the buckets --]
    [#assign s3OperationsId = formatS3Id(operationsBucketType)]
    [#assign s3DataId = formatS3Id(dataBucketType)]
    [#assign s3OperationsPolicyId = formatDependentBucketPolicyId(s3OperationsId)]

    [@createS3Bucket
        mode=segmentListMode
        id=s3OperationsId
        name=operationsBucket
        lifecycleRules=
            operationsExpiration?is_number?then(
                getS3LifecycleExpirationRule(operationsExpiration, "AWSLogs") +
                    getS3LifecycleExpirationRule(operationsExpiration, "CLOUDFRONTLogs") +
                    getS3LifecycleExpirationRule(operationsExpiration, "DOCKERLogs"),
                []
            )
        outputId=formatSegmentS3Id("ops")
    /]
    
    [@createBucketPolicy
        mode=segmentListMode
        id=s3OperationsPolicyId
        bucket=operationsBucket
        statements=
            getS3WriteStatement(
                operationsBucket,
                "AWSLogs",
                "*",
                {
                    "AWS": "arn:aws:iam::" + regionObject.Accounts["ELB"] + ":root"
                }
            ) +
            getS3ReadBucketACLStatement(
                operationsBucket,
                { "Service": "logs." + regionId + ".amazonaws.com" }
            ) +
            getS3WriteStatement(
                operationsBucket,
                "",
                "*",
                { "Service": "logs." + regionId + ".amazonaws.com" },
                { "StringEquals": { "s3:x-amz-acl": "bucket-owner-full-control" } }
            )
        dependencies=[ s3OperationsId ]
    /]
    
    [@createS3Bucket
        mode=segmentListMode
        id=s3DataId
        name=dataBucket
        lifecycleRules=
            dataExpiration?is_number?then(
                getS3LifecycleExpirationRule(dataExpiration),
                []
            )
        outputId=formatSegmentS3Id("data")
    /]
    
    
    [#-- Legacy naming --]
    [#-- TODO: Remove --]
    [@cfTemplateOutput
        mode=segmentListMode
        id=formatId("s3", operationsBucketSegment, operationsBucketType)
        value=
            {
                "Ref" : formatId("s3", operationsBucketType)
            }
    /]
    [@cfTemplateOutput
        mode=segmentListMode
        id=formatId("s3", dataBucketSegment, dataBucketType)
        value=
            {
                "Ref" : formatId("s3", dataBucketType)
            }
    /]
[/#if]

