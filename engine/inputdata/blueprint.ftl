[#ftl]

[#-- Global Blueprint Object --]
[#assign blueprintObject = {}]

[#macro addBlueprint blueprint={} ]
    [#if blueprint?has_content ]
        [@internalMergeBlueprint
            blueprint=blueprint
        /]
    [/#if]
[/#macro]

[#-----------------------------------------------------
-- Internal support functions for blueprint processing --
-------------------------------------------------------]

[#macro internalMergeBlueprint blueprint ]
    [#assign blueprintObject =
        mergeObjects(
            blueprintObject,
            blueprint
        )
    ]
[/#macro]
