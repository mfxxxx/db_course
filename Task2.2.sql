--1.Выведите номера групп и количество студентов, обучающихся в них
SELECT ngroup, COUNT(*) as count_students 
FROM student 
GROUP BY ngroup;

--2.Выведите для каждой группы максимальный средний балл
SELECT ngroup, MAX(avg_score) as max_avg_score
FROM (
  SELECT ngroup, AVG(score) as avg_score
  FROM student
  GROUP BY ngroup, id
) as temp
GROUP BY ngroup;

--3.Подсчитать количество студентов с каждой фамилией
SELECT surname, COUNT(*) as count
FROM student
GROUP BY surname;

--4.Подсчитать студентов, которые родились в каждом году
SELECT EXTRACT(YEAR FROM datebirth) as birth_year, COUNT(*) as count
FROM student
GROUP BY birth_year;

--5.Для студентов каждого курса подсчитать средний балл
SELECT substr(CAST(ngroup as char(4)), 1, 1) as n_cource, AVG(score) 
FROM student 
GROUP BY substr(CAST(ngroup as char(4)), 1, 1);

--6.Для студентов заданного курса вывести один номер группы с максимальным средним баллом
SELECT substr(CAST(ngroup AS text), 1, 1) AS course, ngroup, AVG(score) AS avg_score
FROM student
WHERE substr(CAST(ngroup AS text), 1, 1) = '2' --курс
GROUP BY substr(CAST(ngroup AS text), 1, 1), ngroup
ORDER BY avg_score DESC
LIMIT 1;

--7.Для каждой группы подсчитать средний балл, вывести на экран только те номера групп 
--и их средний балл, в которых он менее или равен 3.5. Отсортировать по от меньшего среднего балла к большему.
SELECT ngroup, AVG(score) as avg_score
FROM student
GROUP BY ngroup
HAVING AVG(score) <= 3.5
ORDER BY AVG(score)

--8.Для каждой группы в одном запросе вывести количество студентов, 
--максимальный балл в группе, средний балл в группе, минимальный балл в группе
SELECT ngroup,
COUNT(*) as count_students,
MAX(score) as max_score,
AVG(score) as avg_score,
MIN(score) as min_score
FROM student
GROUP BY ngroup
ORDER BY ngroup

--9.Вывести студента/ов, который/ые имеют наибольший балл в заданной группе
SELECT *
FROM student
WHERE ngroup = '2282' AND score = (SELECT MAX(score) FROM student WHERE ngroup = '2282')

--10.Аналогично 9 заданию, но вывести в одном запросе для каждой группы студента с максимальным баллом.
SELECT *
FROM student s1
WHERE s1.score = 
(
  SELECT MAX(s2.score) 
  FROM student s2 
  WHERE s2.ngroup = s1.ngroup
)