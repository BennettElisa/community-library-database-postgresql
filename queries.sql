-- Find the title of all the books a member owns given the members first name and last name as "Elisa Bennett"
SELECT title
FROM books
WHERE books.id IN (
    SELECT bookshelf.book_id
    FROM bookshelf
    WHERE owner_member_id = (
        SELECT members.id
        FROM members
        WHERE first_name = 'Elisa' AND last_name = 'Bennett'
    )
);

-- Find number of books a member owns given the members username "theBaptistYogi"

SELECT COUNT(book_id)
FROM bookshelf
WHERE owner_member_id = (
    SELECT members.id
    FROM members
    WHERE username = 'theBaptistYogi'
);

-- Find out how many tags are associated with a particular book given the book name "Eat Feel Fresh"

SELECT COUNT(tag_id)
FROM book_tags
WHERE book_id = (
    SELECT id
    FROM books
    WHERE title LIKE '%Eat Feel Fresh%'
);

-- Find all the tag names associated with the book "Eat Feel Fresh" and label the row "book tags"

SELECT tags.name AS "Book Categories"
FROM tags
WHERE tags.id IN (
    SELECT tag_id
    FROM book_tags
    WHERE book_id = (
        SELECT id
        FROM books
        WHERE title LIKE '%Eat Feel Fresh%'
    )
);

-- Find out who owns "A New Earth" and/or if it's owned by multiple members and return the usernames of the members who own it

SELECT members.username
FROM bookshelf
JOIN members ON members.id = bookshelf.owner_member_id
WHERE book_id = (
        SELECT id
        FROM books
        WHERE title LIKE 'A New Earth%'
);


-- Find member reviews on any books written by - "Jay Shetty". Return the book title, review and member username

SELECT books.title, member_reviews.review, members.username AS "Review from"
FROM books
JOIN member_reviews ON member_reviews.book_id = books.id
JOIN members ON members.id = member_reviews.member_id
WHERE books.id IN (
    SELECT book_id
    FROM book_authors
    WHERE author_id = (
        SELECT authors.id
        FROM authors
        WHERE last_name = 'Shetty'
    )
);

-- Find out many members there are in the community and name the row "Total Members"

SELECT COUNT(id) AS "Total Members" FROM members;

-- Find the top 10 avg ratings and include the book name and order by rating and then title

SELECT title, avg_rating
FROM meta_data
JOIN books ON books.id = meta_data.book_id
ORDER BY avg_rating DESC, title ASC LIMIT 10;

-- Find the top 5 rated books from members in highest to lowest order and include the title of the book

SELECT books.title, rating
FROM member_ratings
JOIN books ON books.id = member_ratings.book_id
ORDER BY rating DESC LIMIT 5;

-- Find the description for the tag 'Yoga'

SELECT tags.description AS "tag description"
FROM tags
WHERE name = 'Yoga';

-- Find out how many books have the tag 'Spirituality'

SELECT COUNT(book_id)
FROM book_tags
WHERE tag_id = (
    SELECT id
    FROM tags
    WHERE name = 'Spirituality'
);

-- Show the titles of the books from the last query and who owns them

SELECT books.title, members.username
FROM book_tags
JOIN bookshelf ON bookshelf.book_id = book_tags.book_id
JOIN books ON books.id = book_tags.book_id
JOIN members ON members.id = bookshelf.owner_member_id
WHERE tag_id = (
    SELECT id
    FROM tags
    WHERE tags.name = 'Spirituality'
);


-- Find a book based on the isbn number "978-0691147215" and list the title, year published, pages, binding and the member who owns it

SELECT b.isbn, b.title, md.year_published, md.pages, md.binding, m.username AS "member with book"
FROM books AS b
JOIN meta_data AS md ON md.book_id = b.id
JOIN bookshelf AS bs ON bs.book_id = b.id
JOIN members AS m ON m.id = bs.owner_member_id
WHERE b.isbn = '978-0691147215';


-- Find a book by the first and last name of the author "Juile Schwartz Gottman"

SELECT title
FROM books
WHERE id = (
    SELECT book_id
    FROM book_authors
    WHERE author_id = (
        SELECT id
        FROM authors
        WHERE first_name = 'Julie' AND last_name LIKE '%Gottman%'
    )
);


-- Determine the username of the member who owns the book by the author found above and if it's availble to borrow

SELECT title, members.username, bs.status
FROM books
JOIN bookshelf AS bs ON bs.book_id = books.id
JOIN members ON members.id = bs.owner_member_id
WHERE books.id = (
    SELECT book_id
    FROM book_authors
    WHERE author_id = (
        SELECT id
        FROM authors
        WHERE first_name = 'Julie' AND last_name LIKE '%Gottman%'
    )
);


-- Find how many books are availble to borrow in the community library

SELECT COUNT(book_id) FROM bookshelf WHERE status = 'available';

-- Find the titles of all of books availble to borrow

SELECT title
FROM bookshelf AS bs
JOIN books ON books.id = bs.book_id
WHERE bs.status = 'available';

-- Add a new member

INSERT INTO "members" ("first_name", "last_name", "username", "email", "joined")
VALUES ('Carter', 'Zanke', 'ZankeCS151', 'carter@email.com', '2025-12-17');

-- Add a new book

INSERT INTO "books" ("title", "isbn")
VALUES ('Changes That Heal: Four Practical Steps to a Happier, Healthier You', '978-0310351788');

-- Add an author

INSERT INTO "authors" ("first_name", "last_name")
VALUES ('Roxy', 'Manning');

-- Add a publisher

INSERT INTO "publishers" ("publisher")
VALUES ('Shambhala');

-- Add a reivew of a book

INSERT INTO "member_reviews" ("member_id", "book_id", "review")
VALUES(
    (SELECT id FROM members WHERE username = 'ZankeCS151'),
    (SELECT id FROM books WHERE isbn = '978-0310351788'),
    'A down to earth and practical guide for growing into a person you enjoy hanging out with!'
);

-- Add a new tag to describe a book in the future

INSERT INTO "tags" ("name", "description")
VALUES ('Social Justice', 'Books about equity, anti-racism, and systemic change');

-- Create a book-tag relationship

INSERT INTO "book_tags" ("book_id", "tag_id")
VALUES (1, 1);

-- Create owner book relationship

INSERT INTO "bookshelf" ("book_id", "owner_member_id", "lent_to_member_id", "date_added", "status")
VALUES (1, 3, NULL, '2024-06-10', 'available'), (5, 2, 3, '2024-12-05', 'checked-out');

-- Update the status of a book

UPDATE "bookshelf"
SET "status" = 'available'
WHERE book_id = 5;


-- Safely test deleting a member with a ROLLBACK clause
BEGIN;

DELETE FROM "members"
WHERE id = 1;

SELECT * FROM deleted_members_audit;

ROLLBACK;

-- Delete a member

DELETE FROM "members"
WHERE id = 1;
