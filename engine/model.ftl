[#ftl]
[#-- Model Engine --]
[#-- The model defines a data layout that the engine creates from the various input sources --]
[#-- Models implement scopes that represent a specifc portion of the data --]
[#-- Each scope is defined as part of the engine and models implement the scope based on the engine deinfed schema to ensure compatability --]

[#assign COMPONENTS_MODEL_SCOPE = "components" ]
[#assign VIEW_MODEL_SCOPE = "view" ]

[#macro processModelScope framework model scope level="" ]
    [#local macroOptions =
        [
            [framework, "model", model, "scope", scope ]
        ]
    ]

    [#local macro = getFirstDefinedDirective(macroOptions)]
    [#if macro?has_content]
        [@(.vars[macro]) level=level /]
    [#else]
        [@debug
            message="Unable to invoke any of the macro options"
            context=macroOptions
            enabled=false
        /]
    [/#if]
[/#macro]
