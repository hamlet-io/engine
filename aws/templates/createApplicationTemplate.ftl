[#ftl]
[#include "setContext.ftl"]

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    [#assign compositeList=[applicationList]]
    "Resources" : {
        [#assign applicationListMode="definition"]
        [#include "componentList.ftl"]
    },

    "Outputs" : {
        [#assign applicationListMode="outputs"]
        [#include "componentList.ftl"]
    }
}

