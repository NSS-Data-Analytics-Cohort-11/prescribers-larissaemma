--1.
----a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.


SELECT npi, SUM (prescription.total_claim_count) as total_drugs
FROM prescriber 
INNER JOIN prescription
USING (npi)
GROUP BY npi
ORDER BY sum (prescription.total_claim_count) DESC
LIMIT 1;

--answer:1881634483;99707

--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT npi,
	   prescriber.nppes_provider_last_org_name,
	   prescriber.nppes_provider_first_name,	
	   prescriber.specialty_description,
	   SUM (prescription.total_claim_count) as total_drugs
FROM prescriber 
INNER JOIN prescription
USING (npi)
GROUP BY npi, 
		prescriber.nppes_provider_last_org_name,
		prescriber.nppes_provider_first_name, 
		prescriber.specialty_description
ORDER BY sum (prescription.total_claim_count) DESC
LIMIT 1;

--answer;1881634483;"PENDLEY";"BRUCE";"Family Practice";99707

--2.
---a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT prescriber.specialty_description, sum (prescription.total_claim_count)
FROM prescription
INNER JOIN prescriber
USING (npi)
GROUP BY prescriber.specialty_description
ORDER BY sum (prescription.total_claim_count) DESC
LIMIT 1;
--answer:"Family Practice";9752347

--b. Which specialty had the most total number of claims for opioids?


SELECT prescriber.specialty_description, sum (total_claim_count) as opioid_count
FROM drug
INNER JOIN prescription
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description
ORDER BY sum (total_claim_count) DESC
LIMIT 1;


--answer: "Nurse Practitioner"; 900845


c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT prescriber.specialty_description, SUM (prescription.total_claim_count)
FROM prescriber 
LEFT JOIN prescription
USING (npi)
GROUP BY prescriber.specialty_description
HAVING sum(prescription.total_claim_count) is NULL


--d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

SELECT
	specialty_description,
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) as opioid_claims,
	
	SUM(total_claim_count) AS total_claims,
	
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) * 100.0 /  SUM(total_claim_count) AS opioid_percentage
	
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
GROUP BY specialty_description
--order by specialty_description;
order by opioid_percentage desc

or

WITH claims AS 
	(SELECT
		pr.specialty_description,
		SUM(rx.total_claim_count) AS total_claims
	FROM prescriber AS pr
	INNER JOIN prescription AS rx
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
	GROUP BY pr.specialty_description),
-- second CTE for total opioid claims
opioid AS
	(SELECT
		pr.specialty_description,
		SUM(rx.total_claim_count) AS total_opioid
	FROM prescriber AS pr
	INNER JOIN prescription AS rx
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
	WHERE drug.opioid_drug_flag ='Y'
	GROUP BY pr.specialty_description)
--main query
SELECT
	claims.specialty_description,
	COALESCE(ROUND((opioid.total_opioid / claims.total_claims * 100),2),0) AS perc_opioid
FROM claims
LEFT JOIN opioid
USING(specialty_description)
ORDER BY perc_opioid DESC;



--3.
--a. Which drug (generic_name) had the highest total drug cost?

SELECT drug.generic_name, sum (prescription.total_drug_cost)
FROM prescription
INNER JOIN drug
USING (drug_name)
GROUP BY drug.generic_name
ORDER BY sum (prescription.total_drug_cost) DESC
LIMIT 1;


--answer:INSULIN GLARGINE,HUM.REC.ANLOG" 104264066.35 


--b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.


SELECT drug.generic_name, ROUND (sum(prescription.total_drug_cost) /sum (prescription.total_day_supply),2)
FROM prescription
INNER JOIN drug
USING (drug_name)
GROUP BY drug.generic_name
ORDER BY sum(prescription.total_drug_cost)/ sum (prescription.total_day_supply) DESC

--answer:"C1 ESTERASE INHIBITOR";3495.22


--4.
--a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/


SELECT drug_name,
	CASE 
		WHEN opioid_drug_flag ='Y' then 'opioid'
		WHEN antibiotic_drug_flag = 'Y' then 'antibiotic'
		ELSE 'neither'
		END as drug_type
FROM drug


--b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.


SELECT sum (prescription.total_drug_cost) as money,
	CASE 
		WHEN opioid_drug_flag ='Y' then 'opioid'
		WHEN antibiotic_drug_flag = 'Y' then 'antibiotic'
		ELSE 'neither'
		END as drug_type,
		SUM(MONEY(prescription.total_drug_cost))
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY drug_type
ORDER BY money DESC


--answer: opioid


--5.
---a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.



SELECT count (*)
FROM cbsa
INNER JOIN fips_county 
USING (fipscounty)
WHERE state ='TN'

--answer: 42


--b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.




SELECT cbsa.cbsaname, sum (population.population) as total_pop
FROM cbsa
INNER JOIN population
USING (fipscounty)
GROUP BY cbsa.cbsaname
ORDER BY total_pop DESC

--answer: "Nashville-Davidson--Murfreesboro--Franklin, TN";1830410 ;"Morristown, TN";116352



--c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT fips_county.county, population.population
FROM population
INNER JOIN fips_county
USING (fipscounty)
WHERE fipscounty NOT IN ( 
  SELECT fipscounty
  FROM cbsa
)
ORDER BY population.population DESC


--answer: "SEVIER"; 95523



--6.
---a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.



SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000



--b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.



SELECT drug_name, prescription.total_claim_count, drug.opioid_drug_flag
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count >= 3000





--c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.




SELECT drug_name, total_claim_count, CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name) AS prescriber_name,
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'not opioid' END AS drug_type
FROM prescription
INNER JOIN drug
USING (drug_name)
INNER JOIN prescriber
ON prescription.npi = prescriber.npi
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;


SELECT drug_name, prescriber.nppes_provider_last_org_name, nppes_provider_first_name,drug_name, prescription.total_claim_count, drug.opioid_drug_flag
FROM prescription
INNER JOIN drug
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE total_claim_count >= 3000







--7.The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

--a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT 
	   drug.drug_name, 
	   drug.opioid_drug_flag,
	   prescriber.specialty_description, 
		prescriber.nppes_provider_city
FROM drug
CROSS JOIN prescriber
WHERE prescriber.nppes_provider_city = 'NASHVILLE' 
     AND drug.opioid_drug_flag = 'Y'
	 AND prescriber.specialty_description = 'Pain Management'
																						   
																		   
																						   
b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

	 
SELECT prescriber.npi,
	   drug.drug_name,
	    drug.opioid_drug_flag,
	    prescriber.specialty_description, 
		prescriber.nppes_provider_city,
		SUM (prescription.total_claim_count)
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING (npi, drug_name)
WHERE prescriber.nppes_provider_city = 'NASHVILLE' 
     AND drug.opioid_drug_flag = 'Y'
	 AND prescriber.specialty_description = 'Pain Management'	
GROUP BY drug.drug_name,
		 drug.opioid_drug_flag,
		 prescriber.npi,
		 prescriber.specialty_description, 
		 prescriber.nppes_provider_city  	 
ORDER BY SUM (prescription.total_claim_count) asc 

--other way

SELECT
	prescriber.npi,
	drug.drug_name,
	(SELECT
	 	SUM(prescription.total_claim_count)
	 FROM prescription
	 WHERE prescriber.npi = prescription.npi
	 AND prescription.drug_name = drug.drug_name) as total_claims
FROM prescriber
CROSS JOIN drug  -- use a cross and an inner
INNER JOIN prescription
using (npi)
WHERE 
	prescriber.specialty_description = 'Pain Management' AND
	prescriber.nppes_provider_city = 'NASHVILLE' AND
	drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug.drug_name
ORDER BY prescriber.npi DESC;

	 

	 
c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT prescriber.npi,
	   drug.drug_name,
	    drug.opioid_drug_flag,
	    prescriber.specialty_description, 
		prescriber.nppes_provider_city,
		SUM (prescription.total_claim_count)
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING (npi, drug_name)
WHERE prescriber.nppes_provider_city = 'NASHVILLE' 
     AND drug.opioid_drug_flag = 'Y'
	 AND prescriber.specialty_description = 'Pain Management'	
GROUP BY drug.drug_name,
		 drug.opioid_drug_flag,
		 prescriber.npi,
		 prescriber.specialty_description, 
		 prescriber.nppes_provider_city  	 
ORDER BY SUM (prescription.total_claim_count) asc  


--answer
SELECT prescriber.npi, drug.drug_name,
 COALESCE(prescription.total_claim_count,0)
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE prescriber.specialty_description = 'Pain Management' AND
	prescriber.nppes_provider_city = 'NASHVILLE' AND
	drug.opioid_drug_flag = 'Y';
