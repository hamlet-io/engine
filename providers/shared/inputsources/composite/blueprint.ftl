[#ftl]

[#-- Intial seeding of settings data based on input data --]
[#macro shared_input_composite_blueprint_seed ]
    [@addBlueprint
        blueprint=
            mergeObjects(
                getCMDBTenantBlueprint(),
                getCMDBAccountBlueprint(),
                getCMDBProductBlueprint()
            )
    /]
[/#macro]
