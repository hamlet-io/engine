[#ftl]
[#macro shared_input_mock_masterdata_seed ]
    [@addMasterData
        data=
            {
                "Regions": {
                    "mock-region-1": {
                        "Locality": "MockLand",
                        "Zones": {
                            "a": {
                                "Title": "Zone A"
                            },
                            "b": {
                                "Title": "Zone C"
                            }
                        }
                    }
                }
            }
    /]
[/#macro]
