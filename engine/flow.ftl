[#ftl]
[#-- Flows--]
[#-- Flows can be used to generate multiple outputs and essentially perform preprocessing of hamlet input data to reduce duplication across multiple output types --]

[#macro processFlows framework flows level="" ]
    [#list asArray(flows) as flow ]
        [#local macroOptions =
            [
                [ framework, "flow", flow ],
                [ DEFAULT_DEPLOYMENT_FRAMEWORK, "flow", flow ]
            ]
        ]

        [#local macro = getFirstDefinedDirective(macroOptions)]
        [#if macro?has_content]
            [@(.vars[macro]) level=level /]
        [#else]
            [@fatal
                message="Unable to invoke any of the flow macro options"
                context=macroOptions
                enabled=false
            /]
            [#stop "HamletFatal: Could not locate flow: ${flow}" ]
        [/#if]
    [/#list]
[/#macro]
