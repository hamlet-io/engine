[#ftl]

[@addComponentDeployment
    type=SERVICE_REGISTRY_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=SERVICE_REGISTRY_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "DNS based service registry"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
            }
        ]
    attributes=
        [
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Namespace",
                "Children" : domainNameChildConfiguration
            }
        ]
/]

[@addChildComponent
    type=SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "An individual service in the registry"
            }
        ]
    attributes=
        [
            {
                "Names" : "ServiceName",
                "Description" : "The hostname portion of the DNS record which will identify this service",
                "Children" : hostNameChildConfiguration
            },
            {
                "Names" : "RecordTypes",
                "Description" : "The types of DNS records that an instance can register with the service",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Values" : [ "A", "AAAA", "CNAME", "SRV" ],
                "Default" : [ "A" ]
            },
            {
                "Names" : "RecordTTL",
                "Description" : "DNS record TTL ( in seconds)",
                "Types" : NUMBER_TYPE,
                "Default" : 300
            },
            {
                "Names" : "RoutingPolicy",
                "Description" : "How the service returns records to the client",
                "Values" : [ "AllAtOnce", "OnlyOne" ],
                "Types" : STRING_TYPE,
                "Default" : "OnlyOne"
            }
        ]
    parent=SERVICE_REGISTRY_COMPONENT_TYPE
    childAttribute="RegistryServices"
    linkAttributes="RegistryService"
/]
