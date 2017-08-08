[#-- EIPs --]
[#if deploymentUnit?contains("eip")]
    [#assign mgmtTier = getTier("mgmt")]
    [#if natEnabled]
        [#list zones as zone]
            [#if natPerAZ || zone?is_first]
                [@createEIP
                    segmentListMode,
                    formatComponentEIPId(mgmtTier, "nat", zone) /]
            [/#if]
        [/#list]
    [/#if]
    [#if sshEnabled && sshStandalone]
        [@createEIP
            segmentListMode,
            formatComponentEIPId(mgmtTier, "ssh") /]
    [/#if]
[/#if]

