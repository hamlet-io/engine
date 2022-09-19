[#ftl]

[@addComponent
    type=MOBILEAPP_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "mobile apps with over the air update hosting"
            }
        ]
    attributes=
        [
            {
                "Names" : "AppFrameworks",
                "Description": "A list of app frameworks used to generate the app",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : ["expo"],
                "Values" : ["expo"]
            },
            {
                "Names" : "AppFrameworks:expo",
                "Description": "Expo specific configuration",
                "Children" : [
                    {
                        "Names": "ReleaseChannel",
                        "Description": "The release channel of the app",
                        "Types": STRING_TYPE,
                        "Default": "__setting:ENVIRONMENT__"
                    },
                    {
                        "Names": "IdOverride",
                        "Description": "Override the existing id used in the expo app",
                        "Types": STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names": "EncryptionPrefix",
                "Description": "A prefix appended to any encrypted values in the solution configuration",
                "Default": "base64:"
            },
            {
                "Names": "VersionSource",
                "Description": "How to determine the version Id of the app",
                "Types": STRING_TYPE,
                "Values" : ["AppFrameworks", "AppReference"],
                "Default" : "AppFrameworks"
            },
            {
                "Names" : "BuildFormats",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "ios", "android" ],
                "Values" : [ "ios", "android" ]
            },
            {
                "Names" : "BuildFormats:ios",
                "Description": "IOS specific distribution configuration",
                "Children" : [
                    {
                        "Names": "ProjectRootDir",
                        "Description": "Within the src code image the path to the root of the ios project",
                        "Types": STRING_TYPE,
                        "Default": "ios"
                    },
                    {
                        "Names": "BundleIdOverride",
                        "Description" : "An override of the app bundle Id",
                        "Types" : STRING_TYPE
                    }
                    {
                        "Names": "DisplayNameOverride",
                        "Description": "An override value for the display name",
                        "Types": STRING_TYPE
                    },
                    {
                        "Names": "NonExemptEncryption",
                        "Description": "Does the app use non-exempt encryption",
                        "Types": BOOLEAN_TYPE,
                        "Default": false
                    },
                    {
                        "Names": "CodeSignIdentityPrefix",
                        "Description": "The prefix of code signing identity from the distribution certificate",
                        "Types": STRING_TYPE,
                        "Values": [ "iPhone Distribution", "Apple Distribution"],
                        "Default": "iPhone Distribution"
                    },
                    {
                        "Names": "AppleTeamId",
                        "Description": "The id of the apple developer team the app will be signed for",
                        "Types": STRING_TYPE
                    },
                    {
                        "Names": "ExportMethod",
                        "Description": "The method of distribution for the signed app",
                        "Types": STRING_TYPE,
                        "Values": [ "app-store", "ad-hoc", "enterprise", "developer" ],
                        "Default": "app-store"
                    },
                    {
                        "Names" : "TestFlight",
                        "Description": "The configuration for TestFlight uploads when using AppStore export",
                        "Children" : [
                            {
                                "Names" : "Enabled",
                                "Description" : "Enable upload to TestFilght - requires app-store ExportMethod",
                                "Types": BOOLEAN_TYPE,
                                "Default": true
                            },
                            {
                                "Names": "AppId",
                                "Description": "The Id of the app in app store connect",
                                "Types": STRING_TYPE
                            },
                            {
                                "Names": "Username",
                                "Description": "The username of the testflight user for the upload",
                                "Types": STRING_TYPE
                            },
                            {
                                "Names": "Password",
                                "Description": "The password of the testflight user for the upload",
                                "Types": STRING_TYPE
                            }
                        ]
                    },
                    {
                        "Names": "DistributionCertificateFileName",
                        "Description": "The file name of the distribution certificate stored in the asFile settings",
                        "Types": STRING_TYPE,
                        "Default": "ios_distribution.p12"
                    },
                    {
                        "Names": "DistributionCertificatePassword",
                        "Description": "The password used to unlock the distribution certificate file",
                        "Types": STRING_TYPE
                    },
                    {
                        "Names": "ProvisioningProfileFileName",
                        "Description": "The file name of the provisioning profile stored in the asFile settings",
                        "Types": STRING_TYPE,
                        "Default": "ios_profile.mobileprovision"
                    }
                ]
            },
            {
                "Names" : "BuildFormats:android",
                "Children" : [
                    {
                        "Names": "ProjectRootDir",
                        "Description": "Within the src code image the path to the root of the android project",
                        "Types": STRING_TYPE,
                        "Default": "android"
                    },
                    {
                        "Names" : "BundleIdOverride",
                        "Description" : "An override of the app bundle Id",
                        "Types": STRING_TYPE
                    }
                    {
                        "Names" : "KeyStore",
                        "Description": "Configuration of the keystore used to sign the app",
                        "Children" : [
                            {
                                "Names": "FileName",
                                "Description": "The file name of the keystore stored in the asFile settings",
                                "Types": STRING_TYPE,
                                "Default": "android_keystore.jks"
                            }
                            {
                                "Names" : "Password",
                                "Description": "The password required to unlock the keystore",
                                "Types" : STRING_TYPE
                            },
                            {
                                "Names" : "KeyAlias",
                                "Description": "The alias of the key in the keystore to use for signing the app",
                                "Types" : STRING_TYPE
                            },
                            {
                                "Names": "KeyPassword",
                                "Description": "The password required to unlock the key",
                                "Types" : STRING_TYPE
                            }
                        ]
                    },
                    {
                        "Names" : "PlayStore",
                        "Description": "Configuration for uploading the app to the Google Playstore",
                        "Children" : [
                            {
                                "Names": "Enabled",
                                "Description": "Enable PlayStore upload",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : false
                            },
                            {
                                "Names" : "JSONKeyFileName",
                                "Description": "The filename of the JSON Key stored in asFile settings used to authenticate with the PlayStore",
                                "Types" : STRING_TYPE,
                                "Default" : "playstore_json_key.json"
                            }
                        ]
                    },
                    {
                        "Names" : "Firebase",
                        "Description": "Configuration for uploading the app to Firebase",
                        "Children" : [
                            {
                                "Names": "Enabled",
                                "Description": "Enable Firebase upload",
                                "Types": BOOLEAN_TYPE,
                                "Default": false
                            },
                            {
                                "Names": "AppId",
                                "Description": "The Id of the app in Firebase to use for uploading the signed app",
                                "Types": STRING_TYPE
                            },
                            {
                                "Names": "JSONKeyFileName",
                                "Types": STRING_TYPE,
                                "Description": "The filename of the JSON Key stored in asFile settings used to authenticate with Firebase",
                                "Default": "firebase_json_key.json"
                            }
                        ]
                    },
                    {
                        "Names": "GoogleServices",
                        "Description": "Service configuration for access to google push services",
                        "Children" : [
                            {
                                "Names": "JSONKeyFileName",
                                "Types" : STRING_TYPE,
                                "Description": "The filename of the JSON Key stored in asFile settings used to authenticate with Firebase",
                                "Default" : "google-services.json"
                            }
                        ]
                    }
                ]
            },
            {
                "Names": "Badge",
                "Description": "Adds a badge to the app icon",
                "Children" : [
                    {
                        "Names": "Enabled",
                        "Description": "Enable adding badge to app icons",
                        "Types": BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "Value",
                        "Description": "The value in  the badge",
                        "Types": STRING_TYPE,
                        "Default": "__setting:ENVIRONMENT__"
                    },
                    {
                        "Names": ["Color", "Colour"],
                        "Description": "The colour of the badgethe badge",
                        "Types": STRING_TYPE,
                        "Values": [
                            "brightgreen",
                            "green",
                            "yellow",
                            "orange",
                            "red",
                            "blue",
                            "lightgrey"
                        ],
                        "Default": "blue"
                    }
                ]
            },
            {
                "Names": [ "Extensions", "Fragment", "Container" ],
                "Description": "Extensions to invoke as part of component processing",
                "Types": ARRAY_OF_STRING_TYPE,
                "Default": []
            },
            {
                "Names" : "Image",
                "Description" : "Control the source of the image for the mobile ota source zip image",
                "Children" : [
                    {
                        "Names" : "Source",
                        "Description" : "The source of the image - registry: the local hamlet registry - url: an external public url",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true,
                        "Values" : [ "link", "registry", "url" ],
                        "Default" : "registry"
                    },
                    {
                        "Names" : "Source:url",
                        "Description" : "Url Source specific Configuration",
                        "Children" : [
                            {
                                "Names" : "Url",
                                "Description" : "The Url to a zip file containing the mobile app source",
                                "Types" : STRING_TYPE
                            },
                            {
                                "Names" : "ImageHash",
                                "Description" : "The expected sha1 hash of the Url if empty any will be accepted",
                                "Types" : STRING_TYPE,
                                "Default" : ""
                            }
                        ]
                    },
                    {
                        "Names": "Link",
                        "Description" : "The link to an image",
                        "AttributeSet": LINK_ATTRIBUTESET_TYPE
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=MOBILEAPP_COMPONENT_TYPE
    defaultGroup="application"
/]
