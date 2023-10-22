-- helps keep the replication file clean

CREATE TABLE books(
  id bigint,
  sku int,
  title text,
  topic text,
  PRIMARY KEY(id)
);
