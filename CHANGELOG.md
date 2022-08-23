# Changelog

## latest (2022-08-23)

#### New Features

* (baseline): add extension support for data ([#2028](https://github.com/hamlet-io/engine/issues/2028))
* (port): add enable for port healthcheck ([#2030](https://github.com/hamlet-io/engine/issues/2030))
* (entrance): stackoutput entrance
* add support for topic and queue extensions
* tasks and extensions for images in runbooks
* (image): add support for the image component
* (lambda): lambda alias ([#2015](https://github.com/hamlet-io/engine/issues/2015))
* add support for dynamic value evaulation
* (correspondent): add  support for channel configuration
* (lb): add enable support for conditions
#### Fixes

* (dn): Test for missing domain name ([#2008](https://github.com/hamlet-io/engine/issues/2008))
* (dynamicinput): error message text ([#2027](https://github.com/hamlet-io/engine/issues/2027))
* set buildblueprint output file name ([#2026](https://github.com/hamlet-io/engine/issues/2026))
* schema entrance output filename ([#2025](https://github.com/hamlet-io/engine/issues/2025))
* typo for deployment test
* (output): output prefix handling
* typo in dynamicvalue return
* (dynamicvalue): remove fatal on missing link
* update naming for source
* correct private key property name ([#2017](https://github.com/hamlet-io/engine/issues/2017))
* (dynamicvalue): fix typo in configuration scope
* (dynamicvalue): resolve handling for lists ([#2013](https://github.com/hamlet-io/engine/issues/2013))
* comment update
* handle empty values or object references
#### Refactorings

* (runbook): support dynamic values in conditions
* remove occurrence dependency and apply at the occurrence level
#### Others

* (lambda): update lambda runtime versions ([#2031](https://github.com/hamlet-io/engine/issues/2031))

Full set of changes: [`8.6.2...latest`](https://github.com/hamlet-io/engine/compare/8.6.2...latest)

## 8.6.2 (2022-06-07)

#### Fixes

* lb link lookup
#### Refactorings

* use shared changelog workflow
#### Others

* update changelog ([#2004](https://github.com/hamlet-io/engine/issues/2004))
* changelog bump
* changelog bump

Full set of changes: [`8.6.0...8.6.2`](https://github.com/hamlet-io/engine/compare/8.6.0...8.6.2)

## 8.6.0 (2022-05-25)

#### New Features

* (lb): define backends indepdent from port mappings
* (cdn): add priority to cdn routes
* tagging control for occurrences
* (logstore): add engine parameter support
* (logstore): add dedicated log storage component
* (datastream): define data stream component
* (lambda): chg constraint on runtime to warning
* (lambda): remove constraint on runtime
* (lambda): versioned lambda retention policy ([#1989](https://github.com/hamlet-io/engine/issues/1989))
* (alerts): add enable attribute on alerts
* add docdb support ([#1934](https://github.com/hamlet-io/engine/issues/1934))
* (lb): define external or internal for lb endpoints
* (lambda): provisioned executions ([#1980](https://github.com/hamlet-io/engine/issues/1980))
* (dnszone): add support for network based configuration
* add certificate authority component
* add build details entrance for image reference info
* (datavolume): zone control and remove backups
* (cdn): add support for disabling event handlers
* add support for HealthCheck Protocol
* (ec2): add support for zone based deploy control
#### Fixes

* add generation contract for unitlist view
* (runbook): don't include disabled tasks
* only include active layers based on district type
* (account): minor fixes for account level aws deployments
* (firewall): rename type attribute on firewall rules
* support regions in state that use refs
* minor version upgrade control
* typo
* typos in attributes
#### Refactorings

* (apigateway): authorization models ([#1995](https://github.com/hamlet-io/engine/issues/1995))
* testing output handling and test profiles
* move functions out of setContext
* update testing to remove solution layer
* remove solution layer
* move multiAZ to standard component configuraiton

Full set of changes: [`8.5.0...8.6.0`](https://github.com/hamlet-io/engine/compare/8.5.0...8.6.0)

## 8.5.0 (2022-03-25)

#### New Features

* max-age control on bucket content ([#1953](https://github.com/hamlet-io/engine/issues/1953))
* add inputinfo entrance
* add null value cleaner to input stages
* (adaptor): add support for alert configuration
* full names based on district
* (ecs): add support for default task compute provider
* add support for using local docker volumes for builds
* (directory): support for log forwarding
* (datafeed): compression control for buckets
* (globaldb): add alerts support
* (backup): Backup support ([#1921](https://github.com/hamlet-io/engine/issues/1921))
* (legacy): add encryption at rest support for logs
* add account layer control over logging
* add logging profile support for encryption at rest
* (tasks): add basic tasks
* (ses): add control over IP access policy
* (tasks): extend ssh tasks and add bash command
* (ecs): add initprocess support for containers
* (cdn): add origin connection timeout support
#### Fixes

* district type for district lookup
* include account in mock filter layers
* encryption of logs for sms
* use raw path for settings path prefix
* Apply suggestions from code review
* (apigateway): handling of null values in definitions
* prefix handling for shared provider
* (lb): add required logging profile to lb ([#1925](https://github.com/hamlet-io/engine/issues/1925))
* module lookup process
* include component settings in environment
* (cdn): add logging profile
* (cd): engine install
* domain parent handling
#### Refactorings

* asfile ordering ([#1955](https://github.com/hamlet-io/engine/issues/1955))
* use local engine definition for testing
* hamlet and dind docker extensions
* update deployment group district handling
* rename district to district type
* remove task containers from shared provider
* consolidate link functions
* remove type based attributes from healthchecks
* (s3): use recommended process for bucket policy
* (district): use attributeset for config
* more specific name part config
* bootstrap clo processing
* backup encryption key ([#1927](https://github.com/hamlet-io/engine/issues/1927))
* (backup): Configuration options ([#1926](https://github.com/hamlet-io/engine/issues/1926))
* Account descriptions and placement profiles ([#1916](https://github.com/hamlet-io/engine/issues/1916))
* attributesets for components
* move domain and certificate to reference data
#### Others

* changelog bump ([#1906](https://github.com/hamlet-io/engine/issues/1906))
* update runtimes for lambda environment

Full set of changes: [`8.4.0...8.5.0`](https://github.com/hamlet-io/engine/compare/8.4.0...8.5.0)

## 8.4.0 (2022-01-06)

#### New Features

* (schema): add base level description
* add ssh copy file and rename ssh run
* add provider details runbook extension
* runbook extension for region
* (baseline): add encryption scheme for ssh key
* add tasks for an ssh bastion connection
* add conditional stage task
* add contract as output suffix for testing
* add shared placement profile
* add testing for runbook generation
* internaltest state control
* add runbook entrances
* (contract): add contract status for skip
* runbook value attribute set
* add runbook component
* configuration updates
* (ecs): add settings for containers
* custom build script lookup
* (lambda): add and layer jar image support ([#1891](https://github.com/hamlet-io/engine/issues/1891))
* add support for hiding the generation contract
* add component configuration scope
* composite configuration compression
* LinkRef support for container LB references ([#1889](https://github.com/hamlet-io/engine/issues/1889))
* add additional setting properties
* add support for component level config settings
* configuration details entrance
* add a standard configuration store
* add support for new lambda versions on inline
* add raw setting namepsaces
* (s3): add enable on notifications
* set waf default to v1
* add ref attribute to template
* wafv2
* wafv2
* (kinesis): ErrorType in prefix ([#1868](https://github.com/hamlet-io/engine/issues/1868))
* (kinesis): Prefix time path control ([#1867](https://github.com/hamlet-io/engine/issues/1867))
* add gpu support for containers
* add support for referencing db secrets
* add rootCredential source configuration
* (ecs): add support for secrets in containers
* add support for components in info output
* (topic): add link support and policy migration ([#1859](https://github.com/hamlet-io/engine/issues/1859))
* add filter policies to topic subscriptions ([#1850](https://github.com/hamlet-io/engine/issues/1850))
* outbound mta
* (lb): add alert configurations for lb ports
* (externalnetwork): set startup action for vpn
* skip image pull during generation
* add inside tunnel config support
* add named ip address groups
* (externalnetwork): SharedKey and BGP Peer
* client vpn component
* include layer and reference in info
* extend testing tooling
* (lb): condition support for lb ports
* (locations): location support
* (base): null detection in base routines
* subscription, hostingplatform, dnszone components
* (av): separate av computer task
#### Fixes

* (schema): handle array of type in schemas
* (schema): handle multiple types for attribute
* description typo
* placements and test properties
* use configuration scopes for schemasets
* scope name for component configuration
* (schema): attributes which are not hashes ([#1893](https://github.com/hamlet-io/engine/issues/1893))
* composite object default attribute processing ([#1892](https://github.com/hamlet-io/engine/issues/1892))
* duplicate field in schema file names
* Extension defaults handling ([#1890](https://github.com/hamlet-io/engine/issues/1890))
* s3 versioning without lifecycle management ([#1884](https://github.com/hamlet-io/engine/issues/1884))
* function call for moudle configuraiton
* reverse orphaned priority order
* remove aws fn from extension config
* ensure orphaned deployments are always first
* description
* incorporate feedback
* incorporate feedback
* orphan deployment detection
* remove missing var check
* handle missing deployment unit
* set maintenance window defaults
* (healthcheck): attribute typo
* (healthcheck): rename type attribute
* wording typo
* hanlding of 0/0 cidr in ip addr groups
* condition on setting global variables
* (cdn): include links in route config
* link matching to suboccurrences
* set default to standard schema
* (user): remove scheme restriction
* flow legacy lambda handling
* remove dns resource group on cdn
* ResourceGroup existence checking
#### Refactorings

* align testing with new format
* (runbook): value handling with substitution
* check image source before overriding image
* remove implicit Enabled attribute ([#1898](https://github.com/hamlet-io/engine/issues/1898))
* JSON Schema generation process
* update entrance and tasks
* format json schema document on output
* ensure the extensions are invoked all the time
* update setup routines to use new configuration
* remove plurals from attribute sets
* migrate configuration sources to shared config
* remove the region layer
* mta rules for send process
* pseudo stack outputs ([#1869](https://github.com/hamlet-io/engine/issues/1869))
* use secret string attribute
* create secretstring attributeset
* update schema to standard config
* create standard resource group attrs
* use eval_json for json loading
* (efs): rename to fileshare
* base and deployment attributes
* remove the id based typing of components
* (directory): rename default username
* (cd): use env for hamlet engine ([#1831](https://github.com/hamlet-io/engine/issues/1831))
* ensure provider known
* permit transition for fragments
* setContext wrapper functions (1)
* remove use of dos2unix
* (directory): set default ip access policy
* district support
* unique namespace for locations
* occurrence logging
* location data in occurrence
* enforce resource group registration
#### Others

* changelog bump ([#1812](https://github.com/hamlet-io/engine/issues/1812))
* fix attribute description spelling
* add comment on priority setup
* add winrm ports to masterdata
* improve error reporting
* correct attribute description
* changelog bump ([#1731](https://github.com/hamlet-io/engine/issues/1731))

Full set of changes: [`8.3.0...8.4.0`](https://github.com/hamlet-io/engine/compare/8.3.0...8.4.0)

## 8.3.0 (2021-09-17)

#### New Features

* (firewall): routing destination support
* (ds): New Component - Directory Services ([#1796](https://github.com/hamlet-io/engine/issues/1796))
* add a correspondent component ([#1793](https://github.com/hamlet-io/engine/issues/1793))
* (lb): add support for setting a default rule
* (linkref): initial implementation ([#1788](https://github.com/hamlet-io/engine/issues/1788))
* Support regex in qualification filters ([#1789](https://github.com/hamlet-io/engine/issues/1789))
* adds zone based lookup for tiers
* add Hostname as an alternate to Certificate
* add logging profiles and typo fix
* add http header filter
* add priority and inspection set
* add firewall component
* extend exception on setting lookup
* add interface attribute type
* port protocol to IANA mapping
* (network): dns query logging
* Add standard date functions and (optional) MaintenanceWindow to RDS ([#1741](https://github.com/hamlet-io/engine/issues/1741))
* set districts for deployment groups
* template output suffixes for mapping
* (districts): Initial implementation
#### Fixes

* whatif state processing ([#1802](https://github.com/hamlet-io/engine/issues/1802))
* annotated qualification ([#1790](https://github.com/hamlet-io/engine/issues/1790))
* remove unused var
* permit the mocking of empty values ([#1754](https://github.com/hamlet-io/engine/issues/1754))
* handle missing domains on products
* allow for multiple module loads
* swagger 2.0 top level security removal
* get attributes from plugin set
* handle tests across sub components deployment
* duplicate fragment processing
* district assignments on groups
* minor updates to account units
* include suboccurrences when generate tests
* qualification of layer data ([#1730](https://github.com/hamlet-io/engine/issues/1730))
#### Refactorings

* remove last of component qualifiers ([#1801](https://github.com/hamlet-io/engine/issues/1801))
* cloudfront header extension handling
* (cache): attribute descriptions
* warnings for occurrence links
* use SubComponent in links ([#1792](https://github.com/hamlet-io/engine/issues/1792))
* namespace qualifier attributes ([#1791](https://github.com/hamlet-io/engine/issues/1791))
* multi-value build references ([#1787](https://github.com/hamlet-io/engine/issues/1787))
* wildcard behaviour of getCompositeObject ([#1786](https://github.com/hamlet-io/engine/issues/1786))
* rename complex check type
* remove global security for openapi 2 ([#1743](https://github.com/hamlet-io/engine/issues/1743))
* add attribute sets for plugin/modules
* handle non segment districts in flows
* clo/layer access during input processing ([#1735](https://github.com/hamlet-io/engine/issues/1735))

Full set of changes: [`8.2.1...8.3.0`](https://github.com/hamlet-io/engine/compare/8.2.1...8.3.0)

## 8.2.1 (2021-07-09)

#### Fixes

* (ci): tag trigger support in pipeline ([#1732](https://github.com/hamlet-io/engine/issues/1732))

Full set of changes: [`8.2.0...8.2.1`](https://github.com/hamlet-io/engine/compare/8.2.0...8.2.1)

## 8.2.0 (2021-07-09)

#### New Features

* releaseinfo entrance
* define registries on the Account Layer
* typed full name
* subcomponent linking
* s3 flowlog expiration ([#1715](https://github.com/hamlet-io/engine/issues/1715))
* migrate testing to github workflows
* (template): add parameter extension macro ([#1701](https://github.com/hamlet-io/engine/issues/1701))
* input qualification ([#1695](https://github.com/hamlet-io/engine/issues/1695))
* add management port configuration to compute
* (ecs): extend placement strategy support
* set SES inbound active ruleset ([#1694](https://github.com/hamlet-io/engine/issues/1694))
* add support for packaging
* (dataset): adds support for image config
* (datapipeline): image source configuration
#### Fixes

* typos and refactorings
* occurrence cache
* default tagging
* (ci): default tag for images
* use workspace for engine dir
* storage profile volume configuration
* changelog generation
* align casing for bootstrap configuration
* (ci): add pull request trigger
* merge config from input seeders by default
* handle missing profiles
* typo in profile name
* getDomainObjects parameters
#### Refactorings

* remove context flow ([#1724](https://github.com/hamlet-io/engine/issues/1724))
* (ci): quality of life updates
* (ci): remove git and binaries from docker
* remove direct references to region ([#1716](https://github.com/hamlet-io/engine/issues/1716))
* add 1.15.1 of the wrapper ([#1719](https://github.com/hamlet-io/engine/issues/1719))
* (ci): updates from testing and ops
* only assemble settings in pregen
* set explicit typed profile attributes
* standardise profile lookups
* remove explicit qualification support ([#1696](https://github.com/hamlet-io/engine/issues/1696))
#### Others

* changelog bump ([#1718](https://github.com/hamlet-io/engine/issues/1718))

Full set of changes: [`8.1.2...8.2.0`](https://github.com/hamlet-io/engine/compare/8.1.2...8.2.0)

## 8.1.2 (2021-05-15)

#### New Features

* (contentnode): add support for image sources
* (mobileapp): add support for image config
* (adaptor): add attribute definition support
* (globaldb): define change stream support
* add compute task for system volumes
* write setting utility
* (apigateway): support for mutualTLS
* (computecluster): image source configuration
* openapi http endpoints and fragment
* yaml env support and alternatives
* yaml config output and contract properties
* add base permissions for ec2 components
* extend multipass generation support
* support executing multiple passes
* make refresh input state routine public ([#1669](https://github.com/hamlet-io/engine/issues/1669))
* (ecs): add compute provider support on service
* disable prefix for value extensions
* (healthcheck): update parameters from testing
* add healthcheck component definition
* warnings and deployed link failures
* compact log format for console
* add raw id and name formatting
* handle log based exceptions in engine
* include logging in entrance invoke
* add logging output processing
* add logging output writer
* console and log file writers
* additional output handlers for console logs
* extend output handler properties
* pretty output for json string
* include latest freemarker wrapper in engine
* add storage profile configuration ([#1642](https://github.com/hamlet-io/engine/issues/1642))
* compute image attribute sets
* add attribute extension support
* extendAttribute enhancements
* explicit extensions only
* computeTask configuration extension macro
* compute tasks
* add image configuration support for vms ([#1627](https://github.com/hamlet-io/engine/issues/1627))
* add attirbutes during extension processing ([#1625](https://github.com/hamlet-io/engine/issues/1625))
* (apigateway): image sourcing support ([#1622](https://github.com/hamlet-io/engine/issues/1622))
* (schema): add layers to the valid schema sections ([#1618](https://github.com/hamlet-io/engine/issues/1618))
* (cd): install the latest hamlet for testing
* adds mount path to volume config
* add support for engine output writing ([#1583](https://github.com/hamlet-io/engine/issues/1583))
* (sqs): ordering configuration for sqs queues
* validate deployment mode provided ([#1576](https://github.com/hamlet-io/engine/issues/1576))
* add occurrences entrance ([#1578](https://github.com/hamlet-io/engine/issues/1578))
* deployment state reporting ([#1574](https://github.com/hamlet-io/engine/issues/1574))
* (userpool): add schema attribute constraints ([#1564](https://github.com/hamlet-io/engine/issues/1564))
* ipaddressgroups on bastion component ([#1567](https://github.com/hamlet-io/engine/issues/1567))
* (gateway): add dpd action configuration
* Stop on fatal ([#1556](https://github.com/hamlet-io/engine/issues/1556))
* refactor input sources ([#1549](https://github.com/hamlet-io/engine/issues/1549))
* additional wrapper search options ([#1553](https://github.com/hamlet-io/engine/issues/1553))
* add schema generation for modules ([#1550](https://github.com/hamlet-io/engine/issues/1550))
* (jenkins): handle plugin upgrades ([#1543](https://github.com/hamlet-io/engine/issues/1543))
* whatif input provider ([#1538](https://github.com/hamlet-io/engine/issues/1538))
* add raw ids for occurrence details ([#1539](https://github.com/hamlet-io/engine/issues/1539))
* layerpath attributeset ([#1537](https://github.com/hamlet-io/engine/issues/1537))
* (baseline): add support for extensions on keys ([#1533](https://github.com/hamlet-io/engine/issues/1533))
* wrapper upgrade ([#1530](https://github.com/hamlet-io/engine/issues/1530))
* linkChildConfiguration to attributeSet attrs
* (s3): add support for inventory reports
* (spa): image source from url ([#1522](https://github.com/hamlet-io/engine/issues/1522))
* (userpool): authprovider extensions ([#1521](https://github.com/hamlet-io/engine/issues/1521))
* new task type: schemaset
* new schemaset view type
* (schema): new entrance type - schemaset
* add default schemacontract generation macro
* (externalnetwork): Alerting support ([#1515](https://github.com/hamlet-io/engine/issues/1515))
* (template): url image sourcing ([#1513](https://github.com/hamlet-io/engine/issues/1513))
* (s3): add s3vpcaccess extension
* changelog generation ([#1509](https://github.com/hamlet-io/engine/issues/1509))
* (registry): support for mutli region registry
* globaldb secondary indexes ([#1507](https://github.com/hamlet-io/engine/issues/1507))
* account inbound ses configuration
* MTA component
* (extensions): Allow mutliple extensions
* (extensions): support entrance extensions
* (extensions): convert existing fragments
* fragment migration to extensions
* allow setting encryption scheme for attributes
* (masterdata): add additional rabbitmq port definitions for queuehost
* (queuehost): initial definition
* (ecs): support container image sourcing ([#1495](https://github.com/hamlet-io/engine/issues/1495))
* (alerts): get metric dimensions from blueprint ([#1490](https://github.com/hamlet-io/engine/issues/1490))
* (secretstore): update configuration and make it shareable ([#1484](https://github.com/hamlet-io/engine/issues/1484))
* (network): flow log control
* (datafeed): add deployment specifc indludes to prefix
* (datafeed): deploy specifc prefixes
* bug-feature templates for issues
* manage one off instance failures
* os patching in solution config
* (lambda): pull images from external source ([#1456](https://github.com/hamlet-io/engine/issues/1456))
* add reference definitions for profiles
* define layers in shared provider
* Add engine support for layers
* (base): add object searching using a keys
* (ecs): add support for compute providers
* add scenario profile reference type
* add scenario loading through blueprint
* add operations and provider to mgmt
* (occurrence): Setting namespaces for occurrence
* (occurrence): support caching of occurrences
* (containers): ulimit configuration
* semver support ([#1434](https://github.com/hamlet-io/engine/issues/1434))
* (apigateway): added logstore attribute
* support for centralised service resources
* (ecs): placement constraint support
* template control per api gateway status
* Generic check for type in authentication header
* API gateway error format control
* hamlet info view
* s3 sync exclude support
* views for blueprint and schema
* dynamic model loading and scopes
* document set support
* add databucket replication attributes ([#1411](https://github.com/hamlet-io/engine/issues/1411))
* add support for token validity expressions ([#1409](https://github.com/hamlet-io/engine/issues/1409))
* (links): incl. support for case-insensitive link direction
* "Account" and fixed build scope ([#1402](https://github.com/hamlet-io/engine/issues/1402))
* add processor profiles
* add engine attr to containerhost
* splitting out container components
* (jenkins): add support for dind in hamlet agents
* (ecs): allow for fragment and image override in solution
* (ecs): add hostname macro for containers
* (ecs): fragment override and image override in solution
* aws ecs account settings
* management contract generation
* add deployment component attributes
* component deployment attributes
* deployment mode and group refernce
* set default deployment group for all components
* update format for deployment groups to incldue name/id
* support deployment document generation using group filters
* support deployment group filtering on occurrences
* (apigateway): add quota throttling
* (ecs): add healthcheck support
* (userpool): control oauth on clients
* (ecs): support for efs volume mounts on ecs tasks
* (efs): support chroot based on mount points
* (openapi): enable throttling settings on apigw
* add service role provisioing to account level
* add service role reference
* add policy to core component config
* (core): extend policy profiles to occurence level control
* (filetransfer): security policy control
* (filetransfer): support for a file transfer component with user integration
* (ecs): add lookup for ingress rules based on links for containers
* (waf): add waf logging profiles
* (schema): add required property to jsonschemas ([#1367](https://github.com/hamlet-io/engine/issues/1367))
* consolidate level clients in line with deployment groups
* add resource labels to support resourceSets in deployment groups
* add deployment groups for unit and level control
* (schema): added subsets for reference data and component schema
* (schema): default output - schema
* tier based network lookup ([#1359](https://github.com/hamlet-io/engine/issues/1359))
* (account): allow unique cmk aliases
* (console): add dedicated cmk option for console sessions
* (secretstore): new component type - secretstore
* set container level auth method for hamlet agent
* (externalservice): Networkacl support
* Container support for network profiles
* Network rule component configuration
* network profiles
* (s3): baseline s3 encryption permissions
* (s3): account level S3 Encryption
* (s3): add configuration support s3 Encryption
* (lb): WAF integration
* (ec2): volume encryption
* (console): Update console support for encryption
* (testcases): add additional output suffix types.
* (externalservice): Attributes for external service endpoint
* Bucket cleanup optional when copying files
* add host from network util
* (lb): add static endpoint forwarding
* (externalservice): add support for endpoints on an external service
* (gateway): destination port control
* (gateway): destination port control for private services
* (gateway): dns configuration support
* (lb): Network load balancer TLS offload
* (router): static route support
* (privateservice): intial support for private services ([#1330](https://github.com/hamlet-io/engine/issues/1330))
* (router): make BGP ASN mandatory
* (gateway): dynamic routing for private gw
* (gateway): private gateway
* (externalnetwork): intial external network support
* (gateway): support for the router component as an engine
* (router): adds initial support for the router component
* (globaldb): intial support for global dbs ([#1325](https://github.com/hamlet-io/engine/issues/1325))
* (fragment): startup command setting for agent
* (jenkins): add support for permanent ecs agents ([#1321](https://github.com/hamlet-io/engine/issues/1321))
* (apigateway): support gateway and cdn https profiles
* (mobileapp): OTA Support on CDN routes ([#1319](https://github.com/hamlet-io/engine/issues/1319))
* (userpool): Add Encryption schema to client secrets
#### Fixes

* syntax update for writing file for sync
* remove global settings assignement
* set deployment unit subset for template
* handle fileformat when not provided
* subset and alternative fixes
* update seeding order
* region in filenames ([#1667](https://github.com/hamlet-io/engine/issues/1667))
* typo in description
* minor spelling mistake fixes
* dynamic cmdb loading ([#1663](https://github.com/hamlet-io/engine/issues/1663))
* set multiAZ flag for blueprint generation ([#1662](https://github.com/hamlet-io/engine/issues/1662))
* typo in definition
* typo in definition
* log format message
* script store sync ([#1647](https://github.com/hamlet-io/engine/issues/1647))
* mta rule link attribute
* default storage profile name
* certificate behaviour configuration ([#1641](https://github.com/hamlet-io/engine/issues/1641))
* handle attribute formats in expand
* align alternative config with gen contract
* update state output to align with output
* pseudo stacks ([#1628](https://github.com/hamlet-io/engine/issues/1628))
* use loaded providers as definitive providers ([#1623](https://github.com/hamlet-io/engine/issues/1623))
* handle multiple load modules in module ([#1621](https://github.com/hamlet-io/engine/issues/1621))
* composite object wildcard handling ([#1614](https://github.com/hamlet-io/engine/issues/1614))
* loader module control ([#1620](https://github.com/hamlet-io/engine/issues/1620))
* line ending standard on unix
* line breaks in text output writing
* url references in changelog
* current unit detection
* handle deployment details in output file name
* correct spelling of output type
* output naming for deployment group prefix ([#1606](https://github.com/hamlet-io/engine/issues/1606))
* typo in blueprint generation
* schema output return
* disable qualifier transformer
* shared test seeder
* shared fixture seeder
* isolate testing to only include local code ([#1594](https://github.com/hamlet-io/engine/issues/1594))
* update layer type for region
* deploymentGroup validation
* (sqs): typo in id details
* define deploymentgroups for schemas ([#1586](https://github.com/hamlet-io/engine/issues/1586))
* regression in unlist generation
* RawId and Name values for subcomponents ([#1585](https://github.com/hamlet-io/engine/issues/1585))
* handle empty deployment unit Ids unitlist
* handle missing product domain ([#1580](https://github.com/hamlet-io/engine/issues/1580))
* update hamlet cli test cmds ([#1575](https://github.com/hamlet-io/engine/issues/1575))
* domain assembly process ([#1573](https://github.com/hamlet-io/engine/issues/1573))
* domain zone configuration ([#1572](https://github.com/hamlet-io/engine/issues/1572))
* handling of log level lookup ([#1569](https://github.com/hamlet-io/engine/issues/1569))
* allow for loading provider input replacement
* internaltest component definition ([#1547](https://github.com/hamlet-io/engine/issues/1547))
* Links as subobjects ([#1545](https://github.com/hamlet-io/engine/issues/1545))
* freemarker wrapper write functions ([#1542](https://github.com/hamlet-io/engine/issues/1542))
* (account): update script store clone setup ([#1541](https://github.com/hamlet-io/engine/issues/1541))
* image url override for containerregistry ([#1534](https://github.com/hamlet-io/engine/issues/1534))
* flowlog configuration ([#1531](https://github.com/hamlet-io/engine/issues/1531))
* AttributeSet handling ([#1529](https://github.com/hamlet-io/engine/issues/1529))
* link attributeset in s3 inventory reports
* attributeset schema one per
* (schema): reference data as one schema per schema
* revert type updates ([#1520](https://github.com/hamlet-io/engine/issues/1520))
* corrected a missed composite object data type update ([#1519](https://github.com/hamlet-io/engine/issues/1519))
* (lambda): correct type for Fixed code version
* schema data type generation
* schema assignment of multiple data types
* changelog generation
* typo in function names
* support buckets without at rest encryption
* remove service linked role check for cmk
* handle missing output mappings for resources
* masterdata inclusion in blueprint
* dind hostname and image details ([#1503](https://github.com/hamlet-io/engine/issues/1503))
* erroneous bracket ([#1501](https://github.com/hamlet-io/engine/issues/1501))
* minor typos
* hanlde missing values for lambda
* support missing extension
* (extensions): use resolved alias id for lookups
* update for ProviderId migration
* (schema): metaparameters should not ref links
* (datafeed): update description
* (reference): deployment mode default hanlding
* layer attribute searching
* handling of account iam and lg subsets
* (console): allow for psuedo s3 buckets
* (accountlayer): fix console logging
* detect missing data volumes
* expand range of certificate behaviours
* possible certificate behaviour attributes
* (s3): renamed global var back to dataOffline ([#1452](https://github.com/hamlet-io/engine/issues/1452))
* include int and version in occurrence caching ([#1451](https://github.com/hamlet-io/engine/issues/1451))
* provide deployment unit to build settings
* typo in function name
* semver supports asterisk in range indicator ([#1438](https://github.com/hamlet-io/engine/issues/1438))
* parameter ordering for invokeViewMacro ([#1428](https://github.com/hamlet-io/engine/issues/1428))
* allow for undefined networkendpoints on a region ([#1427](https://github.com/hamlet-io/engine/issues/1427))
* determine a primary provider to use for views ([#1422](https://github.com/hamlet-io/engine/issues/1422))
* authorizer failure messages
* 403 status on authorizer failure
* case insensitive token validity expression
* setup contract outputs in resourceset ([#1419](https://github.com/hamlet-io/engine/issues/1419))
* better control over scope combination
* output to use arrays
* reinstate link casing changes
* move link target to context support template
* remove copy and paste error
* typo in component
* typos in entrances
* reinstate schema output type
* macro lookup processing array handling
* entrance params and log messages
* provider updates from testing
* engine updates from testing
* typo in openapi syntax ([#1410](https://github.com/hamlet-io/engine/issues/1410))
* syntax and variable name updates for build scopes ([#1403](https://github.com/hamlet-io/engine/issues/1403))
* Explicit mock API passthrough behaviour ([#1401](https://github.com/hamlet-io/engine/issues/1401))
* (ecs): reinstate deployment details ([#1400](https://github.com/hamlet-io/engine/issues/1400))
* (ecs): add fragment and instance back to container props ([#1399](https://github.com/hamlet-io/engine/issues/1399))
* remove legacy component properties
* moved engine type from containerServiceAtttributes to only exist on the ecs component
* corrected call to child component macro
* explicit auth disable for options
* align resource sets with latest deployment groups
* (fragment): hamlet agent properties mounts ([#1397](https://github.com/hamlet-io/engine/issues/1397))
* remove legacy naming for fragment
* typos in fragments
* (ecs): Volume drivers and support for control over volume engine
* Pregeneration output format ([#1395](https://github.com/hamlet-io/engine/issues/1395))
* Output type for pregeneration scripts ([#1394](https://github.com/hamlet-io/engine/issues/1394))
* handle no deploymentunit ([#1392](https://github.com/hamlet-io/engine/issues/1392))
* (apigateway): do not attempt eval if definitions full is null ([#1389](https://github.com/hamlet-io/engine/issues/1389))
* remove unused deployment group config
* remove networkacl policies from iam links ([#1386](https://github.com/hamlet-io/engine/issues/1386))
* (settings): evaluation preferences for setting namespaces
* (openapi): quota throttling only exists on a usage plan
* (efs): use children for ownership
* (mock): set a fixed runId for mock
* use all units by default on resource lables
* ensure service linked roles exist for volume encryption
* only apply basic deployment groups for shared provider
* comments on resource label definition
* If no CIDRs defined, getGroupCIDRs should return false
* (s3): adds migration for queue permissions config
* (externalservice): Apply solution config on the resource group
* (networkProfile): enable or disable egress rules ([#1351](https://github.com/hamlet-io/engine/issues/1351))
* (masterdata): add global outbound rule description
* add settings back in to bootstraps
* remove console only support in bastion
* (account): only run cmk checks in specific units
* (bastion): allow ssh when internet access disabled
* (externalservice): fix var name for ip listing
* (externalservice): var name
* (externalservice): attribute name
* host filtering for networks
* (router): bgp asn description
* perfect square calculation
* use perfect squares for subnet calculations
* Wrapper fix for CMDB file system
* (fragment): agent override for aws user
* Subcomponent config on instance/version
* (gateway): remove mandatory requirement on Endpoint details
* Remove auth provider defaults ([#1313](https://github.com/hamlet-io/engine/issues/1313))
* Add dummy end.ftl for accounts composite
#### Refactorings

* state refresh trigger
* make task generic
* move alert config into attribute set
* update existing writer handlers
* use compute image source components
* remove wait for signal on autoscaling
* split attribute expansion in composite
* add scopes for compute tasks extensions
* align bootstrap naming with computetask
* composite template inclusion ([#1613](https://github.com/hamlet-io/engine/issues/1613))
* remove startup scripts from masterdata
* run tests first for feedback
* state processing ([#1605](https://github.com/hamlet-io/engine/issues/1605))
* CLO accessor names
* command line and masterdata processing
* remove metric setup from core ([#1582](https://github.com/hamlet-io/engine/issues/1582))
* change timing log level ([#1571](https://github.com/hamlet-io/engine/issues/1571))
* move github templates to org ([#1557](https://github.com/hamlet-io/engine/issues/1557))
* attributesets to be def on comp obj
* remove unused global vars
* add error handling for invalid schema instance
* (schemaset): align task attributes ([#1523](https://github.com/hamlet-io/engine/issues/1523))
* remove validation of multiple "type" variations.
* composite object model consistency with types
* identified type-less composite object attributes
* schema output macro to set definitions as object type
* schema macros/functions to handle a subsection
* limit usage of extension
* use name for url images
* move extension macros into shared
* (extensions): migrate existing fragments
* move extension support macros
* support components with mixed case names
* (network): rename flow action
* rename scenarios to modules
* setContext using layers
* move reference data loading to bootstrap
* load all reference data from blueprint
* change loading order for some templates
* switch COT to Hamlet ([#1413](https://github.com/hamlet-io/engine/issues/1413))
* model flow replacement
* remove models in favour of flows
* update view to support entrances
* rename scopes to flows
* update invoking services to entrances
* rename document sets to entrances
* remove dedicated entrypoints
* dynamic loading of subset marcos
* support for new deployment unit attr
* update structure of throttling configuration
* rename start to align with docker docs
* (cmk): service linked role check
* remove copy and paste vars
* add service imports in account templates
* Namespace matching support
#### Docs

* overhaul and revision of outdated readme ([#1566](https://github.com/hamlet-io/engine/issues/1566))
* Add basic README for shared extensions ([#1554](https://github.com/hamlet-io/engine/issues/1554))
#### Others

* changelog update
* (deps): bump lodash from 4.17.20 to 4.17.21 ([#1682](https://github.com/hamlet-io/engine/issues/1682))
* (deps): bump handlebars from 4.7.6 to 4.7.7 ([#1680](https://github.com/hamlet-io/engine/issues/1680))
* (deps): bump hosted-git-info from 2.8.8 to 2.8.9 ([#1681](https://github.com/hamlet-io/engine/issues/1681))
* add node 14 support for lambda ([#1638](https://github.com/hamlet-io/engine/issues/1638))
* (schemas): add layer schemas to schemaset ([#1633](https://github.com/hamlet-io/engine/issues/1633))
* release notes
* changelog
* changelog
* (spelling): updated spelling
