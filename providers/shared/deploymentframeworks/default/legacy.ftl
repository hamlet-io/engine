[#ftl]

[#include "/occurrence.ftl"]
[#include "/link.ftl"]

[#macro processComponents level=""]
    [#local start = .now]
    [@timing message="Starting component processing ..." /]
    [#list tiers as tier]
        [#list (tier.Components!{}) as key, value]
            [#local component =
                {
                    "Id" : key,
                    "Name" : key
                } + value ]
            [#if deploymentRequired(component, deploymentUnit)]
                [#assign multiAZ = component.MultiAZ!solnMultiAZ]
                [#local occurrenceStart = .now]
                [#list requiredOccurrences(
                    getOccurrences(tier, component),
                    deploymentUnit,
                    true) as occurrence]
                    [#local occurrenceEnd = .now]
                    [@timing
                        message= "Got " + tier.Id + "/" + component.Id + " occurrences ..."
                        context=
                            {
                                "Elapsed" : (duration(occurrenceEnd, start)/1000)?string["0.000"],
                                "Duration" : (duration(occurrenceEnd, occurrenceStart)/1000)?string["0.000"]
                            }
                    /]

                    [@debug message=occurrence enabled=false /]

                    [#list occurrence.State.ResourceGroups as key,value]
                        [#if invokeSetupMacro(occurrence, key, ["setup", level]) ]
                            [@debug
                                message="Processing " + key + " ..."
                                enabled=false
                            /]
                        [/#if]
                    [/#list]
                    [#local processingEnd = .now]
                    [@timing
                        message="Processed " + tier.Id + "/" + component.Id + "."
                        context=
                            {
                                "Elapsed"  : (duration(processingEnd, start)/1000)?string["0.000"],
                                "Duration" : (duration(processingEnd, occurrenceEnd)/1000)?string["0.000"]
                            }
                    /]
                [/#list]
            [/#if]
        [/#list]
    [/#list]
    [@timing
        message="Finished component processing."
        context=
            {
                "Elapsed"  : (duration(.now, start)/1000)?string["0.000"]
            }
        /]
[/#macro]

