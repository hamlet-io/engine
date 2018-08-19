[#-- Standard set of buckets for a segment --]

[#if componentType == "s3" &&
        deploymentSubsetRequired("s3", true)]

    [#assign s3OperationsId = formatS3OperationsId()]
    [#assign s3DataId = formatS3DataId()]

    [#-- TODO Remove "Template" variants once legacy naming not longer being used --]
    [#assign s3OperationsTemplateId = formatS3OperationsTemplateId()]
    [#assign s3OperationsPolicyTemplateId = formatDependentBucketPolicyId(s3OperationsTemplateId)]
    [#assign s3DataTemplateId = formatS3DataTemplateId()]
    [#assign s3DataPolicyTemplateId = formatDependentBucketPolicyId(s3DataTemplateId)]

    [@createS3Bucket
        mode=listMode
        id=s3OperationsTemplateId
        name=operationsBucket
        lifecycleRules=
            (operationsExpiration?is_number || operationsOffline?is_number)?then(
                    getS3LifecycleRule(operationsExpiration, operationsOffline, "AWSLogs") +
                    getS3LifecycleRule(operationsExpiration, operationsOffline, "CLOUDFRONTLogs") +
                    getS3LifecycleRule(operationsExpiration, operationsOffline, "DOCKERLogs"),
                []
            )
        outputId=s3OperationsId
    /]

    [#-- TODO(mfl): when Cloud Formation supports it, create an access identity for the segment --]
    [#-- For now it is created by the epilogue script for the cmk --]
    [#assign cfAccess =
        getExistingReference(formatDependentCFAccessId(s3OperationsId), CANONICAL_ID_ATTRIBUTE_TYPE)]
            
    [@createBucketPolicy
        mode=listMode
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
            ) +
            valueIfContent(
                s3ReadPermission(
                    operationsBucket,
                    formatSegmentPrefixPath("settings"),
                    "*",
                    {
                        "CanonicalUser": cfAccess
                    }
                )
                cfAccess,
                []
            )
        dependencies=s3OperationsTemplateId
    /]
    
    [@createS3Bucket
        mode=listMode
        id=s3DataTemplateId
        name=dataBucket
        lifecycleRules=
            (dataExpiration?is_number || dataOffline?is_number)?then(
                getS3LifecycleRule(dataExpiration, dataOffline),
                []
            )
        outputId=s3DataId
    /]

    [#if dataPublicEnabled ]
    
        [#assign dataPublicWhitelistCondition =
            getIPCondition(getGroupCIDRs(dataPublicIPAddressGroups, true)) ]

        [@createBucketPolicy
            mode=listMode
            id=s3DataPolicyTemplateId
            bucket=dataBucket
            statements=
                s3ReadPermission(
                    dataBucket,
                    formatSegmentPrefixPath("apppublic"),
                    "*",
                    "*",
                    dataPublicWhitelistCondition
                    
                )  
            dependencies=s3DataTemplateId
        /]
    [/#if]
    
    [#-- Legacy naming --]
    [#-- TODO: Remove --]
    [@cfOutput
        mode=listMode
        id=formatSegmentS3Id("ops", "template")
        value=s3OperationsTemplateId
    /]
    [@cfOutput
        mode=listMode
        id=formatSegmentS3Id("data", "template")
        value=s3DataTemplateId
    /]
    [#if s3OperationsId != s3OperationsTemplateId ]
        [@cfOutput
            mode=listMode
            id=formatSegmentS3Id("ops")
            value=
                {
                    "Ref" : s3OperationsTemplateId
                }
        /]
    [/#if]
    [#if s3DataId != s3DataTemplateId ]
        [@cfOutput
            mode=listMode
            id=formatSegmentS3Id("data")
            value=
                {
                    "Ref" : s3DataTemplateId
                }
        /]
    [/#if]
[/#if]

