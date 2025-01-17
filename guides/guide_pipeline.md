# Data pipeline guide

A sysadmin guide for setting up the Bohemia data "pipeline"

## Standards and "rules"  

The data processing scripts that migrate data from the ODK Aggregate server to project databases require that:

1. All `.xml` forms deployed on the ODK Aggregate server be generated via the `xls2xform` functionality (or via the python scripts for conversion in the `scripts` sub-directory), _not_ via online converters.

2. All repeat elements (ie, xlsform rows in which the type is `begin repeat`) must contain `repeat_` prefix in the `name` field.

3. No non-repeat elements should contain the word `repeat` in the name field.

4. All group elements (ie, xlsform rows in which the type is `begin group`) must contain `group_` prefix in the `name` field.

5. No non-group elements should contain the word `group` in the name field.

6. All note elements (ie, xlsform rows in which the type is `note`) must contain `note_` prefix in the `name` field.

7. No non-note elements should contain the word `note` in the name field.


## General overview

First, the ODK utilities in the `bohemia` R package (main wrapper function: `odk_get_data`) are used for fetching data from ODK Aggregate databases. Second, cleaning/formatting functions in the `bohemia` R package are used to process the data so as to conform with database standards. Third, the script in `scripts/bohemia_db_schema.sql` is used to set up the PosgreSQL database. Finally, upload functions in the `bohemia` R package are used to send data to the database.

The above is all run automatically every N minutes via crontab which executes the script at `scripts/run_odk_get_data_cron.sh`.

## Database set up

### Deploy  

- Go to the Amazon RDS page: https://eu-west-3.console.aws.amazon.com/rds/home?region=eu-west-3#  
- Click "Create database"  
- Select "Amazon Aurora" and ensure the edition is "with PostgreSQL compatibility"  
- Set version to 11.6  
- Select "Production" under "Templates"  
- For DB cluster identifier, type "bohemiacluster"  
- For master username, use the master username in the credentials file: `psql_master_username`
- For master password, use the master password in the credentials file: `psql_master_password`
- Set "DB instance size" to "Memory optimized" and leave the instance type as is (2 cpus, 16 g ram)  
- For availability and durability, select yes for creating a different node in a different zone  
- Use default VPC  
- Click additional connectivity configuration  
- Under "Public access", click "yes"  
- For VPC security group, click "Create new" and call it "bohemiadbgroup"  
- Keep database port as 5432  
- For database authentication, select "Password and IAM database authentication"  
- Under additional configuration:
  - Intitial database name: `bohemia`  
- You'll now see the `bohemiacluster` database set up at `endpoint` (in the credentials file)
- In the browswer, go to https://eu-west-3.console.aws.amazon.com/ec2/v2/home?region=eu-west-3#SecurityGroups and modify inbound and outbound rules to accept all traffic.  

- You can connect to the db like this:  
```
psql \
   --host=<ENDPOINT> \
   --port=5432 \
   --username=<psql_master_username>\
   --password
```
- A password will be prompted  


### Populate

- Connect to the db (see above)  
- Run the following:  
```
CREATE DATABASE bohemia;
```
- Now disconnect and re-connect to the database as per below:

```
psql \
   --host=<ENDPOINT> \
   --port=5432 \
   --username=<psql_master_username>\
   --password\
   --dbname=bohemia
```

- Copy paste the code from `scripts/bohemia_db_schema.sql`  

### Creating the "clean" tables

- Clean tables are structurally a copy of their similarly named "non-clean" counterparts (with the `clean_` prefix).  
- Clean tables differ from their non-clean counterparts in that they may undergo manual modifications (ie, "data cleaning").  
- These manual modifications are stored in the `xxx` script.  

At first-go, to create the clean tables, run:
```
create_clean_db()
```  

To drop all of the clean tables, run:
```
create_clean_db(drop_all = TRUE)
```

To carry out the "cleaning" (ie, execute changes on the newly-created clean tables), run:
```
clean_db()
```





## Data Update

- Having retrieved the data, the code for updating it is in `scripts/update_database.R`.  
- As mentioned in the General Overview section, the `bohemia` R package (main wrapper function: `odk_get_data`) used for fetching data from ODK is run every N minutes automatically. This section details the steps to deploy and set it up on AWS EC2 instances.

### CronTab Set Up

1. SSH into the `shiny` server (deployed at bohemia.team). The reason for using the shiny server is that it has the necessary R packages.

2. Run (on the shell):

   `crontab -e`

   a. In the crontab editor opened, type in for an automatic run every 42 minutes past the hour:
```
   42 * * * * sh /home/ubuntu/Documents/bohemia/scripts/run_odk_get_data_cron.sh > /home/ubuntu/Documents/bohemia/logs/backup.log 2>&1
```
   b. Save and exit the editor.

3. Wait for the time set to verify the job is run by checking the syslog for the entry:

   `tail -f /var/log/syslog | grep CRON`



### Backups

- Backups are automated and covered in https://github.com/databrew/bohemia/blob/master/guides/guide_backups.md
- Backups for creating data dumps and storing on S3 are on the `odk` server.  
