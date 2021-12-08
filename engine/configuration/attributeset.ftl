[#ftl]

[#assign ATTRIBUTESET_CONFIGURATION_SCOPE = "AttributeSet" ]

[@addConfigurationScope
    id=ATTRIBUTESET_CONFIGURATION_SCOPE
    description="Shared configuration that can be used across configurations"
/]

[#macro addAttributeSet type properties attributes]

    [@addConfigurationSet
        scopeId=ATTRIBUTESET_CONFIGURATION_SCOPE
        id=type
        attributes=attributes
        properties=properties
    /]

[/#macro]

[#macro addExtendedAttributeSet baseType provider type properties attributes ]
    [#local baseAttributeSetConfig = getAttributeSet(baseType)]
    [#if ! (baseAttributeSetConfig?has_content)  ]
        [@fatal
            message="Could not find base attribute set to extend"
            detail="Ensure the attribute set is available or you are using a provider that is available"
            context={
                "BaseType" : baseType,
                "Type" : type,
                "Provider" : provider
            }
        /]
    [/#if]

    [#local extendedAttributes = extendAttributes(baseAttributeSetConfig.Attributes, attributes, provider)]

    [@addAttributeSet
        type=type
        properties=properties
        attributes=extendedAttributes
    /]
[/#macro]

[#function getAttributeSet type ]
    [#return getConfigurationSet(ATTRIBUTESET_CONFIGURATION_SCOPE, type)]
[/#function]

[#function getAttributeSetIds ]
    [#return getConfigurationSetIds(ATTRIBUTESET_CONFIGURATION_SCOPE)]
[/#function]

[#function getAttributeSets ]
    [#local result = {}]

    [#list getConfigurationSets(ATTRIBUTESET_CONFIGURATION_SCOPE) as configurationSet]
        [#local result = mergeObjects(
            result, {
                configurationSet.Id : {
                    "Properties" : configurationSet.Properties,
                    "Attributes" : configurationSet.Attributes
                }
            }
        )]
    [/#list]

    [#return result]
[/#function]
