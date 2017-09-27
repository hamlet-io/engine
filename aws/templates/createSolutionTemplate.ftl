[#ftl]
[#level = "solution"]
[#include "setContext.ftl"]

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    [#assign compositeLists=[solutionList]]
    "Resources" : {
        [#assign solutionListMode="definition"]
        [#include "componentList.ftl"]
    },
    
    "Outputs" : {
        [#assign solutionListMode="outputs"]
        [#include "componentList.ftl"]
        [@cfTemplateGlobalOutputs /]
    }
}
