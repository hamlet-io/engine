[#case "couchdb"]
    [#-- COUCHDB credentials (USER, PASSWORD) expected in env --]

    [@Attributes image="couchdb" /]

    [@Volume "couchdb" "/usr/local/var/lib/couchdb" "/codeontap/couchdb" /]
    
    [#break]

