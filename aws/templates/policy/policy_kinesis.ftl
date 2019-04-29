[#function firehoseStreamProducePermission id] 
    [#return 
        getPolicyStatement(
            [
                "firehose:DeleteDeliveryStream",
                "firehose:PutRecord",
                "firehose:PutRecordBatch",
                "firehose:UpdateDestination"
            ],
            getReference(id, ARN_ATTRIBUTE_TYPE)
        )
    ]
[/#function]