[#ftl]
"Metadata" : {
    "RequestReference" : "${requestReference}",
    [#if accountObject.CostCentre?has_content]
        "CostCentre" : "${accountObject.CostCentre},
    [/#if]
    "ConfigurationReference" : "${configurationReference}",
    "Prepared" : "${.now?iso_utc}"
    [#if buildCommit?has_content]
        ,"BuildReference" : "${buildCommit}"
    [/#if]
    [#if appReference?has_content]
        ,"AppReference" : "${appReference}"
    [/#if]
}
