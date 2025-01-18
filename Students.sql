
--The number of attempts a student makes in each subject, as well as the average result of the attempts.
SELECT name_subject, COUNT(result) AS 'Count', ROUND(AVG(result),2) AS 'average'
FROM subject LEFT JOIN attempt USING(subject_id)
GROUP BY name_subject
ORDER BY 3 DESC;

--The difference in days between the first and last attempt (if the student made several attempts in the same subject).
SELECT name_student, name_subject, DATEDIFF(MAX(date_attempt),MIN(date_attempt)) AS 'interval' 
FROM subject INNER JOIN attempt USING(subject_id)
             INNER JOIN student USING(student_id)
GROUP BY name_student, name_subject
HAVING DATEDIFF(MAX(date_attempt),MIN(date_attempt))>0
ORDER BY interval ASC;

--Three questions on the subject “Fundamentals of Databases” were randomly selected.
SELECT question_id, name_question
FROM question INNER JOIN subject USING(sudject_id)
WHERE name_subject in('Fundamentals of Databases')
ORDER BY RAND()
LIMIT 3;

--Questions that were included in the test for Semenov Ivan on the subject "Basics of SQL" 2020-05-17.
SELECT q.name_question, a.name_answer, IF(a.is_correct, 'correct', 'wrong') AS 'result'
FROM testing t INNER JOIN question q USING(question_id)
               INNER JOIN answer a USING(answer_id)
               INNER JOIN attempt att USING(attempt_id)
WHERE att.subject_id=(SELECT subject_id FROM subject WHERE name_subject='Basics of SQL')
      AND date_attempt='2020-05-17'
      AND student_id=(SELECT student_id FROM student WHERE name_student='Semenov Ivan');

--Test results.
SELECT name_student, name_subject, date_attempt, (SELECT ROUND(((SUM(is_correct)/3)*100),2) AS r
                                                  FROM answer
                                                  WHERE is_correct>0
                                                  GROUP BY question_id)
                                                  AS 'result'
FROM attempt 
INNER JOIN subject USING(subject_id)
INNER JOIN student USING(student_id);

--The percentage of successful solutions, the name of the subject to which the question relates and the total number of answers to this question.
--(Since the question texts can be long, they are truncated to 30 characters).
SELECT name_subject, CONCAT(LEFT(name_question, 30)'...') AS 'Question', COUNT(t.answer_id) AS 'Count_answer',
       ROUND(SUM(is_correct)/COUNT(t.answer_id)*100,2) AS 'success'
FROM testin t INNER JOIN answer a USING(answer_id)
               INNER JOIN question q ON q.question_id=t.question_id
               INNER JOIN subject s ON s.subject_id=q.subject_id
GROUP BY 1, 2
ORDER BY 1, 2 DESC;

--"The easiest" and "the hardest" question
SELECT name_subject, CONCAT(LEFT(name_question, 30)'...') AS 'Question',
IF(ROUND(SUM(is_correct)/COUNT(t.answer_id)*100,2)=(SELECT b1.complexity 
                                                    FROM (SELECT name_subject, name_question,
                                                          ROUND(SUM(is_correct)/COUNT(t.answer_id)*100,2) AS complexity
                                                           FROM testin t INNER JOIN answer a USING(answer_id)
                                                                         INNER JOIN question q ON q.question_id=t.question_id
                                                                         INNER JOIN subject s ON s.subject_id=q.subject_id
                                                           GROUP BY 1, 2
                                                           ORDER BY 3 ASC
                                                           LIMIT 1) b1), 'the hardest',
                                                     IF(ROUND(SUM(is_correct)/COUNT(t.answer_id)*100,2)=(SELECT b2.complexity
                                                                               (SELECT name_subject, name_question,
                                                                               ROUND(SUM(is_correct)/COUNT(t.answer_id)*100,2) AS complexity
                                                                               FROM testin t INNER JOIN answer a USING(answer_id)
                                                                                 INNER JOIN question q ON q.question_id=t.question_id
                                                                                 INNER JOIN subject s ON s.subject_id=q.subject_id
                                                                               GROUP BY 1, 2
                                                                               ORDER BY 3 DESC
                                                                               LIMIT 1) b2), 'the easiest', Null)) AS Complexity
FROM testin t INNER JOIN answer a USING(answer_id)
INNER JOIN question q ON q.question_id=t.question_id
INNER JOIN subject s ON s.subject_id=q.subject_id
GROUP BY 1, 2
HAVING Complexity IN ('the hardest','the easiest');

--Educational programs for which the minimum score for each subject is greater than or equal to 40 points. Programs are sorted alphabetically.
SELECT DISTINCT(name_program) FROM program_subject
INNER JOIN program USING (program_id)
WHERE program_id NOT IN(SELECT program_id FROM program_subject WHERE min_result < 40)
ORDER BY name_program;

--The number of additional points that each applicant will receive.
SELECT name_enrollee, SUM(IF(bonus is Null, 0, bonus)) AS Bonus
FROM enrollee e
LEFT JOIN enrollee_achievement ea ON e.enrollee_id=ea.enrollee_id
LEFT JOIN achievement a ON a.achievement_id=ea.achievement_id

--The number of people who applied for each educational program and the competition for it.
SELECT name_department, name_program, plan, COUNT(pe.enrollee_id) AS amount_e
       ROUND(COUNT(pe.enrollee_id)/plan, 2) AS contest
FROM department d 
JOIN program p ON d.department_id=p.department_id
JOIN program_enrollee pe ON pe.program_id=p.program_id
GROUP BY 1, 2, 3
ORDER BY 5 DESC;

--Inclusion of a new integer column str_id in the applicant_order table (located before the first one).
ALTER TABLE aplicant_order ADD str_id INT FIRST;
SELECT * FROM aplicant_order

--All steps that consider nested queries.
SELECT
IF(LENGTH(CONCAT(module_id,' ',module_name))>19,
  CONCAT(LEFT(CONCAT(module_id,' ',module_name),16),'...'),' ') AS modul,
IF(LENGTH(CONCAT(module_id,'.',lesson_position,' ',lesson_name))>19,
  CONCAT(LEFT(CONCAT(module_id,'.',lesson_position,' ',lesson_name),16),'...'),' ') AS lesson,
CONCAT(module_id,'.',lesson_position,'.',step_position,' ',step_name) AS step
FROM module m
  JOIN lesson l USING(module_id)
  JOIN step s USING(lesson_id)
WHERE step_name LIKE '%nested_queries%'
ORDER BY 1, 2, 3;

--The step_keyword table is filled in the following way: if the keyword is in the step name, then include in step_keyword a row with the step id and the keyword id.
1)INSERT INTO step_keyword
SELECT step_id, keyword.keyword_id
FROM keyword CROSS JOIN step
WHERE INSTR(CONCAT('\\b',step_name,'\\b'),CONCAT('\\b',keyword_name,'\\b'))>0
                        OR                   
2)WHERE REGEXP_INSTR(step_name,CONCAT('\\b',keyword_name,'\\b'))>0
                        OR
3) WHERE  
INSTR(CONCAT(" ", step_name, " "), CONCAT(" ", keyword_name, " ")) > 0 or
INSTR(CONCAT(" ", step_name, " "), CONCAT(" ", keyword_name, ",")) > 0 or
INSTR(CONCAT(" ", step_name, " "), CONCAT(" ", keyword_name, "(")) > 0

--Implemented search by keywords. Steps associated with keywords MAX and AVG at the same time are displayed.
SELECT CONCAT(module_id,'.',lesson_position,
  IF(LENGTH(step_position)<10, CONCAT('0',step_position),step_position),' ',step_name) AS step
FROM module m
  JOIN lesson l USING(module_id)
  JOIN step s USING(lesson_id)
  JOIN step_keyword sk USING(step_id)
  JOIN keyword k USING(keyword_id)
WHERE REGEXP_LIKE(keyword_name,'\S*\s*MAX\S*\s*')
OR REGEXP_LIKE(keyword_name,'\S*\s*AVG\S*\s*')
GROUP BY 1
HAVING COUNT(keyword_name)=2
ORDER BY 1;

--The number of students belonging to each group is calculated.
SELECT
CASE 
     WHEN rate<=10 THEN 'I'
     WHEN rate<=15 THEN 'II'
     WHEN rate<=27 THEN 'III'
     ELSE 'IV' END AS 'Group',
CASE 
     WHEN rate<=10 THEN 'from 0 to 10'
     WHEN rate<=15 THEN 'from 11 to 15'
     WHEN rate<=27 THEN 'from 16 to 27'
     ELSE 'from 27' END AS 'Interval',
COUNT(student_name) AS 'quantity' 
FROM (SELECT student_name, COUNT(*) AS rate
      FROM (SELECT student_name, step_id
            FROM student
            JOIN step_student USING(student_id)
            WHERE result='correct'
            GROUP BY 1,2) b1
  GROUP BY 1) b2
GROUP BY 1, 2
ORDER BY 1;

--For each step, the percentage of correct solutions is displayed.
1)WITH get_count_cor (step_name, count_cor)
     AS (SELECT step_name, COUNT(*)
         FROM step
         INNER JOIN step_student USING(step_id)
         WHERE rexult='correct'
         GROUP BY step_name),
     get_count_wr (step_name, count_wr)
     AS (SELECT step_name, COUNT(*)
         FROM step
         INNER JOIN step_student USING(step_id)
         WHERE result='wrong'
         GROUP BY step_name)
SELECT step_name, 
IF(ROUND(step_cor/(step_cor+step_wrong)*100) is Null, 100, ROUND(step_cor/(step_cor+step_wrong)*100)) AS success
FROM get_count_cor FULL JOIN  get_count_wr USING(step_name)
ORDER BY 2, 1;
                       OR
2)SELECT step_name, ROUND(AVG(IF(result='correct', 1, 0))*100) AS success
FROM step INNER JOIN step_student USING(step_id) 
GROUP BY step_name
ORDER BY 1, 2;

-- Calculating students' progress
WITH stud_step_cor (student_name, step_cor)
     AS (SELECT student_name, COUNT(DISTINCT(step_id)
         FROM student INNER JOIN step_student USING(student_id)
         WHERE result='correct'
         GROUP BY 1)
  SELECT student_name, result AS progress, CASE 
                                            WHEN result=100 THEN 'the best'
                                            WHEN result=80 THEN 'better'
                                            ELSE "" END as result
  FROM (SELECT student_name,
        ROUND(step_cor/(SELECT COUNT(DISTINCT(step_id)) FROM step_student)*100) AS result
        FROM stud_step_cor GROUP BY 1) b1
  ORDER BY 2 DESC, 1;

--For a student named student_61, all of his attempts are displayed.
SELECT student_name, CONCAT(LEFT(step_name,20),'...') AS step, result, 
       FROM_UNIXTIME(submission_time) AS submission_time,
       SEC_TO_TIME(IFNULL(submission_time- LAG(submission_time) OVER(ORDER BY submission_time),0)) AS difference
FROM step_student
JOIN student USING(student_id)
JOIN step    USING(step_id)
WHERE student_name='student_61'
ORDER BY 4 ASC;

-- Average time for students to complete a lesson according to the following algorithm:
-- step completion time = sum of time spent on each attempt, ignoring attempts that lasted more than 4 hours.
-- calculate the total time spent on each lesson for each student;
-- average lesson completion time in hours, round the result to 2 decimal places;
SELECT ROW_NUMBER() OVER(ORDER BY AVG(t)) AS number,
       CONCAT(module_id,'.',lesson_position,' ',lesson_name) AS lesson,
       ROUND(AVG(t/3600), 2) AS average time
FROM (SELECT lesson_id, student_id, SUM(submission_time-attempt_time) AS t
      FROM lesson
      JOIN step USING(lesson_id)
      JOIN step_student USING(step_id)
      WHERE SUM(submission_time-attempt_time)<4*3600
      GROUP BY 1, 2) AS b1
JOIN lesson USING (lesson_id)
GROUP BY 2;

-- Each student's ranking relative to the student who has completed the most steps in the module.
1) WITH rate_all (module_id, student_name, cor_step)
     AS (SELECT module_id, student_name, COUNT(DISTINCT(step_id))
         FROM student JOIN step_student USING(sudent_id)
                      JOIN step USING(step_id)
                      JOIN lesson USING(lesson_id)
         WHERE result='correct'
         GROUP BY 1, 2),
    rate_max (module_id, student_name, max_cor_step)
    AS (SELECT module_id, MAX(b1)) 
      FROM (SELECT module_id, student_name, COUNT(DISTINCT(step_id) as b1
            FROM student JOIN step_student USING(sudent_id)
                         JOIN step USING(step_id)
                         JOIN lesson USING(lesson_id)
            WHERE result='correct'
            GROUP BY 1, 2) s1
        GROUP BY module_id)
SELECT module_id, student_name, cor_step, ROUND((100*cor_step)/max_core_step,1) AS relative_rating
FROM rate_all LEFT JOIN rate_max USING(module_id)
ORDER BY 1 ASC, 4 DESC, 2;
                                     OR --using the window function!
2)SELECT module_id, student_name, COUNT(DISTINCT step_id) as step,
         ROUND((100*COUNT(DISTINCT step_id))/ (MAX(COUNT(DISTINCT step_id)) OVER(PARTITION BY module_id)),1) AS relative_rating
  FROM student INNER JOIN step_student USING(student_id)
               INNER JOIN step USING (step_id)
               INNER JOIN lesson USING (lesson_id)
   WHERE result = "correct"
   GROUP BY 1, 2
   ORDER BY 1, 4 DESC, 2;

--The order and interval at which the user submitted the last correctly completed task of each lesson.
WITH time_max(student_name, lesson, max_subm)
    AS (SELECT student_name, CONCAT(module_id,'.',lesson_position), MAX(submission_time)
        FROM student JOIN step_student USING(student_id)
                     JOIN step USING(step_id)
                     JOIN lesson USING(lesson_id)
        WHERE result = 'correct'
        GROUP BY 1,lesson_id),
requirements AS (SELECT student_name
                 FROM time_max
                 GROUP BY student_name
                 HAVING COUNT(*) >= 3)
SELECT student_name, lesson, FROM_UNIXTIME(max_subm) AS max_submission_time, 
       IFNULL(CEIL((max_subm - LAG(max_subm) OVER(PARTITION BY student_name ORDER BY max_subm))/ 86400),'-') AS interval
FROM time_max JOIN requirements USING(student_name)
ORDER BY 1, 3;


