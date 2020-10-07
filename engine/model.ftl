[#ftl]
[#-- Models and Flows--]
[#-- Before processing a flow you can use the model to define a common data structure or setup across multiple flows --]
[#-- Flows provide a path throught the hamlet engine to generate an output --]
[#-- Flows can be used to generate multiple outputs and essentially perform preprocessing of hamlet input data to reduce duplication across multiple output types --]

[#assign COMPONENTS_MODEL_FLOW = "components" ]
[#assign VIEW_MODEL_FLOW = "view" ]

[#macro processModelFlow framework model flow level="" ]
    [#local macroOptions =
        [
            [framework, "model", model, "flow", flow ],
            [DEFAULT_DEPLOYMENT_FRAMEWORK, "model", model, "flow", flow ]
        ]
    ]

    [#local macro = getFirstDefinedDirective(macroOptions)]
    [#if macro?has_content]
        [@(.vars[macro]) level=level /]
    [#else]
        [@fatal
            message="Unable to invoke any of the model flow macro options"
            context=macroOptions
            enabled=false
        /]
        [#stop "HamletFatal: Unable to invoke any of the model flow macro options" ]
    [/#if]
[/#macro]
