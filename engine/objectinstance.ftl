[#ftl]

[#----------------------------------------------------------
-- Gather public functions for ObjectInstances processing --
-----------------------------------------------------------]

[#function findPublicFunctions]
    [#local publicFunctions =
        getPluginTree(
            "/providers/shared/objectinstance/",
            {
                "Regex" : [r"fn\.ftl"],
                "AddEndingWildcard" : false,
                "MinDepth" : 1,
                "MaxDepth" : 1,
                "FilenameGlob" : r"fn.ftl"
            }
        )
    ]
    [#return publicFunctions?sort_by("Path")]
[/#function]

[#local files = findPublicFunctions()]
[#list files as file]
    [#include "/providers/shared/objectinstance/"+file.Path+"/"+file.File]
[/#list]
