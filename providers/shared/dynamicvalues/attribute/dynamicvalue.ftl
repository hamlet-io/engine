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
/]

[#function shared_dynamicvalue_attribute value properties sources={} ]

    [#if sources.occurrence?? ]
        [#local link = (sources.occurrence.Configuration.Solution.Links[properties.linkId])!{}]
        [#local linkTarget = getLinkTarget(sources.occurrence, link)]

        [#if ! linkTarget?has_content ]
            [@fatal
                message="Link could not be found for attribute"
                context={
                    "Step"  : sources.occurrence.Core.Component.RawId,
                    "LinkId" : properties.linkId,
                    "Links" : sources.occurrence.Configuration.Solution.Links
                }
            /]
        [/#if]

        [#return (linkTarget.State.Attributes[properties.attributeName])!"" ]
    [/#if]
    [#return "__${vaule}__"]
[/#function]
