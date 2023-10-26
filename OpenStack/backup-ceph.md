# Backup and Restore

**1. Ceph Configuration**

- *Command:* There isn't a specific Ceph command for this. Simply copy the configuration files.
- *Steps:*
  - Locate the Ceph configuration files in the `/etc/ceph/` directory.
  - Use the `cp` or `rsync` command to copy the `ceph.conf` and `ceph.client.admin.keyring` files to a secure location.

**2. Monitor State**

- *Command:* There isn't a specific Ceph command for this. You can use standard file copy commands.
- *Steps:*
  - Identify the Ceph monitor nodes. You can use the following command to do this:

    ```
    ceph mon stat
    ```

    or

    ```
    ceph mon dump
    ```

  - To check the current monitor quorum status and monitor health, use the following command:

       ```
       ceph quorum_status
       ```

  - For each monitor node, copy the monitor store data and monitor map files:

       ```
       cp -r /var/lib/ceph/mon/ceph-<mon-id> /path/to/backup/
       ```

    or

       ```
       ceph mon dump <mon-id> > <backup-file>
       ```

  - Verify the backup file. You can use the following command to do this:

    ```
    ceph mon check <backup-file>

    ```

  - Restore the monitor data from the backup file. You can use the following command to do this:

    ```
    ceph mon restore <mon-id> <backup-file>
    ```

**3. OSD Metadata**

- *Command:* There isn't a specific Ceph command for this. Use file copy commands.
- *Steps:*

  - To gather OSD information, use the following command:

    ```
    ceph osd tree
    ```

  - To gather OSD information, use the following command:

       ```
       ceph osd dump > osd_dump.txt
       ```

    or

        ```
        ceph osd dump <osd-id> > <backup-file>
        ```
  - Copy the OSD map and crush map files:

       ```
       cp /var/lib/ceph/osd/ceph-<osd-id>/fsid  /path/to/backup/
       cp /var/lib/ceph/osd/ceph-<osd-id>/whoami  /path/to/backup/
       cp /etc/ceph/osd/ceph-<osd-id>/keyring /path/to/backup/
       ```

  - Verify the backup file. You can use the following command to do this:

    ```
    ceph osd check <backup-file>
    ```

  - Create a new OSD. You can use the following command to do this:

    ```
    ceph osd create
    ```

  - Restore the OSD data from the backup file. You can use the following command to do this:

    ```
    ceph osd restore <osd-id> <backup-file>
    ```

**4. Data Backups**

- **RBD Images**
  - *Commands:*
    - To create an RBD snapshot:

         ```
         rbd snap create <pool>/<image>@snapshot-name
         ```

    - To export an RBD snapshot:

         ```
         rbd export <pool>/<image>@snapshot-name /path/to/backup/image-export.img
         ```

    - To import an RBD snapshot:
- **CephFS**
  - *Command:*
    - Use the following command to create a CephFS metadata dump:

         ```
         ceph fs dump > cephfs_dump.txt
         ```

  - Restore the metadata from the backup file. You can use the following command to do this:

      ```
      ceph fs restore <fs-name> <backup-file>
      ```

  - Mount the Ceph file system. You can use the following command to do this:

      ```
      mount -t ceph <fs-name> <mount-point>
      ```

**5. Database Backups**

- **Ceph Manager Database**
  - *Commands:*
    - Use `ceph-mgr` to create a database backup:

         ```
         ceph-mgr ceph fsid dump --format=json-pretty > mgr-database-backup.json
         ```

**6. Cluster Monitoring and Logs**

- *Commands:*
  - To copy log files, you can use standard file copy commands. Logs are typically located in `/var/log/ceph/` on Ceph nodes.
