[#-- Baseline Component --]
[#if componentType == BASELINE_COMPONENT_TYPE ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#-- make sure we only have one occurence --]
        [#if  core.Tier.Id == "mgmt" &&
                core.Component.Id == "baseline" && 
                core.Version.Id == "" && 
                core.Instance.Id == "" ]
            
            [#-- Segment Seed --]
            [#assign segmentSeedId = resources["segmentSeed"].Id ]
            [#if !(getExistingReference(segmentSeedId)?has_content) ]
                
                [#assign segmentSeedValue = resources["segmentSeed"].Value]

                [#if deploymentSubsetRequired("prologue", false)]
                    [@cfScript
                        mode=listMode
                        content=
                        [
                            "case $\{STACK_OPERATION} in",
                            "  create|update)"
                        ] +
                        pseudoStackOutputScript(
                                "Seed Values",
                                { segmentSeedId : segmentSeedValue },
                                "seed"
                        ) +
                        [            
                            "       ;;",
                            "       esac"
                        ]
                    /]
                [/#if]
            [/#if]

            [#-- Monitoring Topic --]
            [#if (resources["segmentSNSTopic"]!{})?has_content ]
                [#assign topicId = resources["segmentSNSTopic"].Id ]
                [#if deploymentSubsetRequired(BASELINE_COMPONENT_TYPE, true)]
                    [@createSegmentSNSTopic
                        mode=listMode
                        id=topicId
                    /]
                [/#if]
            [/#if]

            [#-- Subcomponents --]
            [#list occurrence.Occurrences![] as subOccurrence]

                [#assign subCore = subOccurrence.Core ]
                [#assign subSolution = subOccurrence.Configuration.Solution ]
                [#assign subResources = subOccurrence.State.Resources ]

                [#-- Storage bucket --]
                [#if subCore.Type == BASELINE_DATA_COMPONENT_TYPE ]
                    [#assign bucketId = subResources["bucket"].Id ]
                    [#assign bucketName = subResources["bucket"].Name ]
                    [#assign bucketPolicyId = subResources["bucketpolicy"].Id ]
                    [#assign legacyS3 = subResources["bucket"].LegacyS3 ]

                    [#if ( deploymentSubsetRequired(BASELINE_COMPONENT_TYPE, true) && legacyS3 == false ) || 
                        ( deploymentSubsetRequired("s3") && legacyS3 == true) ]

                        [#assign lifecycleRules = [] ]
                        [#list subSolution.Lifecycles?values as lifecycle ]
                            [#assign lifecycleRules += 
                                getS3LifecycleRule(lifecycle.Expiration, lifecycle.Offline, lifecycle.Prefix)]
                        [/#list]

                        [#assign sqsNotifications = [] ]
                        [#assign sqsNotificationIds = [] ]
                        [#assign bucketDependencies = [] ]

                        [#list subSolution.Notifications!{} as id,notification ]
                            [#if notification?is_hash]
                                [#list notification.Links?values as link]
                                    [#if link?is_hash]
                                        [#assign linkTarget = getLinkTarget(subOccurrence, link, false) ]
                                        [@cfDebug listMode linkTarget false /]
                                        [#if !linkTarget?has_content]
                                            [#continue]
                                        [/#if]

                                        [#assign linkTargetResources = linkTarget.State.Resources ]

                                        [#switch linkTarget.Core.Type]
                                            [#case AWS_SQS_RESOURCE_TYPE ]
                                                [#if isLinkTargetActive(linkTarget) ]
                                                    [#assign sqsId = linkTargetResources["queue"].Id ]
                                                    [#assign sqsNotificationIds = [ sqsId ]]
                                                    [#list notification.Events as event ]
                                                        [#assign sqsNotifications +=
                                                                getS3SQSNotification(sqsId, event, notification.Prefix, notification.Suffix) ]
                                                    [/#list]
                                                    
                                                [/#if]
                                                [#break]
                                        [/#switch]
                                    [/#if]
                                [/#list]
                            [/#if]
                        [/#list]

                        [#list sqsNotificationIds as sqsId ]
                            [#assign sqsPolicyId =
                                formatS3NotificationsQueuePolicyId(
                                    bucketId,
                                    sqsId) ]
                            [@createSQSPolicy
                                    mode=listMode
                                    id=sqsPolicyId
                                    queues=sqsId
                                    statements=sqsS3WritePermission(sqsId, bucketName)
                                /]
                            [#assign bucketDependencies += [sqsPolicyId] ]
                        [/#list]

                        [@createS3Bucket
                            mode=listMode
                            id=bucketId
                            name=bucketName
                            versioning=subSolution.Versioning
                            lifecycleRules=lifecycleRules
                            sqsNotifications=sqsNotifications
                            dependencies=bucketDependencies
                        /]
                                    
                        [#-- role based bucket policies --]
                        [#assign bucketPolicy = []]
                        [#switch subSolution.Role ]
                            [#case "operations" ]
                                [#assign cfAccess =
                                    getExistingReference(formatDependentCFAccessId(bucketId), CANONICAL_ID_ATTRIBUTE_TYPE)]
                                
                                [#assign bucketPolicy += 
                                    s3WritePermission(
                                        bucketName,
                                        "AWSLogs",
                                        "*",
                                        {
                                            "AWS": "arn:aws:iam::" + regionObject.Accounts["ELB"] + ":root"
                                        }
                                    ) +
                                    s3ReadBucketACLPermission(
                                        bucketName,
                                        { "Service": "logs." + regionId + ".amazonaws.com" }
                                    ) +
                                    s3WritePermission(
                                        bucketName,
                                        "",
                                        "*",
                                        { "Service": "logs." + regionId + ".amazonaws.com" },
                                        { "StringEquals": { "s3:x-amz-acl": "bucket-owner-full-control" } }
                                    ) +
                                    valueIfContent(
                                        s3ReadPermission(
                                            bucketName,
                                            formatSegmentPrefixPath("settings"),
                                            "*",
                                            {
                                                "CanonicalUser": cfAccess
                                            }
                                        )
                                        cfAccess,
                                        []
                                    )]
                                [#break]
                            [#case "appdata" ] 
                                [#if dataPublicEnabled ]
        
                                    [#assign dataPublicWhitelistCondition =
                                        getIPCondition(getGroupCIDRs(dataPublicIPAddressGroups, true)) ]

                                    [#assign bucketPolicy += s3ReadPermission(
                                                bucketName,
                                                formatSegmentPrefixPath("apppublic"),
                                                "*",
                                                "*",
                                                dataPublicWhitelistCondition
                                            )]
                                [/#if]
                                [#break]
                        [/#switch]
        
                        [#if bucketPolicy?has_content ]
                            [@createBucketPolicy
                                mode=listMode
                                id=bucketPolicyId
                                bucket=bucketName
                                statements=bucketPolicy
                                dependencies=bucketId
                            /]
                        [/#if]
                    [/#if]            
                [/#if]
            [/#list]

        [#else]
            [@cfException
                mode=listMode
                description="The baseline component can only be deployed once as an unversioned component"
                context=core
            /]
            [#break]

        [/#if]
    [/#list]
[/#if]
