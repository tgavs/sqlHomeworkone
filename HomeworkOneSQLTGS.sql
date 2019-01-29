USE sakila;

-- 1a. Display the first and last names of all actors from the table actor--

SELECT first_name,last_name FROM actor;

-- 1b. Display the first and last name of each actor in a single column in upper case letters. Name the column Actor Name --

SELECT CONCAT(first_name,',',last_name) as ActorName FROM actor;


-- 2a. You need to find the ID number, first name, and last name of an actor, of whom you know only the first name, "Joe."  --
-- What is one query would you use to obtain this information? --

SELECT actor_id,first_name,last_name FROM actor WHERE first_name="Joe";
 
-- 2b. Find all actors whose last name contain the letters GEN --

SELECT * FROM actor WHERE last_name LIKE "%gen%";

-- 2c. Find all actors whose last names contain the letters LI. This time, order the rows by last name and first name, in that order:

SELECT * FROM actor WHERE last_name LIKE "%li%" ORDER BY last_name,first_name ASC;


-- 2d. Using IN, display the country_id and country columns of the following countries: Afghanistan, Bangladesh, and China:

SELECT country_id, country FROM country WHERE country IN ("Afghanistan","Bangladesh", "China");

-- 3a. You want to keep a description of each actor. 
-- You don't think you will be performing queries on a description, so create a column in the table actor named description and
--  use the data type BLOB (Make sure to research the type BLOB, as the difference between it and VARCHAR are significant).

ALTER TABLE actor
ADD COLUMN description BLOB
AFTER last_update; 


-- 3b. Very quickly you realize that entering descriptions for each actor is too much effort. Delete the description column.

ALTER TABLE actor
DROP COLUMN description;


-- 4a. List the last names of actors, as well as how many actors have that last name.

SELECT last_name,COUNT(DISTINCT last_name) FROM actor GROUP BY last_name;


-- 4b. List last names of actors and the number of actors who have that last name, but only for names that are shared by at least two actors

SELECT last_name, count(*)
FROM actor
GROUP BY last_name;

-- 4c. The actor HARPO WILLIAMS was accidentally entered in the actor table as GROUCHO WILLIAMS. Write a query to fix the record.

SET @fixActorId:= (SELECT actor_id FROM actor WHERE first_name="GROUCHO" AND last_name="WILLIAMS");


UPDATE actor SET first_name="HARPO" WHERE actor_id=@fixActorId;

-- 4d. Perhaps we were too hasty in changing GROUCHO to HARPO. 
-- It turns out that GROUCHO was the correct name after all! In a single query, if the first name of the actor is currently HARPO, 
-- change it to GROUCHO.

UPDATE actor SET first_name="GROUCHO" WHERE actor_id=@fixActorId;

-- 5a. You cannot locate the schema of the address table. Which query would you use to re-create it?


DESCRIBE address;

-- 6a. Use JOIN to display the first and last names, as well as the address, of each staff member. 
-- Use the tables staff and address:

SELECT * FROM staff;

SELECT first_name,last_name, address FROM staff LEFT JOIN address USING (address_id);


-- 6b. Use JOIN to display the total amount rung up by each staff member in August of 2005.
-- Use tables staff and payment.

SELECT * FROM payment;


SELECT first_name,last_name,SUM(amount) as "Total_Amount" FROM staff LEFT JOIN payment USING(staff_id) GROUP BY staff_id;

-- 6c. List each film and the number of actors who are listed for that film. Use tables film_actor and film. Use inner join.

SELECT title, COUNT(actor_id) as "Number_of_Actors" FROM film INNER JOIN film_actor USING (film_id) GROUP BY film_id; 


-- 6d. How many copies of the film Hunchback Impossible exist in the inventory system?

SELECT title, COUNT(inventory_id) FROM film LEFT JOIN inventory USING (film_id) WHERE title="Hunchback Impossible";

-- 6e. Using the tables payment and customer and the JOIN command, list the total paid by each customer. 
-- List the customers alphabetically by last name:

SELECT first_name,last_name, SUM(amount) as "Total Amount Paid"
FROM payment 
LEFT JOIN customer 
USING (customer_id) 
GROUP BY customer_id 
ORDER BY last_name ASC;


-- 7a. The music of Queen and Kris Kristofferson have seen an unlikely resurgence. 
-- As an unintended consequence, films starting with the letters K and Q have also soared in popularity. 
-- Use subqueries to display the titles of movies starting with the letters K and Q whose language is English.

SELECT c.title, c.language_id FROM
	(SELECT title,language_id
	FROM film
	WHERE language_id IN
		(SELECT language_id 
		FROM language 
		WHERE name="English"
         )
	 ) c
WHERE c.title
LIKE "K%" OR c.title LIKE "Q%";



-- 7b. Use subqueries to display all actors who appear in the film Alone Trip.

SELECT actor_id,first_name,last_name
FROM actor
WHERE actor_id 
IN (SELECT actor_id
	FROM film_actor
    WHERE film_id =(SELECT film_id 
					FROM film
					WHERE title="Alone Trip"
                    )
    );
    
-- 7c. You want to run an email marketing campaign in Canada, for which you will need the names and email addresses 
-- of all Canadian customers. Use joins to retrieve this information.

SELECT first_name,last_name, email, country
FROM customer LEFT JOIN
	(SELECT address_id,city_id,country_id, country 
     FROM (SELECT address_id, city_id,country_id 
		   FROM address 
           LEFT JOIN city 
           USING (city_id)
           ) as a
	 LEFT JOIN country
	 USING (country_id)
     ) as b
USING (address_id)
WHERE country LIKE '%Canada%';


-- 7d. Sales have been lagging among young families, and you wish to target all family movies for a promotion.
-- Identify all movies categorized as family films

SELECT film_id,title,category_id,rating,name
FROM film 
LEFT JOIN (SELECT film_id,category_id,name
		   FROM film_category LEFT JOIN category
           USING (category_id)
		   )as a
USING (film_id)
WHERE name="family";

-- 7e. Display the most frequently rented movies in descending order.

SELECT film_id,rentsbyFilm,title
FROM film
LEFT JOIN (SELECT COUNT(film_id) as rentsbyFilm,film_id,inventory_id,rental_id
		   FROM rental LEFT JOIN inventory
	       USING (inventory_id)
	       GROUP BY film_id
           ) as a
USING (film_id)
ORDER BY rentsbyFilm DESC;


-- 7f. Write a query to display how much business, in dollars, each store brought in.

SELECT store_id, SUM(amount) AS "totalSales" 
FROM payment 
LEFT JOIN customer
USING (customer_id)
GROUP BY store_id;

-- 7g. Write a query to display for each store its store ID, city, and country.

SELECT country,store_id, city 
FROM(SELECT country_id, store_id,city
	FROM (SELECT store_id, address_id,city_id 
			   FROM store
			   LEFT JOIN address
			   USING(address_id)
			   ) as a
	LEFT JOIN city
	USING (city_id)
    GROUP BY store_id
	) as b
LEFT JOIN country
USING (country_id);


-- 7h. List the top five genres in gross revenue in descending order. 
-- (Hint: you may need to use the following tables: category, film_category, inventory, payment, and rental.)

SELECT sum(amount) as "grossRevenue",category_id, name as "categoryName"
FROM (SELECT title, film_id, inventory_id, rental_id,amount,category_id
	  FROM (SELECT title, film_id, inventory_id, rental_id,amount
		    FROM(SELECT title, film_id, inventory_id, rental_id
			     FROM rental
			     LEFT JOIN (SELECT title, film_id,inventory_id
						    FROM inventory 
						    LEFT JOIN film
						    USING (film_id)
						    ) as a
			     USING (inventory_id)
			    ) as b
		    LEFT JOIN payment
		    USING (rental_id)
            ) AS d
	 LEFT JOIN film_category
	 USING (film_id)
     )AS e
LEFT JOIN category
USING (category_id)
GROUP BY categoryName
ORDER BY grossRevenue DESC
LIMIT 5;



-- 8a. In your new role as an executive, you would like to have an easy way of viewing the Top five genres by gross revenue.
-- Use the solution from the problem above to create a view. If you haven't solved 7h, you can substitute another query to create a view.

CREATE VIEW top_5_genres AS
SELECT grossRevenue,category_id,categoryName
FROM(SELECT sum(amount) AS "grossRevenue",category_id, name AS "categoryName"
	 FROM (SELECT title, film_id, inventory_id, rental_id,amount,category_id
	       FROM (SELECT title, film_id, inventory_id, rental_id,amount
		         FROM(SELECT title, film_id, inventory_id,rental_id
					  FROM rental
					  LEFT JOIN (SELECT title, film_id,inventory_id
								 FROM inventory 
								 LEFT JOIN film
								 USING (film_id)
								 ) AS a
					  USING (inventory_id)
					  ) AS b
				 LEFT JOIN payment
				 USING (rental_id)
				 ) AS d
		  LEFT JOIN film_category
		  USING (film_id)
		  )AS e
	LEFT JOIN category
	USING (category_id)
	GROUP BY categoryName
	ORDER BY grossRevenue DESC
	LIMIT 5
    ) AS f;

-- 8b. How would you display the view that you created in 8a?

SELECT * FROM top_5_genres;


-- 8c. You find that you no longer need the view top_five_genres. Write a query to delete it.


DROP VIEW top_5_genres;
