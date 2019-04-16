# README for `guardian`

Guardian is a set of orchestration tools for assembling objects into Glacier-ready packages, transferring to Glacier, and recording relevant Glacier information from successful transfers in a local database.

## Requirements

* Ruby 2.3.0
* MySQL
* Amazon Glacier credentials

## Supported Applications

Guardian currently supports assembly and transfer of objects for the following applications:

* [Bulwark](https://github.com/upenn-libraries/bulwark) using [git-annex](https://git-annex.branchable.com/)

* [OPenn](https://openn.library.upenn.edu) using rsync

## Usage

This workflow is two-fold, generating YML manifests for data to be transferred to Glacier based on a CSV manifest file.  This repo contains an [example of the template for the manifest linked here](examples/example_guardian_manifest.csv).

The `guardian-make-todo` script uses the [todo_runner gem](https://github.com/upenn-libraries/todo_runner) to generate individual YML manifests, one per archive to be sent to Glacier.  The `guardian-glacier-transfer` script uses the [stronghold gem](https://github.com/upenn-libraries/stronghold) to generate each archival ZIP package and transfer to Glacier.  Glacier metadata (the archive ID and associated description) is loaded into the MySQL database for long-term storage upon each successful transfer. 

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
docker cp $CSV_MANIFEST $GUARDIAN_CONTAINER:/usr/src/app/.
docker exec -it $GUARDIAN_CONTAINER ruby guardian-make-todo $CSV_MANIFEST todos/
docker exec -it $GUARDIAN_CONTAINER bash -c "ruby guardian-glacier-transfer todos/*.todo"
```

#### guardian-glacier-transfer

The `guardian-glacier-transfer` script is a todo-runner that fetches, zips, and pushes packages of data to Glacier.

The todo-runner tasks, in order, are:

1. `:validate_todo_file` -- confirm required fields are present and verification values are valid 
2. `:fetch_source` -- retrieve the source data specified in the todo-file
3. `:verify_fetch`(*) -- if implemented, verify fetched data's content integrity
4. `:zip` -- package source data in single zip file; store sha-256
5. `:verify_zip`(*) -- if implemented *and* requested, verify zipped archive content integrity
6. `glacier` -- push to Glacier and record information in FortDB database

(*) This feature implemented only for OPenn-rsync packages. 


Sample YAML todo file:

    ---
    :todo_base: directive_name_1
    :source: "/$DOCKER_PATH/directive_name_1"
    :workspace: workspace/directive_name_1
    :compressed_destination: zip-workspace/directive_name_1/directive_name_1.zip
    :verification_destination: verify-workspace/directive_name_1
    :cleanup_directories: workspace/directive_name_1|zip-workspace/directive_name_1|verify-workspace/directive_name_1
    :glacier_description: '{"owner":"katherly","description":"directive_name_1"}'
    :glacier_vault: vault_name
    :application: bulwark
    :method: gitannex
    :verify_compressed_archive: 'true'

The YAML todo file keys are:

- `:todo_base` -- the basename of the data package (e.g., 'mscodex1234')
    - used in logging messages
- `:source` -- location of the source data
    - may be: a locally mounted path for a Bulwark-gitannex repo (e.g., `git_share/mscodex1234`); or a full rsync URL for OPenn-rsync (e.g., `rsync://openn.library.upenn.edu/OPenn/Data/0002/mscodex1234`)
    - used by `:fetch_source` task
- `:workspace` -- path on the guardian server to which the data will be fetched
    - used by `:fetch_source` task
- `:compressed_destination` -- path on the guardian server to the compressed zip file
    - used by `:zip`, `:verify_zip` and `:glacier` tasks
- `:verification_destination` -- path on the guardian server to which to decompress the zipped archive for contents verification; required if `:verify_compressed_archive` is `true`
    - used by `:verify_zip` task
- `:cleanup_directories` -- pipe-separated list of directories to remove upon transfer completion
    - used by `:glacier` task
- `:glacier_description` -- JSON blob of archived description for upload to glacier as archive metadata and for storage in FortDb
    - must be a valid JSON string
    - used throughout
- `:glacier_vault` -- name of the Glacier vault to which the archive should be pushed; e.g., 'openn'
    - used by `:glacier` task
- `:application` -- the source application for the archive; 'bulwark' or 'openn'
    - used by `:fetch_source`, `:verify_fetch`, and `:verify_zip` tasks
- `:method` -- archive retrieval method, 'gitannex' for 'bulwark' and 'rsync' for 'openn'
    - used by `:fetch_source`, `:verify_fetch`, and `:verify_zip` tasks
- `:verify_compressed_archive` -- optional; 'true' if zip file contents should be verified
    - used by `:verify_zip` task
    
#### Data validation and checksumming

When each zip archive is created the `:glacier_description` value is updated 
with the SHA-256 checksum of the zipped archive. For example,

```yaml
:archive_description: '{"owner":"demery","repository":"Walters Art Museum","openn_repo_id":"0020","description":"W681","archive_checksum":"094b114a0d79f09e6be1c4c893e4e1076d9432ff3218eac16d82fa2f6c30ecb5","archive_checksum_algorithm":"sha256"}'
```
    
Note that both 'archive_checksum' and 'archive_checksum_algorithm' properties have been added to the description.

When the `#verify_fetch` method is implemented for a given application-method combination (e.g, openn + rsync), this method should verify the source. This may be done by using a checksum manifest, for example. The method should return `true` only upon successful validation of the source data.

The `:verify_zip` task invokes the `#verify_zip` method when `:verify_compressed_archive` has a value of `'true'`. When the `#verify_zip` method is implemented for a given application-method combination (e.g, openn + rsync), this method should:

1. decompress the zipped archive to `:verification_destination`, and
2. verify the decompressed content *such that the verified fetched and zip contents are confirmed to be identical*.

Important: If `:verify_compressed_archive` is `true`, then `verification_destination` **must** be provided; otherwise, the todo-file will fail validation.

If the `#verify_zip` method returns `true`, the `:glacier_description` value is updated noting the zip contents have been verified. In the following description, `archive_contents_verified` has the value `true`.
                                            
```yaml
:archive_description: '{"owner":"demery","repository":"Walters Art Museum","openn_repo_id":"0020","description":"W681","archive_checksum":"094b114a0d79f09e6be1c4c893e4e1076d9432ff3218eac16d82fa2f6c30ecb5","archive_checksum_algorithm":"sha256""archive_contents_verified":true}'
```

NB: When an archive has been retrieved from Glacier, if the 'archive_checksum' is present **and** 'archive_contents_verified' is `true`, then the integrity of the archive content can be checked using the 'archive_checksum' and without having to verify the contents themselves. 

#### Log level

By default log level is set to `Logger::INFO`. To control the log level set the `GUARDIAN_LOG_LEVEL` environment variable to `DEBUG`, `INFO`, `WARN`, `ERROR`, or `FATAL`. 

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/upenn-libraries/guardian](https://github.com/upenn-libraries/guardian).

## License

This code is available as open source under the terms of the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0).
