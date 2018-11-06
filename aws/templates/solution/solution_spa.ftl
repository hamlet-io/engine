[#-- Single Page App --]

[#if componentType == SPA_COMPONENT_TYPE]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign resources = occurrence.State.Resources]
        [#assign solution = occurrence.Configuration.Solution ]

        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript
                mode=listMode
                content=(getExistingReference(cfId)?has_content)?then(
                    [
                        "case $\{STACK_OPERATION} in",
                        "  create|update)"
                    ] +
                    [
                        "# Invalidate distribution",
                        "info \"Invalidating cloudfront distribution ... \"",
                        "invalidate_distribution" +
                        " \"" + region + "\" " +
                        " \"" + getExistingReference(cfId) + "\" || return $?"

                    ] +
                    [
                        "       ;;",
                        "       esac"
                    ],
                    []
                )
            /]
        [/#if]
    [/#list]
[/#if]
