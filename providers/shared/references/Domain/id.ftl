[#ftl]

[#-- Domain Roles --]
[#-- Primary is used on component attributes --]
[#assign DOMAIN_ROLE_PRIMARY="primary" ]
[#-- Secondaries allow a smooth transition from one domain to another --]
[#assign DOMAIN_ROLE_SECONDARY="secondary" ]

[@addReference
    type=DOMAIN_REFERENCE_TYPE
    pluralType="Domains"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Represents a segment of a domain name"
            }
        ]
    attributes=[
        {
            "Names" : "Name",
            "Description" : "The name of the domain",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Stem",
            "Description" : "The root stem domain name that children will be based on",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Zone",
            "Description" : "The zone the endpoint belongs to",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Bare",
            "Description" : "Use the name value of the domain as the full domain name value",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "Role",
            "Types" : STRING_TYPE,
            "Values" : [
                DOMAIN_ROLE_PRIMARY,
                DOMAIN_ROLE_SECONDARY
            ]
        },
        {
            "Names" : [ "Parents", "Parent" ],
            "Description" : "The parent of this domain segment",
            "Types" : ARRAY_OF_STRING_TYPE
        }
    ]
/]


[#function isPrimaryDomain domainObject]
    [#return domainObject.Role == DOMAIN_ROLE_PRIMARY ]
[/#function]

[#function isSecondaryDomain domainObject]
    [#return domainObject.Role == DOMAIN_ROLE_SECONDARY ]
[/#function]

[#function getDomainObjects certificateObject ]
    [#local result = [] ]
    [#local primaryNotSeen = true]

    [#local lines = getObjectLineage(
        addIdNameToObjectAttributes(
            getReferenceData(DOMAIN_REFERENCE_TYPE)
        ),
        (certificateObject.Domain)!"") ]

    [#list lines as line]
        [#local name = "" ]
        [#local role = DOMAIN_ROLE_PRIMARY ]
        [#list line as domainObject]
            [#if !(domainObject.Bare) ]
                [#local name = formatDomainName(
                                   contentIfContent(
                                       domainObject.Stem!"",
                                       contentIfContent(
                                           domainObject.Name!"",
                                           ""
                                       )
                                   ),
                                   name
                               ) ]
            [/#if]
            [#if domainObject.Role?? && domainObject.Role?has_content]
                [#local role = domainObject.Role]
            [/#if]
        [/#list]

        [#local result +=
            [
                getCompositeObject(
                    getReferenceConfiguration(DOMAIN_REFERENCE_TYPE).Attributes,
                    line
                    + [
                        {
                            "Name" : name,
                            "Role" : valueIfTrue(role, primaryNotSeen, DOMAIN_ROLE_SECONDARY)
                        }
                    ])
            ] ]
        [#local primaryNotSeen = primaryNotSeen && (role != DOMAIN_ROLE_PRIMARY) ]
    [/#list]

    [#-- Force first entry to primary if no primary seen --]
    [#if primaryNotSeen && (result?size > 0) ]
        [#local forcedResult = [ result[0] + { "Role" : DOMAIN_ROLE_PRIMARY } ] ]
        [#if (result?size > 1) ]
            [#local forcedResult += result[1..] ]
        [/#if]
        [#local result = forcedResult]
    [/#if]

    [#-- Add any domain inclusions --]
    [#local includes = certificateObject.IncludeInDomain!{} ]
    [#if includes?has_content]
        [#local hostParts = certificateObject.HostParts ]
        [#local parts = [] ]

        [#list hostParts as part]
            [#if includes[part]!false]
                [#switch part]
                    [#case "Segment"]
                        [#local parts += [segmentName!""] ]
                        [#break]
                    [#case "Environment"]
                        [#local parts += [environmentName!""] ]
                        [#break]
                    [#case "Product"]
                        [#local parts += [productName!""] ]
                        [#break]
                [/#switch]
            [/#if]
        [/#list]

        [#local extendedResult = [] ]
        [#list result as entry]
            [#local extendedResult += [
                    entry +
                    {
                        "Name" : formatDomainName(parts, entry.Name)
                    }
                ] ]
        [/#list]
        [#local result = extendedResult]
    [/#if]

    [#return result]
[/#function]
