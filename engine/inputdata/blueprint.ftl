[#ftl]

[#-- Global Blueprint Object --]
[#assign blueprintObject = {}]

[#macro addBlueprint blueprint={} ]
    [#if blueprint?has_content ]
        [@interalMergeBlueprint
            blueprint=blueprint
        /]
    [/#if]
[/#macro]

[#-----------------------------------------------------
-- Internal support functions for blueprint processing --
-------------------------------------------------------]

[#macro interalMergeBlueprint blueprint ]
    [#assign blueprintObject =
        mergeObjects(
            blueprintObject,
            blueprint
        )
    ] 
[/#macro]