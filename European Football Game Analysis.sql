European Football Game Analysis

--Initial Exploration and Data Profiling
-- Preview the Country Table
SELECT * FROM Country LIMIT 5;

-- Preview the League Table
SELECT * FROM League LIMIT 5;

-- Preview the Match Table
SELECT * FROM Match LIMIT 5;

-- Preview the Player Table
SELECT * FROM Player LIMIT 5;

-- Preview the Player_Attributes Table
SELECT * FROM Player_Attributes LIMIT 5;

-- Preview the Team Table
SELECT * FROM Team LIMIT 5;

-- Preview the Team_Attributes Table
SELECT * FROM Team_Attributes LIMIT 5;

-- 1. Basic Player Data Overview
-- This query retrieves basic player information, including name, height, and weight,
-- to give a general overview of player statistics.
SELECT player_name, height, weight
FROM Player
LIMIT 10;

-- 2. Average Player Attributes by Season
-- This query calculates the average player ratings and potentials across all players for each season.
-- It provides a view of general player skill trends over the years.
SELECT strftime('%Y', date) AS season,
       AVG(overall_rating) AS avg_rating,
       AVG(potential) AS avg_potential
FROM Player_Attributes
GROUP BY season
ORDER BY season ASC;

-- 3. Key Skill Trends by Season
-- This query calculates average values for key skills (dribbling, finishing, and defensive awareness) by season.
-- It helps track trends in player performance in these specific areas over time.
SELECT strftime('%Y', date) AS season,
       AVG(dribbling) AS avg_dribbling,
       AVG(finishing) AS avg_finishing,
       AVG(defensive_awareness) AS avg_defense
FROM Player_Attributes
GROUP BY season
ORDER BY season ASC;

-- 4. Top Players Per Season Based on Rating
-- This query identifies the top players each season based on their overall rating.
-- It joins the Player and Player_Attributes tables to get player names and their highest ratings for each season.
SELECT p.player_name, pa.overall_rating, strftime('%Y', pa.date) AS season
FROM Player_Attributes AS pa
JOIN Player AS p ON pa.player_api_id = p.player_api_id
WHERE pa.overall_rating IS NOT NULL
ORDER BY season ASC, overall_rating DESC
LIMIT 10;

-- 5. Attribute Trends for a Specific Player
-- This query tracks the performance of a specific player across seasons,
-- showing their overall rating, potential, dribbling, finishing, and sprint speed.
-- Replace [INSERT_PLAYER_API_ID] with the actual player_api_id for the player you want to analyze.
SELECT strftime('%Y', date) AS season,
       overall_rating, potential, dribbling, finishing, sprint_speed
FROM Player_Attributes
WHERE player_api_id = [INSERT_PLAYER_API_ID]
ORDER BY season ASC;

WITH Goals AS (
    SELECT 
        t.team_long_name AS Team,
        SUM(m.home_team_goal + m.away_team_goal) AS Total_Goals
    FROM 
        Match AS m
    JOIN 
        Team AS t ON m.home_team_api_id = t.team_api_id OR m.away_team_api_id = t.team_api_id
    GROUP BY 
        t.team_long_name
),
Wins AS (
    SELECT 
        t.team_long_name AS Team,
        SUM(CASE 
            WHEN m.home_team_api_id = t.team_api_id AND m.home_team_goal > m.away_team_goal THEN 1
            WHEN m.away_team_api_id = t.team_api_id AND m.away_team_goal > m.home_team_goal THEN 1
            ELSE 0 
        END) AS Total_Wins
    FROM 
        Match AS m
    JOIN 
        Team AS t ON m.home_team_api_id = t.team_api_id OR m.away_team_api_id = t.team_api_id
    GROUP BY 
        t.team_long_name
),
Defense AS (
    SELECT 
        t.team_long_name AS Team,
        SUM(CASE 
            WHEN m.home_team_api_id = t.team_api_id THEN m.away_team_goal
            WHEN m.away_team_api_id = t.team_api_id THEN m.home_team_goal
            ELSE 0 
        END) AS Total_Goals_Conceded
    FROM 
        Match AS m
    JOIN 
        Team AS t ON m.home_team_api_id = t.team_api_id OR m.away_team_api_id = t.team_api_id
    GROUP BY 
        t.team_long_name
)
SELECT 
    Goals.Team,
    Goals.Total_Goals,
    Wins.Total_Wins,
    Defense.Total_Goals_Conceded
FROM 
    Goals
JOIN 
    Wins ON Goals.Team = Wins.Team
JOIN 
    Defense ON Goals.Team = Defense.Team
ORDER BY 
    Total_Wins DESC, Total_Goals DESC;


-- 1. Basic League and Country Overview
-- This query retrieves league names along with their associated country names,
-- helping us to establish the relationship between leagues and countries.
SELECT l.name AS league_name, c.name AS country_name
FROM League AS l
JOIN Country AS c ON l.country_id = c.id
ORDER BY country_name;

-- 2. Key Stats by League
-- This query calculates the total number of matches, average goals scored, and average betting odds
-- for each league. It helps to understand the overall competitiveness and scoring trends in each league.
SELECT l.name AS league_name,
       COUNT(m.id) AS total_matches,
       AVG(m.home_team_goal + m.away_team_goal) AS avg_goals,
       AVG(m.B365H) AS avg_home_odds,
       AVG(m.B365D) AS avg_draw_odds,
       AVG(m.B365A) AS avg_away_odds
FROM Match AS m
JOIN League AS l ON m.league_id = l.id
GROUP BY league_name
ORDER BY total_matches DESC;

-- 3. Key Stats by Country
-- This query calculates the total number of matches and average goals scored in each country.
-- It provides insights into scoring trends at a country level, allowing for cross-country comparisons.
SELECT c.name AS country_name,
       COUNT(m.id) AS total_matches,
       AVG(m.home_team_goal + m.away_team_goal) AS avg_goals
FROM Match AS m
JOIN League AS l ON m.league_id = l.id
JOIN Country AS c ON l.country_id = c.id
GROUP BY country_name
ORDER BY total_matches DESC;

-- 4. Comparing Home and Away Wins by Country
-- This query determines the percentage of matches won by the home team versus the away team in each country.
-- It can highlight if certain countries have a higher home advantage.
SELECT c.name AS country_name,
       ROUND(100.0 * SUM(CASE WHEN m.home_team_goal > m.away_team_goal THEN 1 ELSE 0 END) / COUNT(m.id), 2) AS home_win_percentage,
       ROUND(100.0 * SUM(CASE WHEN m.home_team_goal < m.away_team_goal THEN 1 ELSE 0 END) / COUNT(m.id), 2) AS away_win_percentage
FROM Match AS m
JOIN League AS l ON m.league_id = l.id
JOIN Country AS c ON l.country_id = c.id
GROUP BY country_name
ORDER BY home_win_percentage DESC;

-- 5. Average Player Attributes by Country
-- This query calculates average player attributes like overall rating and potential for players in each country.
-- It gives a sense of the general player skill level in different countries.
SELECT c.name AS country_name,
       AVG(pa.overall_rating) AS avg_player_rating,
       AVG(pa.potential) AS avg_player_potential
FROM Player_Attributes AS pa
JOIN Player AS p ON pa.player_api_id = p.player_api_id
JOIN Match AS m ON p.player_api_id = m.id
JOIN League AS l ON m.league_id = l.id
JOIN Country AS c ON l.country_id = c.id
GROUP BY country_name
ORDER BY avg_player_rating DESC;

-- Betting Odds Analysis and Prediction Accuracy

-- Step 1: Analyze betting odds, predict outcomes, and check accuracy
WITH betting_analysis AS (
    SELECT
        match_id,                          -- Unique match identifier
        home_team_id,                      -- Home team identifier
        away_team_id,                      -- Away team identifier
        home_team_goal,                    -- Goals scored by the home team
        away_team_goal,                    -- Goals scored by the away team
        home_odds,                         -- Betting odds for home team win
        draw_odds,                         -- Betting odds for a draw
        away_odds,                         -- Betting odds for away team win

        -- Predicted outcome based on the lowest odds
        CASE
            WHEN home_odds < away_odds AND home_odds < draw_odds THEN 'Home'
            WHEN away_odds < home_odds AND away_odds < draw_odds THEN 'Away'
            ELSE 'Draw'
        END AS predicted_outcome,

        -- Actual outcome based on goals scored
        CASE
            WHEN home_team_goal > away_team_goal THEN 'Home'
            WHEN away_team_goal > home_team_goal THEN 'Away'
            ELSE 'Draw'
        END AS actual_outcome,

        -- Check if the prediction matches the actual result
        CASE
            WHEN (home_odds < away_odds AND home_odds < draw_odds AND home_team_goal > away_team_goal) THEN 1
            WHEN (away_odds < home_odds AND away_odds < draw_odds AND away_team_goal > home_team_goal) THEN 1
            WHEN (draw_odds < home_odds AND draw_odds < away_odds AND home_team_goal = away_team_goal) THEN 1
            ELSE 0
        END AS correct_prediction

    FROM
        Match  -- Replace with your table name if different
)

-- Step 2: Select detailed analysis with betting predictions and outcomes
SELECT
    match_id,
    home_team_id,
    away_team_id,
    home_team_goal,
    away_team_goal,
    home_odds,
    draw_odds,
    away_odds,
    predicted_outcome,
    actual_outcome,
    correct_prediction
FROM
    betting_analysis
ORDER BY
    match_id;

-- Step 3: Calculate the overall accuracy of the predictions
SELECT
    (SUM(correct_prediction) * 100.0 / COUNT(*)) AS prediction_accuracy
FROM
    betting_analysis;
