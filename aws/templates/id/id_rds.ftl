[#-- RDS --]

[#-- Resources --]

[#assign RDS_RESOURCE_TYPE = "rds" ]
[#assign RDS_SUBNET_GROUP_RESOURCE_TYPE = "rdsSubnetGroup" ]
[#assign RDS_PARAMETER_GROUP_RESOURCE_TYPE = "rdsParameterGroup" ]
[#assign RDS_OPTION_GROUP_RESOURCE_TYPE = "rdsOptionGroup" ]

[#function formatRDSId tier component extensions...]
    [#return formatComponentResourceId(
                RDS_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatRDSSubnetGroupId tier component extensions...]
    [#return formatComponentResourceId(
                RDS_SUBNET_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatRDSParameterGroupId tier component extensions...]
    [#return formatComponentResourceId(
                RDS_PARAMETER_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatRDSOptionGroupId tier component extensions...]
    [#return formatComponentResourceId(
                RDS_OPTION_GROUP_RESOURCE_TYPE,
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

