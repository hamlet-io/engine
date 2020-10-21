[#ftl]

[#-- Service Resource Configuration provides a lookup service for details about resources that have beeb loaded --]
[#-- Resources are stored under a provider and service and allow for their own sections for different configuration groups --]
[#-- These macros can be extended by other providers to add their own resource configuration --]

[#assign serviceResourceConfiguration = {}]

[#-- Query functions --]
[#function getServiceResourceSection provider service resource section ]
    [#return (serviceResourceConfiguration[provider][service]["resources"][resource][section])!{} ]
[/#function]

[#function getServiceSection provider service section ]
    [#return (serviceResourceConfiguration[provider][service][section])!{} ]
[/#function]

[#function getServiceResources provider service  ]
    [#return ((serviceResourceConfiguration[provider][service]["resources"])?keys)![] ]
[/#function]

[#function getServices provider ]
    [#return ((serviceResourceConfiguration[provider])?keys)![]]
[/#function]

[#function getServiceFromResource provider resource ]
    [#list getServices(provider) as service ]
        [#list getServiceResources(provider, service) as svcResource ]
            [#if svcResource ==  resource ]
                [#return service ]
            [/#if]
        [/#list]
    [/#list]
    [#return ""]
[/#function]

[#-- resource --]
[#macro addServiceResource provider service resource ]
    [@addServiceResourceSection
        provider=provider
        service=service
        resource=resource
        section="present"
        configuration={
            "present" : true
        }
    /]
[/#macro]

[#macro addServiceResourceSection provider service resource section configuration ]
    [@internalMergeServiceResourceConfiguration
        provider=provider
        service=service
        resource=resource
        section=section
        configuration=configuration
    /]
[/#macro]

[#-- service --]
[#macro addService provider service ]
    [@addServiceSection
        provider=provider
        service=service
        section="present"
        configuration={
            "present" : true
        }
    /]
[/#macro]

[#macro addServiceSection provider service section configuration ]
    [@internalMergeServiceConfiguration
        provider=provider
        service=service
        section=section
        configuration=configuration
    /]
[/#macro]


[#-- Internal Macros for processing --]
[#macro internalMergeServiceConfiguration provider service section configuration={} ]
    [#if section == "resources" ]
        [@fatal
            message="Invalid Service Section Name"
            detail="Provide another section heading name"
        /]
    [/#if]
    [#assign serviceResourceConfiguration =
        mergeObjects(
            serviceResourceConfiguration,
            {
                provider : {
                    service : {
                        section : configuration
                    }
                }
            }
        )]
[/#macro]

[#macro internalMergeServiceResourceConfiguration provider service resource section configuration={} ]
    [#assign serviceResourceConfiguration =
        mergeObjects(
            serviceResourceConfiguration,
            {
                provider : {
                    service : {
                        "resources" : {
                            resource : {
                                section : configuration
                            }
                        }
                    }
                }
            }
        )]
[/#macro]
