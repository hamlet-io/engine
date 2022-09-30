[#ftl]

[@addDynamicValueProvider
    type=IPADDRESSGROUP_DYNAMIC_VALUE_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Returns the resolved CIDR Addresses from IPAddressGroups defined in the solution"
        }
    ]
    parameterOrder=[
        "groupId"
    ]
    parameterAttributes=[
        {
            "Names" : "groupId",
            "Description" : "The Id of the IPAddressGroups",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]

[#function shared_dynamicvalue_ipaddressgroup value properties sources={} ]
    [#if sources.occurrence?? ]
        [#local cidrs = getGroupCIDRs(properties.groupId, true, occurrence)]
        [#return cidrs!"__HamletWarning: IP Address group ${groupId} could not be resolved__" ]
    [/#if]
[/#function]
