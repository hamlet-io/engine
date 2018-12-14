[#-- Events --]

[#assign EVENT_RULE_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : { 
            "Attribute" : "Arn"
        }
    }
]

[#assign outputMappings +=
    {
        AWS_EVENT_RULE_RESOURCE_TYPE : EVENT_RULE_OUTPUT_MAPPINGS
    }
]
[#macro createScheduleEventRule mode id 
        targetId 
        enabled 
        scheduleExpression 
        targetParameters
        dependencies="" ]
        
    [#if enabled ] 
        [#assign state = "ENABLED" ]
    [#else]
        [#assign state = "DISABLED" ]
    [/#if]
    
    [@cfResource
        mode=mode
        id=id
        type="AWS::Events::Rule"
        properties=
            {
                "ScheduleExpression" : scheduleExpression,
                "State" : state,
                "Targets" : asArray(targetParameters)
            }
        outputs=EVENT_RULE_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]
