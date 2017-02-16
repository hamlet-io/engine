[#ftl]
[#include "setContext.ftl"]

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    "Resources" : {
        [#assign sliceCount = 0]        
        [#assign segmentListMode="definition"]
        [#include segmentList]                      
    },
    "Outputs" : 
    {
        [#assign sliceCount = 0]
        [#assign segmentListMode="outputs"]
        [#include segmentList]
    }
}






