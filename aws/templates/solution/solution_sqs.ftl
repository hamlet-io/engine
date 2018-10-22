[#-- SQS --]
[#if (componentType == SQS_COMPONENT_TYPE) && deploymentSubsetRequired("sqs", true)]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#assign sqsId = resources["queue"].Id ]
        [#assign sqsName = resources["queue"].Name ]
        [#assign dlqId = resources["dlq"].Id ]
        [#assign dlqName = resources["dlq"].Name ]

        [#assign dlqRequired =
            isPresent(solution.DeadLetterQueue) ||
            ((environmentObject.Operations.DeadLetterQueue.Enabled)!false)]
        [#if dlqRequired]
            [@createSQSQueue
                mode=listMode
                id=dlqId
                name=dlqName
                retention=1209600
                receiveWait=20
            /]
        [/#if]
        [@createSQSQueue
            mode=listMode
            id=sqsId
            name=sqsName
            delay=solution.DelaySeconds
            maximumSize=solution.MaximumMessageSize
            retention=solution.MessageRetentionPeriod
            receiveWait=solution.ReceiveMessageWaitTimeSeconds
            visibilityTimout=solution.VisibilityTimeout
            dlq=valueIfTrue(dlqId, dlqRequired, "")
            dlqReceives=
                valueIfTrue(
                  solution.DeadLetterQueue.MaxReceives,
                  solution.DeadLetterQueue.MaxReceives > 0,
                  (environmentObject.Operations.DeadLetterQueue.MaxReceives)!3)
        /]

    [/#list]
[/#if]
