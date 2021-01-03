[#ftl]

[@addExtension
    id="esfilter"
    aliases=[
        "filter",
        "_filter"
    ]
    description=[
        "Elasticsearch Authentication filter",
        "Provides a basic Authentiation filter for public AWS ES indexes"
    ]
    supportedTypes=[
        ECS_SERVICE_COMPONENT_TYPE,
        ECS_TASK_COMPONENT_TYPE,
        CONTAINERSERVICE_COMPONENT_TYPE,
        CONTAINERTASK_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_esfilter_deployment_setup occurrence ]

    [#-- DATA and QUERY credentials (USERNAME, PASSWORD) expected in env --]
    [#-- TODO(mfl): change container to use standard ES atributes --]

    [#local esLinkId = (_context.DefaultEnvironment["ES_LINK_ID"])!"es" ]
    [#local esLink = _context.Links[esLinkId]]
    [#local esFQDN = esLink.State.Attributes["FQDN"]]
    [#local esPort = esLink.State.Attributes["PORT"]]

    [@Attributes image="esfilter" /]

    [@Variables
        {
            "CONFIGURATION" : _context.DefaultEnvironment?json_string,
            "ES" : esFQDN + ":" + esPort
        }
    /]

[/#macro]
