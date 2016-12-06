[#ftl]
{
    "Credentials" : {
        "alm" : {
            "LDAP" : {
                "UserDN" : "uid=alm@${accountId}.gosource.com.au,dc=gosource,dc=com,dc=au",
                "Password" : "${ldapPassword}"
            },
            "Bind" : {
                "BindDN" : "cn=alm,ou=${accountId},ou=accounts,ou=${tenantId},ou=organisations,dc=gosource,dc=com,dc=au",
                "Password" : "${bindPassword}"
            }
        }
    }
}
