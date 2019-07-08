[#ftl]
[#macro aws_topic_cf_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets="template" /]
        [#return]
    [/#if]

    [#local parentCore = occurrence.Core]
    [#local parentSolution = occurrence.Configuration.Solution]
    [#local parentResources = occurrence.State.Resources]

    [#local topicId = parentResources["topic"].Id ]
    [#local topicName = parentResources["topic"].Name ]

    [#-- Baseline component lookup --]
    [#local baselineComponentIds = getBaselineLinks(parentSolution.Profiles.Baseline, [ "Encryption" ] )]
    [#local cmkKeyId = baselineComponentIds["Encryption"] ]

    [#if deploymentSubsetRequired(TOPIC_COMPONENT_TYPE, true)]
        [@createSNSTopic 
            id=topicId 
            name=topicName 
            encrypted=parentSolution.Encrypted
            kmsKeyId=cmkKeyId
            fixedName=parentSolution.FixedName
        /]
    [/#if]

    [#list occurrence.Occurrences![] as subOccurrence]

        [#local core = subOccurrence.Core ]
        [#local solution = subOccurrence.Configuration.Solution ]
        [#local resources = subOccurrence.State.Resources ]
        
        [#switch core.Type]

            [#case TOPIC_SUBSCRIPTION_COMPONENT_TYPE  ]
                [#local subscriptionId = resources["subscription"].Id ]

                [#local links = solution.Links ]
                [#local protocol = solution.Protocol]

                [#list links as linkId,link]
                
                    [#local linkTarget = getLinkTarget(occurrence, link) ]

                    [@debug message="Link Target" context=linkTarget enabled=false /]

                    [#if !linkTarget?has_content]
                        [#continue]
                    [/#if]

                    [#local linkTargetCore = linkTarget.Core ]
                    [#local linkTargetConfiguration = linkTarget.Configuration ]
                    [#local linkTargetResources = linkTarget.State.Resources ]
                    [#local linkTargetAttributes = linkTarget.State.Attributes ]

                    [#local endpoint = ""]
                    [#local deliveryPolicy = {}]
                    
                    [#switch linkTargetCore.Type ]
                        [#case "external" ]
                            [#local endpoint = linkTargetAttributes["SUBSCRIPTION_ENDPOINT"] ]
                            [#local protocol = linkTargetAttributes["SUBSCRIPTION_PROTOCOL"] ]

                            [#if ! endpoint?has_content && ! protocol?has_content ]
                                [@fatal
                                    message="Subscrption protocol or endpoints not found"
                                    context=link
                                    detail="External link Attributes Required SUBSCRIPTION_ENDPOINT - SUBSCRIPTION_PROTOCOL"
                                /]
                            [/#if]
                            [#break]
                    [/#switch]

                    [#if ! endpoint?has_content && ! protocol?has_content ]
                        [@fatal
                            message="Subscrption protocol or endpoints not found"
                            context=link
                            detail="Could not determine protocol and endpoint for link"
                        /]
                    [/#if]
                    

                    [#switch protocol ]
                        [#case "http"]
                        [#case "https" ]
                            [#local deliveryPolicy = getSNSDeliveryPolicy(solution.DeliveryPolicy) ]
                            [#break]
                    [/#switch]

                    [#if deploymentSubsetRequired(TOPIC_COMPONENT_TYPE, true)]
                        [@createSNSSubscription 
                            id=subscriptionId
                            topicId=topicId 
                            endpoint=endpoint
                            protocol=solution.Protocol
                            rawMessageDelivery=solution.RawMessageDelivery 
                            deliveryPolicy=deliveryPolicy
                        /]
                    [/#if]                    
                [/#list]
                [#break]
        [/#switch]
    [/#list]
[/#macro]