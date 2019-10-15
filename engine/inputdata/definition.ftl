[#ftl]

[#-- External definition files for components (API Specifications) --]
[#assign definitionsObject = {} ]

[#macro addDefinition definition={} ]
    [#if definition?has_content ]
        [@interalMergeDefinition
            definition=definition
        /]
    [/#if]
[/#macro]

[#-----------------------------------------------------
-- Internal support functions for blueprint processing --
-------------------------------------------------------]

[#macro interalMergeDefinition definition ]
    [#assign definitionsObject =
        mergeObjects(
            definitionsObject,
            definition
        )
    ] 
[/#macro]