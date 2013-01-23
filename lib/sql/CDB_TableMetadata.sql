CREATE TABLE IF NOT EXISTS
  public.CDB_TableMetadata (
    tabname regclass not null primary key,
    updated_at timestamp with time zone not null default now()
  );

-- Anyone can see this, but updates are only possible trough
-- the security definer trigger
GRANT SELECT ON public.CDB_TableMetadata TO public;

-- Trigger logging updated_at in the CDB_TableMetadata
-- Attach to tables like this:
--
--   CREATE trigger track_updates
--    AFTER INSERT OR UPDATE OR TRUNCATE ON <tablename>
--    FOR EACH STATEMENT
--    EXECUTE PROCEDURE cdb_tablemetadata_trigger(); 
--
-- NOTE: _never_ attach to CDB_TableMetadata ...
--
CREATE OR REPLACE FUNCTION CDB_TableMetadata_Trigger()
RETURNS trigger AS
$$
BEGIN
  WITH nv as (
    SELECT TG_RELID as tabname, NOW() as t
  ), updated as (
    UPDATE public.CDB_TableMetadata x SET updated_at = nv.t
    FROM nv WHERE x.tabname = nv.tabname
    RETURNING x.tabname
  )
  INSERT INTO public.CDB_TableMetadata SELECT nv.*
  FROM nv LEFT JOIN updated USING(tabname)
  WHERE updated.tabname IS NULL;

  -- TODO: PERFORM NOTIFY something ?

  RETURN NULL;
END;
$$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER;
