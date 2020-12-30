[#ftl]

[#-- Global Blueprint Object --]
[#assign blueprintObject = {}]

[#macro addBlueprint blueprint={} ]
    [#if blueprint?has_content ]
        [@internalMergeBlueprint
            base=blueprintObject
            blueprint=blueprint
        /]
    [/#if]
[/#macro]

[#macro rebaseBlueprint base={} ]
    [#if base?has_content ]
        [@internalMergeBlueprint
            base=base
            blueprint=blueprintObject
        /]
    [/#if]
[/#macro]

[#-----------------------------------------------------
-- Internal support functions for blueprint processing --
-------------------------------------------------------]

[#macro internalMergeBlueprint base blueprint ]
    [#assign blueprintObject =
        mergeObjects(
            base,
            blueprint
        )
    ]
[/#macro]
