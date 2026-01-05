-- Represent books owned by members with a unique constraints on the isbn
CREATE TABLE "books"(
    "id" SERIAL PRIMARY KEY,
    "title" VARCHAR(255) NOT NULL,
    "isbn" VARCHAR(17) UNIQUE
);

-- Represent authors of the books
CREATE TABLE "authors" (
    "id" SERIAL PRIMARY KEY,
    "first_name" VARCHAR(255) NOT NULL,
    "last_name" VARCHAR(255) NOT NULL
);

-- Represent the many-to-many relationship between books and authors with a composite primary key
CREATE TABLE "book_authors" (
    "book_id" INTEGER NOT NULL,
    "author_id" INTEGER NOT NULL,
    PRIMARY KEY(book_id, author_id),
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE,
    FOREIGN KEY(author_id) REFERENCES authors(id) ON DELETE CASCADE
);

-- Represent publishers of the member books
CREATE TABLE "publishers" (
    "id" SERIAL PRIMARY KEY,
    "publisher" VARCHAR(255) UNIQUE
);

-- Represent that a book can have multiple publishers and a publisher can publish many books
CREATE TABLE "book_publishers" (
    "book_id" INTEGER,
    "publisher_id" INTEGER,
    PRIMARY KEY(book_id, publisher_id),
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE,
    FOREIGN KEY(publisher_id) REFERENCES publishers(id) ON DELETE CASCADE
);

-- Represent addition data about the books
CREATE TABLE "meta_data" (
    "id" SERIAL PRIMARY KEY,
    "book_id" INTEGER NOT NULL,
    "edition" VARCHAR(17),
    "year_published" SMALLINT,
    "avg_rating" NUMERIC(3,2),
    "binding" VARCHAR(20) CHECK("binding" IN ('paperback', 'kindle edition', 'hardcover', 'spiral-bound')),
    "pages" SMALLINT,
    "date_added" DATE NOT NULL DEFAULT CURRENT_DATE,
    "cover_image_url" VARCHAR(255) DEFAULT NULL,
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
);

-- Represent different labels for organizing and categorizing books by genre/type and theme
CREATE TABLE "tags" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(100) NOT NULL UNIQUE,
    "description" VARCHAR(255) NOT NULL
);

-- Represent the different categories associated with each book
CREATE TABLE "book_tags" (
    "book_id" INTEGER NOT NULL,
    "tag_id" INTEGER NOT NULL,
    PRIMARY KEY(book_id, tag_id),
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE,
    FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- Represent members that have joined the community
CREATE TABLE "members" (
    "id" SERIAL PRIMARY KEY,
    "first_name" VARCHAR(255) NOT NULL,
    "last_name" VARCHAR(255) NOT NULL,
    "username" VARCHAR(255) NOT NULL UNIQUE,
    "email" VARCHAR(255) NOT NULL UNIQUE,
    "joined" DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Represent books availble to borrow from different members. The bookshelf is like the physical copy of the book owned by members
CREATE TABLE "bookshelf" (
    "id" SERIAL PRIMARY KEY,
    "book_id" INTEGER NOT NULL,
    "owner_member_id" INTEGER NOT NULL,
    -- when the book is no longer being lend reset value to null
    "lent_to_member_id" INTEGER DEFAULT NULL,
    "date_added" DATE NOT NULL DEFAULT CURRENT_DATE,
    "status" VARCHAR(20) NOT NULL CHECK("status" IN ('available', 'lost', 'checked-out', 'not for loan')),
    CONSTRAINT "one_copy_per_owner" UNIQUE(owner_member_id, book_id),
    -- Add constraints for keeping checkout consistent
    CONSTRAINT "checkout_consistency"
        CHECK(
            ("status" = 'checked-out' AND lent_to_member_id IS NOT NULL)
            OR
            ("status" <> 'checked-out' AND lent_to_member_id IS NULL)
        ),
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE,
    FOREIGN KEY(owner_member_id) REFERENCES members(id) ON DELETE CASCADE,
    FOREIGN KEY(lent_to_member_id) REFERENCES members(id) ON DELETE CASCADE
);


-- Represent the reading status of a book for members
CREATE TABLE "member_reading_log" (
    "id" SERIAL PRIMARY KEY,
    "book_id" INTEGER,
    "member_id" INTEGER,
    "reading_status" VARCHAR(20) CHECK("status" IN ('to-read', 'reading', 'read')),
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE,
    FOREIGN KEY(member_id) REFERENCES members(id) ON DELETE CASCADE
);

-- Represent member reviews of books
CREATE TABLE "member_reviews" (
    "id" SERIAL PRIMARY KEY,
    "member_id" INTEGER,
    "book_id" INTEGER,
    "review" TEXT,
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE,
    FOREIGN KEY(member_id) REFERENCES members(id) ON DELETE CASCADE
);


-- Represent member ratings of books
CREATE TABLE "member_ratings" (
    "id" SERIAL PRIMARY KEY,
    "rating" INTEGER CHECK("rating" BETWEEN 0 AND 5),
    "book_id" INTEGER NOT NULL,
    "member_id" INTEGER NOT NULL,
    -- unique constrains to make sure a member can only give one rating to a book
    UNIQUE(member_id, book_id),
    FOREIGN KEY(member_id) REFERENCES members(id) ON DELETE CASCADE,
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
);

-- Create a table to hold data captured from trigger for when a member is deleted to keep a record log
-- https://www.postgresql.org/docs/current/plpgsql-trigger.html

CREATE TABLE deleted_members_audit (
    "audit_id" SERIAL PRIMARY KEY,
    "member_id" INTEGER NOT NULL,
    "first_name" VARCHAR(255) NOT NULL,
    "last_name" VARCHAR(255) NOT NULL,
    "username" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "joined" DATE NOT NULL,

    "deleted_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "deleted_by" TEXT NOT NULL DEFAULT current_user
);

CREATE FUNCTION log_deleted_member() RETURNS trigger AS $log_deleted_member$
    BEGIN
        INSERT INTO deleted_members_audit (
            member_id, first_name, last_name, username, email, joined, deleted_at, deleted_by
        )
        VALUES (
            OLD.id, OLD.first_name, OLD.last_name, OLD.username, OLD.email, OLD.joined, now(), current_user
        );

        RETURN OLD;
    END;
$log_deleted_member$ LANGUAGE plpgsql;

CREATE TRIGGER members_after_delete_log
AFTER DELETE ON members
FOR EACH ROW
EXECUTE FUNCTION log_deleted_member();


-- Add Indexes

CREATE INDEX book_titles_index = books (title);

CREATE INDEX member_name_index ON members (first_name, last_name);
CREATE INDEX member_reviews_book_id_index = member_reviews (book_id);

CREATE INDEX author_names_index ON authors (first_name, last_name);

CREATE INDEX meta_data_book_id_index ON meta_data (book_id);

CREATE INDEX bookshelf_book_id_index ON bookshelf (book_id);
CREATE INDEX bookshelf_book_id_index ON bookshelf (owner_member_id);
CREATE INDEX bookshelf_book_id_index ON bookshelf (lent_to_member_id);
CREATE INDEX bookshelf_availble_books_index ON bookshelf (book_id);
    WHERE status = 'available';

