
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












