[#ftl]

[#--
Attribute extension

Attribute extension is designed to permit providers to supplement any attributes
defined in the shared provider. It is done in a way that permits multiple
providers to extend the attributes simultaneously, but with extensions specific
to the provider easily identified.

A provider has two options - enrich an existing attribute or add namespaced attributes.

** Attribute enrichment **

If the name of the extension matches one of the names of the existing attributes,
the attribute maintains its existing name, and the extension configuration is
merged with the existing attribute configuration.

Where the existing attribute has children, the extension is also expected to have
children and attribute extension is recursively applied to each child.

Where the extension provides possible values, any unique values are added to
the existing attribute values. By default these values are prefixed based on the
provided prefix attribute (a colon is used as a separator). However if the
extension value starts with the provided disablePrefix, the disablePrefix is stripped.
This allows a provider to contribute sharable as well as provider specific values.

If the extension provides a default value, it will be merged with any existing
value.

If the extension provides an attribute set, this overrides any children definition
currently on the existing attribute.

** Namespaced attribute addition **

If the extension names do not overlap those of the existing attributes, the extension
is added to the list of attributes. All the extension names has the provided prefix
added. Any Values or Default value are NOT prefixed, as they are defined within an
already prefixed attribute.

--]
[#function extendAttributes attributes=[] extensions=[] prefix="" disablePrefix="shared:" ]

    [#if ! extensions?has_content]
        [#-- Nothing to do --]
        [#return attributes]
    [/#if]

    [#local result = [] ]
    [#local prefix = prefix?ensure_ends_with(":") ]

    [#local attributes = expandCompositeConfiguration(attributes, true, false)]
    [#local extensions = expandCompositeConfiguration(extensions, true, false)]

    [#-- First extend existing attributes --]
    [#list asArray(attributes) as attribute]

        [#-- Check if any of the extensions have a name matching one of the existing attribute names --]
        [#local attributeExtensions =
            asArray(extensions)?filter(
                e ->
                    getArrayIntersection(
                        asArray(attribute.Names),
                        asArray(e.Names)
                    )?has_content
            )
        ]

        [#-- At most one extension should match the existing attribute --]
        [#if attributeExtensions?size > 1]
            [@warning
                message="Multiple attribute extensions match attribute"
                context={
                    "Attribute" : attribute,
                    "MatchingExtensions" : attributeExtensions
                }
            /]
        [/#if]

        [#if attributeExtensions?has_content]
            [#local attributeExtension = attributeExtensions?first]
            [#if (attribute.Children![])?has_content]
                [#-- Recursively extend child definitions --]
                [#if (attributeExtension.Children![])?has_content]
                    [#local result += [
                        mergeObjects(
                            attribute,
                            {
                                "Children" : extendAttributes(
                                                attribute.Children,
                                                attributeExtension.Children,
                                                prefix)
                            }
                        )
                    ]]
                [#else]
                    [@fatal
                        message="Attribute Extension missing children."
                        context={
                            "Attribute" : attribute,
                            "Extension" : attributeExtension
                        }
                    /]
                [/#if]
            [#else]

                [#local extendedAttributes = {}]
                [#local extendedValues = (attribute.Values)![]]

                [#-- Check for extra values --]
                [#list (attributeExtension.Values)![] as extensionValue]

                    [#if extensionValue?is_string ]
                        [#-- If extension value starts with the disable prefix, --]
                        [#-- value is shared so strip prefix, otherwise         --]
                        [#-- force extension value to be prefixed               --]
                        [#if prefix != disablePrefix ]
                            [#local extendedValues +=
                                [
                                    extensionValue?starts_with(disablePrefix)?then(
                                        extensionValue?remove_beginning(disablePrefix),
                                        extensionValue?ensure_starts_with(prefix)
                                    )
                                ]]
                        [#else]
                            [#local extendedValues +=
                                [
                                    extensionValue?remove_beginning(disablePrefix)
                                ]
                            ]
                        [/#if]
                    [#else ]
                        [#local extendedValues += extensionValue ]
                    [/#if]

                    [#-- At least one extended value so update the values list --]
                    [#local extendedAttributes += {
                        "Values" : getUniqueArrayElements(extendedValues)
                    }]

                [/#list]

                [#-- Check for different default --]
                [#if ((attributeExtension.Default)!"")?has_content ]
                    [#local extendedAttributes += {
                        "Default" : attributeExtension.Default
                    } ]
                [/#if]

                [#-- Extension has extra attributes defined via an attribute set --]
                [#if ((attributeExtension.AttributeSet)![])?has_content ]
                    [#local extendedAttributes += {
                        "AttributeSet" : attributeExtension.AttributeSet,
                        "Children" : []
                    }]
                [/#if]

                [#local result += [
                    mergeObjects(
                        attribute,
                        extendedAttributes
                    )]]
            [/#if]
        [#else]
            [#local result += [attribute]]
        [/#if]
    [/#list]

    [#-- Deal with any new attributes contributed by the extensions --]
    [#local additionalAttributes = [] ]
    [#list extensions as extension ]

        [#-- Check if the extension has a name matching one of the existing attribute names --]
        [#-- If it does, it will already have been processed                                --]
        [#if !
            asArray(attributes)?filter(
                a ->
                    getArrayIntersection(
                        asArray(extension.Names),
                        asArray(a.Names)
                    )?has_content
            )?has_content
        ]
            [#-- The provided extension names will be prefixed. Any values or default are --]
            [#-- NOT prefixed given that the extension names are prefixed.                --]
            [#local additionalAttributes +=
                addPrefixToAttributes(
                    [ extension ],
                    prefix,
                    true,
                    false,
                    false
                )
            ]
        [/#if]
    [/#list]
    [#local result += additionalAttributes ]

    [#return result]
[/#function]
