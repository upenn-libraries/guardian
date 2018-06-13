# README for `guardian`

Guardian is an orchestration script for assembling objects into Glacier-ready packages, transferring to Glacier, and returning relevant Glacier information from successful transfers.

## Requirements

* Ruby 2.3.0
* Amazon Glacier credentials

## Supported Applications

Guardian currently supports assembly and transfer of objects for the following applications:

* Bulwark and git-annex (in development)

## Usage

This script relies on the `todo_runner` gem.  YAML manifests are generated from information in a CSV file.  See `example_guardian_sheet.csv` for a template of the CSV.

To generate the YAML manifests, issue the following command:

```bash 
ruby guardian-make-todo $SOURCE_CSV $DESTINATION
```

Where `$SOURCE_CSV` is the CSV file containing the data for the YAML manifests, and `$DESTINATION` is the directory on the filesystem where the manifests will be written to.

To begin the transfer process, issue the following command:

```bash
ruby guardian-glacier-transfer $PATH_TO_TODO_FILE
```

Where `$PATH_TO_TODO_FILE` is the path on the filesystem to the todo file (YAML manifest) that represents an object being transferred to Glacier.  Note that this script runs on a per-file basis.  To upload in batches, a bash script is recommended.