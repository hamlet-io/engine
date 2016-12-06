[#ftl]
"Metadata" : {
    "RequestReference" : "${requestReference}",
    "ConfigurationReference" : "${configurationReference}",
    "Prepared" : "${.now?iso_utc}"
    [#if buildCommit??]
        ,"BuildReference" : "${buildCommit}"
    [/#if]
    [#if appReference?? && (appReference != "")]
        ,"AppReference" : "${appReference}"
    [/#if]
}
