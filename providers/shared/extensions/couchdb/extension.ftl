[#ftl]

[@addExtension
    id="couchdb"
    aliases=[
        "_couchdb"
    ]
    description=[
        "Basic CouchDB installation"
    ]
    supportedTypes=[
        ECS_SERVICE_COMPONENT_TYPE,
        ECS_TASK_COMPONENT_TYPE,
        CONTAINERSERVICE_COMPONENT_TYPE,
        CONTAINERTASK_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_couchdb_deployment_setup occurrence ]

    [#-- COUCHDB credentials (USER, PASSWORD) expected in env --]
    [@Settings
        {
            "COUCHDB_USER" : (_context.DefaultEnvironment["COUCHDB_USER"])!"HamletFatal: Please provider user env",
            "COUCHDB_PASSWORD" : (_context.DefaultEnvironment["COUCHDB_PASSWORD"])!"HamletFatal: Please provider password env"
        }
    /]
    [@Attributes image="couchdb" /]
    [@Volume "couchdb" "/usr/local/var/lib/couchdb" "/codeontap/couchdb" /]

[/#macro]
