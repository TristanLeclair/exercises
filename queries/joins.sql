-- How can you produce a list of the start times for bookings by members named
-- 'David Farrell'?
SELECT
  starttime
FROM
  cd.bookings AS B
  JOIN (
    SELECT
      *
    FROM
      cd.members
    WHERE
      firstname = 'David'
      AND surname = 'Farrell'
  ) AS M2 ON B.memid = M2.memid;

-- How can you produce a list of the start times for bookings for tennis
-- courts, for the date '2012-09-21'? Return a list of start time and facility
-- name pairings, ordered by the time.
SELECT
  starttime AS start,
  name
FROM
  (
    SELECT
      *
    FROM
      cd.facilities
    WHERE
      name LIKE 'T%C%'
  ) AS fac
  JOIN (
    SELECT
      *
    FROM
      cd.bookings
    WHERE
      date (starttime) = '2012-09-21'
  ) AS bkgs ON fac.facid = bkgs.facid
ORDER BY
  starttime ASC;

-- How can you output a list of all members who have recommended another
-- member? Ensure that there are no duplicates in the list, and that results
-- are ordered by (surname, firstname).
SELECT DISTINCT
  (A.firstname),
  A.surname
FROM
  (
    (
      SELECT
        *
      FROM
        cd.members
    ) AS A
    JOIN (
      SELECT
        *
      FROM
        cd.members
    ) AS B ON A.memid = B.recommendedby
  )
ORDER BY
  surname,
  firstname;

-- How can you output a list of all members, including the individual who
-- recommended them (if any)? Ensure that results are ordered by (surname,
-- firstname).
SELECT
  mem.firstname AS memfname,
  mem.surname AS memsname,
  rec.firstname AS recfname,
  rec.surname AS recsname
FROM
  (
    cd.members AS mem
    LEFT OUTER JOIN cd.members AS rec ON mem.recommendedby = rec.memid
  )
ORDER BY
  mem.surname,
  mem.firstname;

-- How can you produce a list of all members who have used a tennis court?
-- Include in your output the name of the court, and the name of the member
-- formatted as a single column. Ensure no duplicate data, and order by the
-- member name followed by the facility name.
SELECT DISTINCT
  (membkgs.firstname || ' ' || membkgs.surname) AS member,
  fac.name AS facility
FROM
  (
    (
      cd.members AS mem
      JOIN cd.bookings AS bkgs ON mem.memid = bkgs.memid
    ) AS membkgs
    JOIN cd.facilities AS fac ON membkgs.facid = fac.facid
  )
WHERE
  fac.name IN ('Tennis Court 1', 'Tennis Court 2')
ORDER BY
  member,
  facility;

-- How can you produce a list of bookings on the day of 2012-09-14 which will
-- cost the member (or guest) more than $30? Remember that guests have
-- different costs to members (the listed costs are per half-hour 'slot'), and
-- the guest user is always ID 0. Include in your output the name of the
-- facility, the name of the member formatted as a single column, and the cost.
-- Order by descending cost, and do not use any subqueries.
SELECT
  (firstname || ' ' || surname) AS member,
  name AS facility,
  CASE
    WHEN bkgs.memid = 0 THEN (slots * guestcost)
    WHEN bkgs.memid <> 0 THEN (slots * membercost)
  END AS cost
FROM
  cd.members mems
  JOIN cd.bookings bkgs ON mems.memid = bkgs.memid
  JOIN cd.facilities facs ON bkgs.facid = facs.facid
WHERE
  starttime::date = date '2012-09-14'
  AND CASE
  -- Is a guest and rental was more than 30$
    WHEN bkgs.memid = 0
    AND (slots * guestcost) > 30 THEN 1
    -- Is a member and rental was more than 30$
    WHEN bkgs.memid <> 0
    AND (slots * membercost) > 30 THEN 1
    ELSE 0
  END = 1
ORDER BY
  cost DESC;

-- How can you output a list of all members, including the individual who
-- recommended them (if any), without using any joins? Ensure that there are no
-- duplicates in the list, and that each firstname + surname pairing is
-- formatted as a column and ordered.
SELECT DISTINCT
  mems.firstname || ' ' || mems.surname AS member,
  (
    SELECT
      recs.firstname || ' ' || recs.surname AS recommender
    FROM
      cd.members recs
    WHERE
      recs.memid = mems.recommendedby
  )
FROM
  cd.members mems
ORDER BY
  "member";

-- The Produce a list of costly bookings exercise contained some messy logic:
-- we had to calculate the booking cost in both the WHERE clause and the CASE
-- statement. Try to simplify this calculation using subqueries. For reference,
-- the question was:
-- How can you produce a list of bookings on the day of 2012-09-14 which will
-- cost the member (or guest) more than $30? Remember that guests have
-- different costs to members (the listed costs are per half-hour 'slot'), and
-- the guest user is always ID 0. Include in your output the name of the
-- facility, the name of the member formatted as a single column, and the cost.
-- Order by descending cost. 
WITH
  BookingDetails AS (
    SELECT
      (firstname || ' ' || surname) AS member,
      name AS facility,
      CASE
        WHEN bkgs.memid = 0 THEN (slots * guestcost)
        WHEN bkgs.memid <> 0 THEN (slots * membercost)
      END AS cost
    FROM
      cd.members mems
      JOIN cd.bookings bkgs ON mems.memid = bkgs.memid
      JOIN cd.facilities facs ON bkgs.facid = facs.facid
    WHERE
      bkgs.starttime::date = DATE '2012-09-14'
  )
SELECT
  member,
  facility,
  cost
FROM
  BookingDetails
WHERE
  cost > 30
ORDER BY
  cost DESC;
