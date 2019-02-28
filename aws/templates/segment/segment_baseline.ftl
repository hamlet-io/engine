[#-- Baseline Component --]
[#if componentType == BASELINE_COMPONENT_TYPE ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#assign segmentSeedId = resources["segmentSeed"].Id ]
        [#if !(getExistingReference(segmentSeedId)?has_content) ]
            
            [#if legacyVpc ]
                [#assign segmentSeedValue = vpc?remove_beginning("vpc-")]
            [#else]
                [#assign segmentSeedValue = ( runId + accountObject.Seed)[0..(solution.Seed.Length - 1)]  ]
            [/#if]

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

        [#if (resources["segmentSNSTopic"]!{})?has_content ]
            [#assign topicId = resources["segmentSNSTopic"].Id ]
            [#if deploymentSubsetRequired(BASELINE_COMPONENT_TYPE, true)]
                [@createSegmentSNSTopic
                    mode=listMode
                    id=topicId
                /]
            [/#if]
        [/#if]


    [/#list]
[/#if]
