[#ftl]
[#include "setContext.ftl"]

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    "Resources" : {
        [#assign resourceCount = 0]
        [#assign segmentListMode="definition"]
        [#include segmentList]                      
    },
    "Outputs" : 
    {
        [#assign resourceCount = 0]
        [#assign segmentListMode="outputs"]
        [#include segmentList]
    }
}






