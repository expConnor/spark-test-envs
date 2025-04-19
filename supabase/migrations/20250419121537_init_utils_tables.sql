
-- Utils schema ==================================================================

CREATE SCHEMA IF NOT EXISTS utils;

-- Table to store the SQL scripts that are used to upload fanfix and onlyfans data into the creators tables

create table utils.fanfix_onlyfans_data_scripts (
  id serial not null,
  script_name text not null,
  sql_code text not null,
  target_csv_file_name text null,
  notes text null,
  constraint sql_scripts_pkey primary key (id),
  constraint sql_scripts_script_name_key unique (script_name)
) TABLESPACE pg_default;
