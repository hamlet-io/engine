[#-- SES ruleset --]
[#if getCLODeploymentUnit()?contains("sesruleset") || (groupDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets=["template", "epilogue"] /]
    [/#if]

    [#if ! (accountObject["aws:SES"].RuleSet.Name)?has_content]
        [@fatal message="The aws:SES.RuleSet.Name attribute is required in the account object" /]
    [#else]

        [#if deploymentSubsetRequired("epilogue", false) ]
            [@addToDefaultBashScriptOutput
                content=
                    [
                        "case $\{STACK_OPERATION} in",
                        "  create|update)",
                        "   info \"Setting active rule set to " + accountObject["aws:SES"].RuleSet.Name + "\"",
                        "   setActiveSESRuleSet" + " " +
                            regionId + " " +
                            accountObject["aws:SES"].RuleSet.Name + " || return $?"
                        "   ;;",
                        " esac"
                    ]
            /]
        [/#if]

        [#if deploymentSubsetRequired("sesruleset", true) ]
            [@includeServicesConfiguration
                provider=AWS_PROVIDER
                services=[AWS_SIMPLE_EMAIL_SERVICE ]
                deploymentFramework=getCLODeploymentFramework()
            /]

            [@createSESReceiptRuleSet
                id=formatSESReceiptRuleSetId()
                name=accountObject["aws:SES"].RuleSet.Name
            /]

            [#-- Add any required IP Address filtering --]
            [#if getGroupCIDRs(accountObject["aws:SES"].IPAddressGroups, true, occurrence, true)]
                [#list (getGroupCIDRs(accountObject["aws:SES"].IPAddressGroups, true, occurrence))?filter(cidr -> cidr?has_content) as cidr ]
                    [@createSESReceiptIPFilter
                        id=formatSESReceiptFilterId(replaceAlphaNumericOnly(cidr,"X"))
                        name=formatName("account", replaceAlphaNumericOnly(cidr,"-"))
                        cidr=cidr
                    /]
                [/#list]

                [#-- Add a default block all rule --]
                [@createSESReceiptIPFilter
                        id=formatSESReceiptFilterId("0X0X0X0X0")
                        name=formatName("account", "0-0-0-0-0")
                        cidr="0.0.0.0/0"
                        allow=false
                    /]
            [/#if]
        [/#if]
    [/#if]
[/#if]
