[#-- RDS --]

[#-- Resources --]

[#function formatRDSId tier component extensions...]
    [#return formatComponentResourceId(
                "rds",
                tier,
                component,
                extensions)]
[/#function]

[#function formatRDSSubnetGroupId tier component extensions...]
    [#return formatComponentResourceId(
                "rdsSubnetGroup",
                tier,
                component,
                extensions)]
[/#function]

[#function formatRDSParameterGroupId tier component extensions...]
    [#return formatComponentResourceId(
                "rdsParameterGroup",
                tier,
                component,
                extensions)]
[/#function]

[#function formatRDSOptionGroupId tier component extensions...]
    [#return formatComponentResourceId(
                "rdsOptionGroup",
                tier,
                component,
                extensions)]
[/#function]

[#-- Attributes --]

[#function formatRDSDnsId resourceId]
    [#return formatDnsAttributeId(resourceId)]
[/#function]

[#function formatRDSPortId resourceId]
    [#return formatPortAttributeId(resourceId)]
[/#function]

[#function formatRDSDatabaseNameId resourceId]
    [#return formatDatabaseNameAttributeId(resourceId)]
[/#function]

[#-- Outputs --]

[#macro outputRDSDns resourceId]
    [@outputAtt
        formatRDSDnsId(resourceId)
        resourceId
        "Endpoint.Address" /]
[/#macro]

[#macro outputRDSPort resourceId]
    [@outputAtt
        formatRDSPortId(resourceId)
        resourceId
        "Endpoint.Port" /]
[/#macro]

[#macro outputRDSDatabaseName resourceId value]
    [@outputValue
        formatRDSDatabaseNameId(resourceId)
        value /]
[/#macro]

