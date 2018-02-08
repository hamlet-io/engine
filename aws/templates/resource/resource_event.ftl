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
        EVENT_RULE_RESOURCE_TYPE : EVENT_RULE_OUTPUT_MAPPINGS
    }
]

[#macro createScheduleEventRule mode id targetId state="ENABLED" scheduleExpression="rate(15 minutes)" dependencies=""]
    [@cfResource
        mode=mode
        id=id
        type="AWS::Events::Rule"
        properties=
            {
                "ScheduleExpression" : scheduleExpression,
                "State" : state,
                "Targets" : [{
                    "Arn" : getReference(targetId, ARN_ATTRIBUTE_TYPE),
                    "Id" : targetId
                }]
            }
        outputs=EVENT_RULE_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]
