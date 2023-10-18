-- initial generation from csvkit using csvsql.
-- TODO: sqlfluff

CREATE TABLE "goodreads_books" (
  "Book Id" DECIMAL NOT NULL, 
  "Title" VARCHAR NOT NULL, 
  "Author" VARCHAR NOT NULL, 
  "Author l-f" VARCHAR NOT NULL, 
  "Additional Authors" VARCHAR, 
  "ISBN" VARCHAR NOT NULL, 
  "ISBN13" VARCHAR NOT NULL, 
  "My Rating" DECIMAL NOT NULL, 
  "Average Rating" DECIMAL NOT NULL, 
  "Publisher" VARCHAR, 
  "Binding" VARCHAR NOT NULL, 
  "Number of Pages" DECIMAL, 
  "Year Published" DECIMAL, 
  "Original Publication Year" DECIMAL, 
  "Date Read" DATE, 
  "Date Added" DATE NOT NULL, 
  "Bookshelves" BOOLEAN, 
  "Bookshelves with positions" BOOLEAN, 
  "Exclusive Shelf" VARCHAR NOT NULL, 
  "My Review" VARCHAR, 
  "Spoiler" BOOLEAN, 
  "Private Notes" BOOLEAN, 
  "Read Count" BOOLEAN NOT NULL, 
  "Owned Copies" BOOLEAN NOT NULL
);
