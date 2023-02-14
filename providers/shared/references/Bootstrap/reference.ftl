[#ftl]

[#-- Searches by Index attribute, then by object key --]
[#function getBootstrapByIndex index returnEmpty=true]

    [#local bootstraps = getReferenceData(BOOTSTRAP_REFERENCE_TYPE, true)]
    [#local result = {}]
    [#local result += bootstraps?values?filter(x -> x.Index?has_content && x.Index == index)[0]!{}]
    [#if !(result?has_content)]
        [#local result += bootstraps[index]!{}]
    [/#if]

    [#if result?has_content || returnEmpty]
        [#return result]
    [#else]
        [@fatal
            message="Bootstrap Index not found"
            context={"Index" : index, "Bootstraps" : bootstraps}
        /]
    [/#if]
[/#function]
