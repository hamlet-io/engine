[#ftl]

[@addExtension
    id="noenv"
    aliases=[
        "_noenv"
    ]
    description=[
        "Disables all standard Environment variables"
    ]
    supportedTypes=[
        "*"
    ]
/]

[#macro shared_extension_noenv_setup occurrence ]

    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]
    [@DefaultBaselineVariables enabled=false /]

[/#macro]
