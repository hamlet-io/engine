[#ftl]

[@addDynamicValueProvider
    type=BASELINE_DYNAMIC_VALUE_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Returns the attribute of a baseline component"
        }
    ]
    parameterOrder=["BaselineComponentName", "AttributeName"]
    parameterAttributes=[
        {
            "Names" : "BaselineComponentName",
            "Description" : "The Name of the baseline component name",
            "Types" : STRING_TYPE,
            "Values" : [
                "OpsData",
                "AppData",
                "Encryption",
                "SSHKey"
            ],
            "Mandatory" : true
        },
        {
            "Names" : "AttributeName",
            "Description" : "The name of the attribute on the link",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

[#function shared_dynamicvalue_baseline value properties sources={} ]

    [#if sources.occurrence?? ]
        [#local baselineLink = (getBaselineLinks(sources.occurrence, [properties.BaselineComponentName ])[properties.BaselineComponentName])!{}]

        [#if baselineLink?has_content && baselineLink.State.Attributes[properties.AttributeName]?? ]
            [#return (baselineLink.State.Attributes[properties.AttributeName])!"__HamletWarning: attribute ${properties.AttributeName} not found for baseline component ${properties.BaselineComponentName}__" ]
        [/#if]
    [/#if]
[/#function]
