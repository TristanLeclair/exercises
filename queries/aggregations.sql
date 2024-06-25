-- We want to know how many facilities exist - simply produce a total count.
SELECT
  COUNT(*) AS COUNT
FROM
  cd.facilities;

-- Produce a count of the number of facilities that have a cost to guests of 10 or more.
SELECT
  COUNT(*) AS COUNT
FROM
  cd.facilities
WHERE
  guestcost >= 10;

-- Produce a count of the number of recommendations each member has made. Order by member ID.
SELECT
  recommendedby,
  COUNT(*)
FROM
  cd.members
WHERE
  recommendedby IS NOT NULL
GROUP BY
  recommendedby
ORDER BY
  recommendedby;

-- Produce a list of the total number of slots booked per facility.
-- For now, just produce an output table consisting of facility id and slots, sorted by facility id. 
SELECT
  facid,
  SUM(slots) AS "Total Slots"
FROM
  cd.bookings
GROUP BY
  facid
ORDER BY
  facid;

-- Produce a list of the total number of slots booked per facility in the month of September 2012.
-- Produce an output table consisting of facility id and slots, sorted by the number of slots. 
SELECT
  facid,
  SUM(slots) AS "Total Slots"
FROM
  cd.bookings
WHERE
  EXTRACT(
    YEAR
    FROM
      starttime
  ) = 2012
  AND EXTRACT(
    MONTH
    FROM
      starttime
  ) = 9
GROUP BY
  facid
ORDER BY
  "Total Slots";

-- Produce a list of the total number of slots booked per facility per month in the year of 2012.
-- Produce an output table consisting of facility id and slots, sorted by the id and month.
SELECT
  facid,
  EXTRACT(
    MONTH
    FROM
      starttime
  ) AS MONTH,
  SUM(slots) AS "Total Slots"
FROM
  cd.bookings
WHERE
  EXTRACT(
    YEAR
    FROM
      starttime
  ) = 2012
GROUP BY
  facid,
  MONTH
ORDER BY
  facid,
  MONTH;

--
--  Find the total number of members (including guests) who have made at least one booking. 
--
SELECT
  COUNT(DISTINCT memid)
FROM
  cd.bookings;

--
-- Produce a list of facilities with more than 1000 slots booked.
-- Produce an output table consisting of facility id and slots, sorted by facility id.
--
SELECT
  facid,
  SUM(slots) AS "Total Slots"
FROM
  cd.bookings
GROUP BY
  facid
HAVING
  SUM(slots) > 1000
ORDER BY
  facid;

--
-- Produce a list of facilities along with their total revenue. 
-- The output table should consist of facility name and revenue, sorted by revenue. 
-- Remember that there's a different cost for guests and members! 
--
SELECT
  facs.name,
  SUM(
    slots * CASE
      WHEN bkgs.memid = 0 THEN facs.guestcost
      ELSE facs.membercost
    END
  ) AS revenue
FROM
  (
    cd.facilities facs
    JOIN cd.bookings bkgs ON facs.facid = bkgs.facid
  )
GROUP BY
  facs.name
ORDER BY
  revenue;

-- Produce a list of facilities with a total revenue less than 1000.
-- Produce an output table consisting of facility name and revenue, sorted by revenue.
-- Remember that there's a different cost for guests and members!
SELECT
  name,
  revenue
FROM
  (
    SELECT
      facs.name,
      SUM(
        slots * CASE
          WHEN bkgs.memid = 0 THEN facs.guestcost
          ELSE facs.membercost
        END
      ) AS revenue
    FROM
      (
        cd.facilities facs
        JOIN cd.bookings bkgs ON facs.facid = bkgs.facid
      )
    GROUP BY
      facs.name
  ) AS revenues
WHERE
  revenue < 1000
ORDER BY
  revenue;

--
-- Output the facility id that has the highest number of slots booked.
-- For bonus points, try a version without a LIMIT clause.
-- This version will probably look messy! 
--
SELECT
  facid,
  SUM(slots) "Total Slots"
FROM
  cd.bookings
GROUP BY
  facid
HAVING
  SUM(slots) = (
    SELECT
      MAX("Total Slots")
    FROM
      (
        SELECT
          facid,
          SUM(slots) AS "Total Slots"
        FROM
          cd.bookings
        GROUP BY
          facid
      ) AS agg
  );

-- Also doable with
WITH
  SUM AS (
    SELECT
      facid,
      SUM(slots) AS totalslots
    FROM
      cd.bookings
    GROUP BY
      facid
  )
SELECT
  facid,
  totalslots
FROM
  SUM
WHERE
  totalslots = (
    SELECT
      MAX(totalslots)
    FROM
      SUM
  );

--
-- Produce a list of the total number of slots booked per facility per month in the year of 2012.
-- In this version, include output rows containing totals for all months per facility, and a total for all months for all facilities.
-- The output table should consist of facility id, month and slots, sorted by the id and month.
-- When calculating the aggregated values for all months and all facids, return null values in the month and facid columns. 
--
SELECT
  facid,
  EXTRACT(
    MONTH
    FROM
      starttime
  ) AS MONTH,
  SUM(slots) AS "slots"
FROM
  cd.bookings
WHERE
  EXTRACT(
    YEAR
    FROM
      starttime
  ) = 2012
GROUP BY
  ROLLUP (facid, MONTH)
ORDER BY
  facid,
  MONTH;

--
-- Produce a list of the total number of hours booked per facility,
-- remembering that a slot lasts half an hour.
-- The output table should consist of the facility id, name, and hours booked,
-- sorted by facility id.
-- Try formatting the hours to two decimal places.
--
SELECT
  bkgs.facid,
  facs.name,
  ROUND(SUM(bkgs.slots) / 2.0, 2) AS "Total Hours"
FROM
  (
    cd.bookings bkgs
    JOIN cd.facilities facs ON bkgs.facid = facs.facid
  )
GROUP BY
  bkgs.facid,
  facs.name
ORDER BY
  bkgs.facid;

-- 
-- Produce a list of each member name, id, and their first booking after September 1st 2012.
-- Order by member ID. 
--
WITH
  filtered_bkgs AS (
    SELECT
      MIN(starttime) AS starttime,
      memid
    FROM
      cd.bookings
    WHERE
      starttime >= '2012-09-01'
    GROUP BY
      memid
  )
SELECT
  mems.surname,
  mems.firstname,
  mems.memid,
  bkgs.starttime
FROM
  filtered_bkgs bkgs
  JOIN cd.members mems ON bkgs.memid = mems.memid
ORDER BY
  mems.memid;

-- Also doable with
SELECT
  mems.surname,
  mems.firstname,
  mems.memid,
  MIN(bks.starttime) AS starttime
FROM
  cd.bookings bks
  JOIN cd.members mems ON mems.memid = bks.memid
WHERE
  starttime >= '2012-09-01'
GROUP BY
  mems.surname,
  mems.firstname,
  mems.memid
ORDER BY
  mems.memid;

--
-- Produce a list of member names, with each row containing the total member count.
-- Order by join date, and include guest members. 
--
SELECT
  (
    SELECT
      COUNT(DISTINCT memid)
    FROM
      cd.members AS COUNT
  ),
  firstname,
  surname
FROM
  cd.members
ORDER BY
  joindate;

-- USE WINDOW FUNCTIONS
SELECT
  COUNT(*) OVER (),
  firstname,
  surname
FROM
  cd.members
ORDER BY
  joindate;

--
-- Produce a monotonically increasing numbered list of members (including guests),
-- ordered by their date of joining.
-- Remember that member IDs are not guaranteed to be sequential.
--
SELECT
  ROW_NUMBER() OVER (
    ORDER BY
      joindate
  ),
  firstname,
  surname
FROM
  cd.members
ORDER BY
  joindate;

--
-- Output the facility id that has the highest number of slots booked.
-- Ensure that in the event of a tie, all tieing results get output.
--
SELECT
  facid,
  total
FROM
  (
    SELECT
      facid,
      SUM(slots) total,
      RANK() OVER (
        ORDER BY
          SUM(slots) DESC
      ) RANK
    FROM
      cd.bookings
    GROUP BY
      facid
  ) AS ranked
WHERE
  RANK = 1;

--
-- Produce a list of members (including guests), along with the number of hours
-- they've booked in facilities, rounded to the nearest ten hours. Rank them by
-- this rounded figure, producing output of first name, surname, rounded hours,
-- rank. Sort by rank, surname, and first name.
--
SELECT
  firstname,
  surname,
  (SUM(slots) / 2) AS hours,
  RANK() OVER (
    ORDER BY
      (SUM(slots) / 2) DESC
  ) RANK
FROM
  (
    cd.bookings bks
    JOIN cd.members mems ON bks.memid = mems.memid
  )
GROUP BY
  mems.surname,
  mems.firstname,
  mems.memid;

SELECT
  firstname,
  surname,
  ROUND(SUM(slots) / 2, -1) AS hours,
  RANK() OVER (
    ORDER BY
      ROUND(SUM(slots) / 2, -1) DESC
  ) RANK
FROM
  (
    cd.bookings bks
    JOIN cd.members mems ON bks.memid = mems.memid
  )
GROUP BY
  mems.surname,
  mems.firstname,
  mems.memid;

SELECT
  firstname,
  surname,
  ((SUM(slots) + 10) / 20) * 10 AS hours,
  RANK() OVER (
    ORDER BY
      ((SUM(slots) + 10) / 20) * 10 DESC
  ) RANK
FROM
  (
    cd.bookings bks
    JOIN cd.members mems ON bks.memid = mems.memid
  )
GROUP BY
  mems.surname,
  mems.firstname,
  mems.memid;

--
SELECT
  firstname,
  surname,
  ((SUM(bks.slots) + 10) / 20) * 10 AS hours,
  RANK() OVER (
    ORDER BY
      ((SUM(bks.slots) + 10) / 20) * 10 DESC
  ) AS RANK
FROM
  cd.bookings bks
  INNER JOIN cd.members mems ON bks.memid = mems.memid
GROUP BY
  mems.memid
ORDER BY
  RANK,
  surname,
  firstname;

--
SELECT
  firstname,
  surname,
  hours,
  RANK() OVER (
    ORDER BY
      hours DESC
  )
FROM
  (
    SELECT
      firstname,
      surname,
      ((SUM(bks.slots) + 10) / 20) * 10 AS hours
    FROM
      cd.bookings bks
      INNER JOIN cd.members mems ON bks.memid = mems.memid
    GROUP BY
      mems.memid
  ) AS subq
ORDER BY
  RANK,
  surname,
  firstname;

--
-- Produce a list of the top three revenue generating facilities (including
-- ties). Output facility name and rank, sorted by rank and facility name. 
--
SELECT
  name,
  RANK() OVER (
    ORDER BY
      earnings DESC
  )
FROM
  (
    SELECT
      facs.name,
      SUM(
        bks.slots * CASE
          WHEN memid = 0 THEN facs.guestcost
          ELSE facs.membercost
        END
      ) AS EARNINGS
    FROM
      cd.bookings bks
      JOIN cd.facilities facs ON bks.facid = facs.facid
    GROUP BY
      facs.name
  ) AS subq
ORDER BY
  RANK
LIMIT
  3;

--
-- Classify facilities into equally sized groups of high, average, and low
-- based on their revenue. Order by classification and facility name.
--
SELECT
  name,
  (
    CASE
      WHEN tiles = 1 THEN 'high'
      WHEN tiles = 2 THEN 'average'
      WHEN tiles = 3 THEN 'low'
    END
  ) AS revenue
FROM
  (
    SELECT
      facs.name,
      NTILE(3) OVER (
        ORDER BY
          SUM(
            bks.slots * CASE
              WHEN memid = 0 THEN facs.guestcost
              ELSE facs.membercost
            END
          ) DESC
      ) AS tiles
    FROM
      cd.bookings bks
      JOIN cd.facilities facs ON bks.facid = facs.facid
    GROUP BY
      facs.name
    ORDER BY
      tiles,
      facs.name
  ) AS subq;

--
-- Based on the 3 complete months of data so far, calculate the amount of time
-- each facility will take to repay its cost of ownership. Remember to take
-- into account ongoing monthly maintenance. Output facility name and payback
-- time in months, order by facility name. Don't worry about differences in
-- month lengths, we're only looking for a rough value here! 
--
SELECT
  name,
  -- revenue / 3.0 AS monthly_revenue_approx,
  -- monthlymaintenance,
  -- initialoutlay,
  initialoutlay / ((revenue / 3.0) - monthlymaintenance) AS months_before_positive
FROM
  (
    SELECT
      facs.name,
      SUM(
        bks.slots * CASE
          WHEN memid = 0 THEN facs.guestcost
          ELSE facs.membercost
        END
      ) AS revenue,
      facs.monthlymaintenance,
      facs.initialoutlay
    FROM
      cd.bookings bks
      JOIN cd.facilities facs ON bks.facid = facs.facid
    GROUP BY
      facs.name,
      facs.monthlymaintenance,
      facs.initialoutlay
    ORDER BY
      -- revenue DESC,
      facs.name
  ) AS subq;

--
-- For each day in August 2012, calculate a rolling average of total
-- revenue over the previous 15 days. Output should contain date and
-- revenue columns, sorted by the date. Remember to account for the
-- possibility of a day having zero revenue. This one's a bit tough,
-- so don't be afraid to check out the hint!
--
WITH
  daily_revenue AS (
    SELECT
      -- facs.name,
      SUM(
        bks.slots * CASE
          WHEN memid = 0 THEN facs.guestcost
          ELSE facs.membercost
        END
      ) AS revenue,
      EXTRACT(
        DAY
        FROM
          starttime
      ) AS DAY,
      EXTRACT(
        MONTH
        FROM
          starttime
      ) AS MONTH
    FROM
      cd.bookings bks
      JOIN cd.facilities facs ON bks.facid = facs.facid
    WHERE
      EXTRACT(
        MONTH
        FROM
          bks.starttime
      ) IN (7, 8)
      AND EXTRACT(
        YEAR
        FROM
          bks.starttime
      ) = 2012
    GROUP BY
      -- facs.name,
      EXTRACT(
        MONTH
        FROM
          starttime
      ),
      EXTRACT(
        DAY
        FROM
          starttime
      )
  )
SELECT
  date,
  revenue
FROM
  (
    SELECT
      AVG(revenue) OVER (
        ORDER BY
          MONTH,
          DAY ROWS BETWEEN 14 PRECEDING
          AND CURRENT ROW
      ) AS revenue,
      TO_DATE(CONCAT(2012, '-', MONTH, '-', DAY), 'YYYY-MM-DD') AS date
    FROM
      daily_revenue
  ) AS subq
WHERE
  EXTRACT(
    MONTH
    FROM
      date
  ) = 8;
