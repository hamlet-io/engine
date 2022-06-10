[#ftl]

[@addDynamicValueProvider
    type=ATTRIBUTE_DYNAMIC_VALUE_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Returns the attribute of a link configured under the components Links"
        }
    ]
    parameterOrder=["linkId", "attributeName"]
    parameterAttributes=[
        {
            "Names" : "linkId",
            "Description" : "The Id of the link to get the attribute from",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "attributeName",
            "Description" : "The name of the attribute on the link",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
    supportedComponentTypes=["*"]
/]

[#function shared_dynamicvalue_attribute value properties occurrence extraSources={} ]

    [#local link = (occurrence.Configuration.Solution.Links[properties.linkId])!{}]
    [#local linkTarget = getLinkTarget(occurrence, link)]

    [#if ! linkTarget?has_content ]
        [@fatal
            message="Link could not be found for attribute"
            context={
                "Step"  : occurrence.Core.Component.RawId,
                "LinkId" : properties.linkId,
                "Links" : occurrence.Configuration.Solution.Links
            }
        /]
    [/#if]

    [#return (linkTarget.State.Attributes[properties.attributeName])!"" ]
[/#function]
