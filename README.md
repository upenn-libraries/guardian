# README for `guardian`

Guardian is an orchestration script for assembling objects into Glacier-ready packages, transferring to Glacier, and returning relevant Glacier information from successful transfers.

## Requirements

* Ruby 2.3.0
* MySQL
* Amazon Glacier credentials

## Supported Applications

Guardian currently supports assembly and transfer of objects for the following applications:

* [Bulwark](https://github.com/upenn-libraries/bulwark) using [git-annex](https://git-annex.branchable.com/)

## Usage

This workflow is two-fold, generating YML manifests for data to be transferred to Glacier based on a CSV manifest file.  This repo contains an [example of the template for the manifest linked here](examples/example_guardian_manifest.csv).

The `guardian-make-todo` script uses the [todo_runner gem](https://github.com/upenn-libraries/todo_runner) to generate individual YML manifests, one per archive to be sent to Glacier.  The `guardian-glacier-transfer` script uses the [stronghold gem](https://github.com/upenn-libraries/stronghold) to generate each archival ZIP package and transfer to Glacier.  Glacier metadata (the archive ID and associated description) is recorded in a text file stored in a location specified by the $LOCAL_LOG_FILE_PATH variable at runtime, and is loaded into the MySQL database for long-term storage at the end of the run. 

To generate the YAML manifests, issue the following command:

```bash 
ruby guardian-make-todo $SOURCE_CSV $DESTINATION
```

Where `$SOURCE_CSV` is the CSV file containing the data for the YAML manifests, and `$DESTINATION` is the directory on the filesystem where the manifests will be written to.

To begin the Glacier transfer process, issue the following command:

```bash
ruby guardian-glacier-transfer $PATH_TO_TODO_FILE
```

Where `$PATH_TO_TODO_FILE` is the path on the filesystem to the todo file (YAML manifest) that represents an object being transferred to Glacier.  Note that this script runs on a per-file basis.  To upload in batches, a bash script or partial matching with a wildcard character is recommended.

## Production

This workflow runs in Docker Swarm in production with Ruby and MySQL as two separate services.  Local mounts for three filesystem locations are specified at runtime as Swarm does not currently support the use of `env_file` in docker-compose.

### Deployment

To deploy in Swarm, issue the following command:

```bash
LOCAL_BG_REMOTE=/local/abs/path/to/data LOCAL_ZIP_WORKSPACE=/local/abs/path/to/workspace LOCAL_LOG_FILE=/local/abs/path/to/logsdir/ docker stack deploy -c docker-compose.yml guardian
```

The database container should take ~30 seconds to perform a health check before becoming available.  Once the service is available, execute the following command to initialize the database:

```bash
docker exec $GUARDIAN_CONTAINER rake db_migrate
```

You should see the following output:

```bash
== 20180207220555 GlacierArchives: migrating ==================================
-- adapter_name()
   -> 0.0000s
-- adapter_name()
   -> 0.0000s
-- adapter_name()
   -> 0.0000s
-- create_table(:glacier_archives, {:options=>"ENGINE=InnoDB", :id=>:integer})
   -> 0.0092s
== 20180207220555 GlacierArchives: migrated (0.0095s) =========================
```

Your deployment is now ready for use.

### Usage

Workflow syntax in Swarm is as follows:

```bash
docker cp $CSV_MANIFEST $GUARDIAN_CONTAIER:/usr/src/app/.
docker exec -it $GUARDIAN_CONTAINER ruby guardian-make-todo $CSV_MANIFEST todos/
docker exec -it $GUARDIAN_CONTAINER bash -c "ruby guardian-glacier-transfer todos/*.todo"
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/upenn-libraries/guardian](https://github.com/upenn-libraries/guardian).

## License

This code is available as open source under the terms of the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0).
