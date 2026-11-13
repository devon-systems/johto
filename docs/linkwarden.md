# Linkwarden

Linkwarden runs on Goldenrod at `https://linkwarden.cute.haus`. Pocket ID
allows the `Family` group to sign in. Password login is enabled as a fallback;
public registration is disabled. Users created through Pocket ID can sign in
and create their first password at `/settings/password` without an old password.
The Pocket ID client uses the exact callback
`https://linkwarden.cute.haus/api/v1/auth/callback/oidc` and requires PKCE.

Flux deploys the application and Meilisearch from `k8s/linkwarden`. The pinned
Linkwarden image runs Prisma migrations before starting its web and worker
processes. The `linkwarden` role owns its database in `pg-shared`.

Archives are stored in `/mnt/Data/apps/linkwarden`, owned by UID/GID 1000.
Comin creates this directory and configures a daily restic backup. Deploy the
host configuration before enabling the workload. Meilisearch uses a local-path
volume on Goldenrod and can rebuild its index from PostgreSQL.

Barman backs up the database separately from the archive files. When restoring,
select compatible database and archive backup times. A Git revert changes the
container image but does not reverse database migrations. Before downgrading,
check migration compatibility and restore the database if necessary.

The database password appears in both `linkwarden-pg-creds.sops.yaml` and the
`DATABASE_URL` in `linkwarden-env.sops.yaml`. Update both when rotating it.
The OIDC client secret and Meilisearch key are also in `linkwarden-env.sops.yaml`.

Meilisearch version updates require manual review because the on-disk index
format can change between minor releases. Plan and test the index migration
before merging an update. Linkwarden exits if its search worker cannot connect
to Meilisearch.

`MEILI_UPGRADE_DB=true` permits the reviewed image to migrate its index at
startup. Before each version upgrade, take a Meilisearch snapshot or a cold
copy of the index. The pre-1.56.0 recovery copy is retained on Goldenrod at
`/mnt/Data/apps/linkwarden/meilisearch-before-1.56.0` and covered by restic.
