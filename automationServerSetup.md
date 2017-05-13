## ALM Setup

In general ALM consists of jenkins, docker and httpd as frontend. Jenkins is distributed as a war file and thus needs some container service to be run on, we use tomcat7.

1) **Run up ALM server, and create DNS entry for it - `{automation}.domain`**
2) **Install the required packages**
```
yum -y update
yum install -y git jq dos2unix
yum install -y httpd24  mod24_ssl
yum install -y tomcat7
yum install -y docker
yum groupinstall "Development Tools"
```
3) **Configure tomcat7**

Put the following line just before to trailing tag to `/etc/tomcat7/context.xml`:
```
<Environment name="JENKINS_HOME" value="/codeontap/jenkins/" type="java.lang.String"/>
```
Put the following lines for `JAVA_OPTS` in `/etc/tomcat7/tomcat7.conf`:
```
JAVA_OPTS="${JAVA_OPTS} -Dhudson.DNSMultiCast.disabled=true"

JAVA_OPTS="${JAVA_OPTS} -Dorg.apache.commons.jelly.tags.fmt.timeZone=Australia/Sydney"
```
Configure `UTF8` as base encoding, thus add the following attribute to `Connector` section of `/etc/tomcat7/server.xml` file:
```
URIEncoding="UTF-8"
```
Add tomcat user to docker group to access docker:
```
usermod -aG docker tomcat
```
4) **Setup jenkins**

Download the latest stable version to `/root` directory, rename it to `jenkins-{version}.war`, copy it to `webapps` dir as `ROOT.war`:
```
sudo su
cd ~
wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war
mv jenkins.war jenkins-{version}.war
cd /usr/share/tomcat7/webapps
cp ~/jenkins-{version}.war ROOT.war
mkdir -p /codeontap/jenkins
chown tomcat:tomcat /codeontap/jenkins
```
Create backup script in `/root/backup_data.sh` - replace `{domain}` to required domain:
```
#!/bin/bash
JENKINS_DIR="/codeontap/jenkins"
REGION="ap-southeast-2"
BUCKET="s3://operations-alm-automation.{domain}/Backups/alm"
TIMESTAMP=`date +"%Y-%m-%d-%H-%M"`
aws s3 cp --recursive --exclude "*log" $JENKINS_DIR/jobs $BUCKET/jenkins/$TIMESTAMP/jobs --region $REGION
aws s3 cp $JENKINS_DIR/config.xml $BUCKET/jenkins/$TIMESTAMP/config.xml --region $REGION
```
Change mode for backup script to make it executable:
```
chmod 755 /root/backup_data.sh
```
Create crontab:
```
# Copy key data to S3 each day
0  2 * * * /root/backup_data.sh
#
# Clean up tomcat logs
10 1 * * * find /var/log/tomcat7/ -mtime +30 -exec rm -rf {} \;
#
# Keep SSL certificate up to date
5 0,8,16 * * * /root/certbot-auto renew >> /var/log/renew_cert_check.log 2>&1
```
Start tomcat:
```
service tomcat7 start
```
5) **Setup docker**
```
service docker start
```
6) **Setup httpd**

Create `jenkins.conf` vhost for http redirect to https - replacing `{domain}` with the required domain:
```
<VirtualHost *:80>
    ServerName automation.{domain}
    RewriteEngine on
    ReWriteCond %{SERVER_PORT} !^443$
    RewriteRule ^/(.*) https://%{HTTP_HOST}/$1 [NC,R,L]
</VirtualHost>
```
Create `jenkins-ssl.conf` vhost for jenkins - replacing `{domain}` with the required domain:
```
<VirtualHost *:443>
    ServerName automation.{domain}
    SSLProxyEngine On
    SSLProxyCheckPeerCN on
    SSLProxyCheckPeerExpire on
    ServerAdmin alerts@{domain}
    ErrorLog logs/ssl_error_log
    TransferLog logs/ssl_access_log
    LogLevel warn
    SSLEngine on
    SSLProtocol             all -SSLv2 -SSLv3
    SSLCipherSuite          ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
    SSLHonorCipherOrder     on
    SSLOptions +StrictRequire
    SSLCertificateFile /etc/letsencrypt/live/automation.{domain}/cert.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/automation.{domain}/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/automation.{domain}/chain.pem
    SetEnvIf User-Agent ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0
    CustomLog logs/ssl_request_log \
          "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
    ProxyPass         /  http://localhost:8080/ nocanon
    ProxyPassReverse  /  http://localhost:8080/
    ProxyRequests     Off
    AllowEncodedSlashes NoDecode
    <Proxy http://localhost:8080/*>
       Order deny,allow
       Allow from all
    </Proxy>
</VirtualHost>
```
Install let's encrypt functionality to obtain/maintain SSL certificate into root home directory:
```
cd ~
wget https://dl.eff.org/certbot-auto
chmod +x certbot-auto
./certbot-auto certonly --debug
```
Ignore any errors involving apachectl (config will be invalid until certificate obtained), choose `(3) (Spin up temporary webserver)` as the authentication method required, and `automation.{domain}` as the required domain.

Start the httpd server:
```
service httpd start
```
Check renewal will work ok - need to reconfigure to allow for running http server (choose 2) to renew certificate). If this works, then crontab job should be ok as well:
```
./certbot-auto --apache certonly --debug
./certbot-auto renew --dry-run
```
7) **configure the services in chkconfig:**
```
  chkconfig tomcat7 on
  chkconfig httpd on
  chkconfig docker on
```
8) **Configure Jenkins.**

Go to Jenkins at https://automation.{domain} in a browser (initial admin password in `/codeontap/jenkins/secrets/initialAdminPassword`).
Install the recommended plugins, and **DON'T** set up an admin user - we will configure authentication using github.
In `Configure System`, set the Jenkins `Location` to `automation.{domain}`, save and confirm proxy is now working correctly.
In `Manage Plugins`, install non-standard plugins:
  1. GitHub Authentication
  2. Slack Notification 
  3. Extended Choice Parameter
  4. User build Vars
  5. Environment Injector
  6. Parameterized Trigger

9) **Add GitHub Authentication**

Add OAuth Application in github organisation, set callback to `https://automation.{domain}/securityRealm/finishLogin`.

>If you don't have access to github organisation settings, add OAuth Application in your account (Settings -> Developer Settings -> OAuth application -> Register a new application) and request owner transfer to organisation.

Select `any logged in user` for the authorisation, save, and log off/log on to confirm authentication now through github.
Switch to `project based matrix authorisation`, add an entry for the organsiation granting general read, add an entry for the org devops group granting all permissions, save and confirm can still log in as part of devops team (create in github if not there already)..

10) **Add Credentials**

In `Jenkins->Credentials` add global credentials (Usename/Password) for GitHub and AWS. Set a 
Add Jenkins integration to Slack team to get a token, add a global credential (secret text) for Slack.
Pick the credential on `Jenkins->Manage Jenkins->Configure System` screen in 'Global Slack Notifier Settings' section. Set `Team Subdomain` and `Channel`.
The credentials can be decrypted from `aws-accounts` repo in `gs-gs` account.

11) **Run sudo commands without tty**

If tomcat user needs to be able to run sudo commands without tty, you need to the following:
```
visudo
```
Change the line
```
Defaults    requiretty
```
to
```
Defaults    !requiretty
```
and add the following line to the very end of file:
```
%tomcat ALL=NOPASSWD: ALL
```
and change tomcat shell in `/etc/passwd` to `/bin/bash`
 
> *NOTE: This is not necessary if sudo is only required to be able to run docker assuming tomcat added to the docker group as shown above*

12) ***Set up LDAP jenkins authentication (as alternative to GitHub Authentication)***
  1. Open jenkins URL(since it is not setup yet, it should allow anonymous login)
  2. Go to Manage Jenkins -> Configure Global Security
  3. There you will need to check Enable Security box and then select LDAP as security Realm
  4. Once it is done you will need to click on Advanced box under LDAP security realm and configure LDAP with the following values:
```
Server: alm.gosource.com.au
root DN: dc=gosource,dc=com,dc=au
User search base: ou=Users
User search filter: uid={0}
Group search base: ou=Groups,ou=env01,ou=accounts,ou=env,ou=organisations (it depends on the organization name)
Group search filter:
Group membership: select Parse user attribute for list of groups from dropdown and put memberOf as Group membership attribute
Manager DN: this one should be populated with the alm CN created for the organization
Manager Password: this one should be populated with the alm password
Display Name LDAP attribute: displayname
Email Address LDAP attribute: mail
```
  5. After LDAP is configured you will need to choose the proper Authorization, it is Project-based Matrix Authorization Strategy, configure local-alm group with the full access and other LDAP groups with the Read Permissions as required
 
 
13) Adding docker images to the private registry

  1. First you need to login to the instance with the running docker daemon(alm fits best for this purpose) and login to the private registry:

`docker login -u USER -p PASS -e USER docker.env01.gosource.com.au:443`

  2. Then you need to pull or build the image that needs to be added to the registry, e.g.:

`docker pull logstash`

  3. After the image is built/pulled, it needs to be tagged properly, e.g.:

`docker tag logstash docker.env01.gosource.com.au:443/logstash`

  4. And then it could be pushed to the registry:

`docker push docker.env01.gosource.com.au:443/logstash`


14) Google email domains and addresses
GoSource uses Google to host the various email domains it uses under gosource.com.au. To set up an email domain:

  1. Add the domain in the Google console->Domains. Domains take the form {OrganisationIdentifier}{SequenceNumber = 01, 02...}, e.g. fin01, gs03. NOTE: Make sure "Add another domain" is selected NOT the default "Add a domain alias of gosource.com.au"
  2. Create DNS records (MX, TXT, SPF) for the domain. This is currently done in Route53 within the root+aws@gosource.com.au account. Copy the record contents from any of the other account domains already in DNS. TTL can be set to 1d (86400s). MX record should use the standard Google entries, TXT/SPF should use "v=spf1 include:amazonses.com include:\_spf.google.com ~all" so emails can be accepted when coming either from the AWS Simple Email Service or from Google itself.
  3. Verify the domain in the Google console->domains->Set up Google MX records->I have completed these steps (the previous step covers the actions necessary - this is just to keep Google happy). The status should initially say "MX records setup validation in progress..." but after a while (up to 24 hours) will change to "Active". There is nothing we do to make this happen.

The next step is to create a default domain email address if required (normally it isn't as there is a gosource wide email group for this purpose, which in turn includes a global history email account). This will be included in all email groups set up for the domain and is basically designed to collect email history for the account. To set up the default email:

  1. Ensure GoSource has purchased enough email account licences. Go to Google console->Users and if there is a red circle in the top right corner, click on it to purchase more email accounts.
  2. Click on the Add Users button in the top right corner.
  3. Select Add a user manually.
    * First name = {OrganisationName}{SequenceNumber}. A name is used to make it clearer who the account belongs to but the id can be used instead if a longer name doesn't add any value (e.g. Finance01 instead of fin01).
    * Last name = {Development | Production}
    * Email address = domain@domain.gosource.com.au. NOTE: Make sure you select the specific domain from the dropdown.
  4. Create the user

Finally, each domain should have a "root" and "alerts" group. The root group will be used in creating accounts to online service providers, such as AWS. The alerts group is used to notify of exceptions occurring within the account, such an email bounces. To set up the root group:

  1. Go to Google console->Groups and select "Create Group" in the top right hand corner.
  2. The name of the group should be "{FirstName} {LastName} - root". The First/Last name are the same as the default domain email .
  3. The group email address should be "root". NOTE: Make sure you select the specific domain from the dropdown - normally you'll get an error if you don't as the root account will already exist for the domain initially displayed.
  4. Access Level should be "Team" and the "Also allow anyone on the internet to post messages" must be selected. (You can do this later if you accidently forget to select this checkbox).
  5. Add the GoSource wide default group (default@gosource.com.au or default@gosource.gosource.com.au depending on whether the account is related to GoSource Production or Gosource Development) to the group via the Google console->Groups->root group->Add.
  6. Add the domain default email (if created) to the group via the Google console->Groups->root group->Add.
  7. Repeat the process replacing "root" with "alerts".

15) SSL certificates
GoSource obtains an SSL certificate for any accounts in which an alm is established, and if a project is using the gosource domain, can also obtain a certificate for project environments. We'd expect any production environment would use a project specific SSL certificate.

The following openssl command should be used to generate the domain keypair (crt) and the certificate signing request (csr). Both should be stored in the top level of the account/project credentials S3 bucket.
```
openssl req -new -newkey rsa:2048 -sha256 -nodes -keyout {domain}-ssl-prv.pem -out {domain}-ssl-csr.pem
where {domain} is the domain to be covered, with dots replaced with dashes, e.g. fin01-gosource-com-au-ssl-prv.pem.
```
Attributes for certificates with a .gosource.com.au suffix should be

```
Country Name: AU
State: Australian Capital Territory
Locality: Canberra
Organization Name: GoSource Pty Ltd
Organization Unit: <blank>
Common Name: wildcarded version of domain
Email Address: webmaster@gosource.com.au
Challenge Password: <blank>
Optional Company Name: <blank>
```

To view a formatted version of the CSR,

```
openssl req -text -in {domain}-ssl-csr.pem
```
The next step is to submit the CSR to the certificate issuing provider. The following values should be specified if requested;

```
Certificate Format: PEM
Signature Algorithm: SHA-2
Verification method: email (will be sent to admin@gosource.com.au)
Site Administrator
First Name: GoSource
Last Name: GoSource
Title: <blank>
Email Address: webmaster@gosource.com.au
Phone Number: +61261983268
Technical Details: <same as admin details>
```

Ensure the resulting certificate is provided in PEM format, and save it in S3 with the CSR as {domain}-ssl-crt.pem. It may also be necessary to capture issuer intermediary certificates, e.g. rapidssl-ssl-intermediate.pem.

16) Shelf Account Creation
In order to speed up the process of organisation account creation, we maintain a few GoSource "shelf" accounts - shelf01, shelf02, ..shelfnn. These are basically fully set up AWS accounts. Importantly, they are already linked for consolidated billing and have cross-account access established via the gosource-administration role.

When a customer needs a new account, a shelf account is converted into an organisation account as described below.

A new shelf account is then created in readiness for the next customer, and reuses the email address of the previous account. Note that the renaming of the login for the customer account must be done BEFORE the new shelf account is created. It is expected that only a few shelf accounts will be kept in readiness, though as demand grows this pool can also grow.

To create a shelf account, the following steps need to be followed:

  1. If not already set up, create a new domain for the shelf account using the "shelf" organisation id.
  2. If not already set up, create a root group for the shelf account. First name = Shelf{SequenceNumber}
  3. Go to console.aws.amazon.com
  4. Enter the shelf account root email address, select "I am a new user" and click on signin
    * Name = same first/last name as the root group e.g. Shelf01 Development
    * Email address = root+aws@domain as per naming conventions
    * Password = random 20 character password - http://www.random.org/passwords/?num=1&len=20&format=html&rnd=new. Password should be stored in the Credentials bucket of the root+aws@cb.gosource.com.au (production) or root+aws@cb.gosource.gosource.com.au account, key /gs/shelfnn/aws-account-{AWSaccountID}.csv
  5. Click on create account
  6. A prompt is displayed saying "You have not yet signed up for AWS." Click on "sign up for AWS".
    * Full Name = "Steve Capell", Company Name = "GoSource Pty Ltd", Country = "Australia", Address = "Level 1 The Realm / 18 National Circuit BARTON", City = "Canberra", State="ACT", Postal Code="2600"
    * Phone Number = mobile of account creator - you will receive a call from AWS to confirm the account. 
    * _NOTE: Include the country code in the number._
  7. Enter the security captcha check, tick the agreement checkbox and click "Create Account"
  8. Enter details of a GoSource credit card - this will be replaced by consolidated billing in a step below. "Use my contact address" should be selected and is ok if the details were entered as detailed in a previous step.
  9. Confirm the telephone number presented in the "Identity Verification" dialog is correct and click on "Call Me Now". Provide the PIN shown on the dialog to the automated voice confirmation.
  10. Select "Basic (Free)" as the support plan, then click "Continue"
  11. The email addresses provided to the root group of the domain will be notified when the account is created.
  12. Log in to confirm the account is operational . The name displayed in the top right hand corner should match that entered for the domain and for the account Name.

The next step is to link the AWS account for consolidated billing to the GoSource consolidated billing account.

  1. Log in to root+aws@cb.gosource.com.au (or root+aws@cb.gosource.gosource.com.au for the GoSource development environment)
  2. Confirm the account name in the top right corner if for a consolidated billing account, then select "Billing & Cost Management" from the dropdown under the name.
  3. Select "Consolidated Billing" and click on the "Send a Request" button
  4. Enter the root+aws@domain address for the newly created account e.g. root+aws@shelf01.gosource.com.au and send the request.
  5. The addresses included in the root group for the domain will receive a confirmation email. Have one of them accept the consolidated billing request. If doing this all on one PC, make sure you log out of any AWS account (e.g. the consolidated billing account) before clicking on the link, or copy it first into a different browser.
  6. Log in using the root+aws@domain user of the new shelf account.
  7. Click on "Accept Request" to finalise the consolidated billing set up.

The next step is to create a role in the account that will be used by the GoSource website to be able to provision projects into this account. To create the gosource-administration role;

  1. Go to the IAM service
  2. Select "Roles" from the left hand menu
  3. Click on the "Create New Role" button
  4. Enter the role name as "gosource-administration", then select "Next Step" in the bottom right hand corner
  5. Select the "Role for Cross-Account Access" option, and choose the "select" button next to "Provide access between AWS accounts you own.
  6. Enter the ID of the GoSource Production account (514002541898) or development account if setting up an account for testing (635449961798 ). Leave the "Require MFA" option unchecked, and again select "Next Step"
  7. Click "Select" next to "Administrator Access". We will tighten this later via the CloudFormation template but for now, this will avoid any permissions issues when projects are provisioned into the account. Click "Next Step" again then click "Create Role".

***NOTE: the steps above are for manual creation of the the shelf account. The next step will be to change this to use a CloudFormation script for as much of the creation as possible.***

17) Conversion of Shelf Account to Organisation Account
Most of the work to set up an AWS account is performed as part of creating the shelf account. The following steps are needed:

  1. If not already set up, create a new email domain based on the organisation id, e.g. fin01.gosource.com.au.
  2. If required, create an email address for the domain. The first name ideally should be a full word or two, but if this doesn't make sense, use the organisation id used in the domain.
  3. Log in to the shelf account that is to be converted. The highest numbered account should normally be selected.
  4. Under the name of the account in the top right hand corner, select "My Account". then select the "Edit" link to the right of the "Account Settings" section.title
  5. Edit the name and replace the first name e.g. "Shelf01" with the value used when setting up the email account e.g. "Finance01"
  6. Edit the email to use the root+aws@domain of the organisation domain e.g. root+aws@shelf01.gosource.com.au -> root+aws@fin01.gosource.com.au.
  7. You will need to log out and log in again (now using the organisation account email address) to confirm that the changes have been made.
  8. Update the entry in the consolidated billing account credentials S3 bucket to reflect the updated username, and save it under the OID/OAID entry. Delete the entry under gs/shelf?? to reflect that the shelf account is no longer available until a new one is created.

We now need to establish the necessary infrastructure to allow emails to be sent from the account. This involves a number of steps.
  1. First we create an email group (if we haven't already) to receive bounce and compliant notifications:
    * Create an "alerts" email group following the instructions above for the "root" group but substituting "alerts" for "root".
  2. Next create an S3 bucket for the account (as distinct from the project specific buckets) to hold credentials.
    * create a "credentials" bucket e.g. credentials.fin01.gosource.com.au.
  3. Next we need to configure the AWS Simple Email Service (SES):
    * Select the SES service - you will need to switch regions as it isn't offered in Sydney - use US West (Oregon).
    * Click "SMTP Settings", then "Create My SMTP Credentials" (this will create an IAM user with the correct privileges to access the SES service
    * Enter an IAM User Name of "gosource-ses"
    * Download the SMTP credentials - these will be stored in the account credentials bucket as aws-ses-{region}.csv

Now we need to verify the account email domain. (this process will need to be repeated for each project within the account that wants to send emails)

  1.  Click "Domains" under Verified Senders
  2.  Click "Verify a New Domain"
  3.  Enter the account domain, e.g. fin01.gosource.com.au, and select the "Generate DKIM Settings" option
  4.  Create the TXT and CNAME entries as per the displayed information. They can have a long TTL such as 1d. It's probably simpler to "download as CSV" and display in your favourite text editor in order to be able to cut/paste into the AWS route53 console. Remember to omit the ".gosource.com.au" from the name when cutting and pasteing (note this includes the leading dot).
  5.  Click on the entry for the domain just added, and expand the control next to the "Notifications" label.
  6.  Click Edit Configuration
  7.  Create an AWS Simple Notification Service (SNS) topic via the provided link. Give it the same name as the domain, prefixed with "alerts", but with hyphens instead of dots, e.g. alerts-fin01-gosource-com-au. (If verifying a project domain, just reuse the existing topic)
  8.  Associate the topic with bounces and compliants and save the configuration
  9.  Click Edit Configuration again, but this time, disable email feedback forwarding and save again

Next we need to configure the SNS topic to send notifications to the account alerts email group:

  1.  Go to the SNS service
  2.  Select the topic created above (note that it will have been created in the same region as SES was set up in)
  3.  Click "Subscribe to Topic" from the Actions dropdown. Select Email as the protocol, and enter the alerts group email address as the Endpoint. This will result in bounce and compliant notifications going to the alerts group. Confirm the subscription from an account in the alerts group (make sure you are not logged in at the time in another browser tab/window).

When the domain and DKIM settings are verified (it can take a while but if it seems to be taking forever, the DNS entries might not be quite right):

  1.  Go back in to the domain settings in the SES console
  2.  Expand the DKIM section, and click "Enable". This will result in all emails for the domain being signed with DKIM.

Finally:

  1.  Click on the Dashboard menu entry in the SES console
  2.  Click on "Request Production Access"
  3.  Select the region used, and the limit "Desired Daily Sending Quota". Enter 200 as the limit. It can be increased later if required,
  4.  Select Mail Type as "Other", website URL as "https://www.compliancetest.net" and "Yes" in all the dropdowns.
  5.  "Use case description" - "GoSource uses a separate AWS account to host each of its customer's development facilities. This includes both an Application Lifecycle Management support and project environments. It is a common requirement for email notifications to be sent from these environments. 

We expect actual send rates to be low so are ok with the default limits to start with. It is mainly the ability to send to a broad range of email addresses that we are seeking at this stage.
  *  Add your email address as a CC on the request, and click the "Web" contact mechanism. The request creates a support ticket which you can see via the Support menu in the top right-hand corner of the console when logged in to the organisation account.

In order to avoid using the AWS account for administrative activities on the account, we also create a local administrators group, and a IAM user as a member of this group that can be used by sysadmins assigned to customer projects:

  1.  Go to the IAM service
  2.  Select "Users" from the left hand menu
  3.  Click on the "Create New User" button
  4.  Create a user called "gosource-root". At present, leave "Generate an access key for each user" selected as the api credential can be used to manually perform any AWs cli operations needed over time. Eventually these will all be done via the cross-account role.
  5.  Select the user and click on "Manage Password". Select an auto-generated password.
  6.  Download the user and api credentials - these will be stored in the account credentials bucket as aws-user-gosource-root.csv and aws-api-gosource-root.csv
  7.  Close the dialog
  8.  Select "Groups" from the left hand menu
  9.  Click on the "Create New Group" button
  10.  Enter the group name as "gosource-local-administrators", then select "Next Step" in the bottom right hand corner
  11.  Select the "Administrator Access" policy template
  12.  Click "Next Step" and "Create Group"
  13.  Select the newly created group and pick "Add Users To Group" from the "Group Actions" dropdown
  14.  Check the box next to the "gosource-root" user
  15.  Click "Add Users"

That's it. The organisation account is now ready to be used. The provisioning of an ALM or project environments can now commence via the gosource-administration role, or manually via the gosource-root user.
