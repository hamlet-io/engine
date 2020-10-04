[#ftl]
[#include "/bootstrap.ftl" ]

[#assign documentSetType = commandLineOptions.DocumentSet.Type ]
[#assign documentSet = getDocumentSet(documentSetType) ]

[#-- Validate Command line options are right for the document set --]
[#assign validCommandLineOptions = getCompositeObject(documentSet.Configuration, commandLineOptions) ]

[#-- Determine the document sets for the provider --]
[#list providerMarkers as providerMarker ]
    [#-- aws/documentsets/documentset.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "documentsets", documentSetType],
        [ "documentset" ]
    /]
[/#list]
