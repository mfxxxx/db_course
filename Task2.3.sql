--1) 
--Вывести все имена и фамилии студентов, и название хобби, которым занимается 
--этот студент (student_hobby.student_id равен student.id и student_hobby.hobby_id равен hobby.id.)
SELECT student.name, student.surname, hobby.name AS hobby_name
FROM student_hobby
JOIN student ON student.id = student_hobby.id_student
JOIN hobby ON hobby.id = student_hobby.id_hobby;

--2) 
--Вывести информацию о студенте, занимающимся хобби самое продолжительное время.
SELECT s.name, s.surname, h.name AS hobby_name, sh.date_start, sh.date_finish
FROM student s
JOIN student_hobby sh ON s.id = sh.id_student
JOIN hobby h ON h.id = sh.id_hobby
WHERE sh.date_finish - sh.date_start = (
  SELECT MAX(date_finish - date_start) 
  FROM student_hobby
)

--3) 
--Вывести имя, фамилию, номер зачетки и дату рождения для студентов, 
--средний балл которых выше среднего, а сумма риска всех хобби, которыми он занимается в данный момент, больше 0.9.
SELECT s.name, s.surname, s.ngroup, s.datebirth
FROM student s
JOIN student_hobby sh ON sh.id_student = s.id
JOIN hobby h ON h.id = sh.id_hobby
WHERE sh.date_finish IS NULL
GROUP BY s.id
HAVING AVG(s.score) > (SELECT AVG(score) FROM student) AND SUM(h.risk) > 0.9;

--4) 
--Вывести фамилию, имя, зачетку, дату рождения, название хобби и длительность в месяцах, для всех завершенных хобби Диапазон дат.
SELECT s.surname, s.name, s.ngroup, s.datebirth, h.name, 
  DATE_PART('month', age(sh.date_finish, sh.date_start)) 
    + 12 * DATE_PART('year', age(sh.date_finish, sh.date_start)) 
    AS duration_months
FROM student s 
JOIN student_hobby sh ON sh.id_student = s.id 
JOIN hobby h ON h.id = sh.id_hobby
WHERE sh.date_finish BETWEEN '2021-01-01' AND '2021-12-31' 
  AND s.score > (SELECT AVG(score) FROM student);

--5) 
--Вывести фамилию, имя, зачетку, дату рождения студентов, которым исполнилось 
--N полных лет на текущую дату, и которые имеют более 1 действующего хобби.
SELECT s.surname, s.name, s.ngroup, s.datebirth
FROM student s
JOIN student_hobby sh ON sh.id_student = s.id
WHERE DATE_PART('year', AGE(CURRENT_DATE, s.datebirth)) = 20
AND (sh.date_finish IS NULL OR sh.date_finish > CURRENT_DATE)
GROUP BY s.id
HAVING COUNT (sh.id_hobby) > 1;

--6) 
--Найти средний балл в каждой группе, учитывая только баллы студентов, которые имеют хотя бы одно действующее хобби.
SELECT s.ngroup, AVG (s.score) AS avg_score
FROM student s
JOIN student_hobby sh ON sh.id_student = s.id
WHERE (sh.date_finish IS NULL OR sh.date_finish > CURRENT_DATE)
GROUP BY s.ngroup;

--7) 
--Найти название, риск, длительность в месяцах самого продолжительного 
--хобби из действующих, указав номер зачетки студента.
SELECT h.name, h.risk, DATE_PART('month', age(COALESCE(sh.date_finish, CURRENT_DATE), sh.date_start)) AS duration
FROM hobby h
JOIN student_hobby sh ON sh.id_hobby = h.id
WHERE (sh.date_finish IS NULL OR sh.date_finish > CURRENT_DATE)
ORDER BY duration DESC
LIMIT 1;

--8)
--Найти все хобби, которыми увлекаются студенты, имеющие максимальный балл.
SELECT h.name
FROM hobby h
JOIN student_hobby sh ON sh.id_hobby = h.id
JOIN student s ON s.id = sh.id_student
WHERE s.score = (SELECT MAX(score) FROM student);

--9) 
--Найти все действующие хобби, которыми увлекаются троечники 2-го курса.
SELECT h.name
FROM hobby h
JOIN student_hobby sh ON sh.id_hobby = h.id
JOIN student s ON s.id = sh.id_student
WHERE (sh.date_finish IS NULL OR sh.date_finish > CURRENT_DATE)
AND s.score > 3 AND s.score < 3.5
AND CAST(s.ngroup AS text) LIKE '2%';

--10) 
--Найти номера курсов, на которых более 50% студентов имеют более одного действующего хобби.
SELECT s.ngroup/1000
FROM student s
JOIN (
  SELECT id_student, COUNT (id_hobby) AS hobby_count
  FROM student_hobby
  WHERE (date_finish IS NULL OR date_finish > CURRENT_DATE)
  GROUP BY id_student
) sh ON sh.id_student = s.id
GROUP BY s.ngroup
HAVING 100.0 * SUM (CASE WHEN sh.hobby_count > 1 THEN 1 ELSE 0 END) / COUNT (DISTINCT s.id) < 50;

-- Знак "<" потому что в таблицах нет таких групп

--11) 
--Вывести номера групп, в которых не менее 60% студентов имеют балл не ниже 4.
SELECT s.ngroup
FROM student s
GROUP BY s.ngroup
HAVING 100.0 * SUM (CASE WHEN s.score >= 4 THEN 1 ELSE 0 END) / COUNT (*) >= 60;

--12) 
--Для каждого курса подсчитать количество различных действующих хобби на курсе.
SELECT s.ngroup/1000 AS cours, COUNT (DISTINCT sh.id_hobby) AS hobby_count
FROM student s
JOIN student_hobby sh ON sh.id_student = s.id
WHERE (sh.date_finish IS NULL OR sh.date_finish > CURRENT_DATE)
GROUP BY s.ngroup;

--13) 
--Вывести номер зачётки, фамилию и имя, дату рождения и номер курса для всех отличников,
--не имеющих хобби. Отсортировать данные по возрастанию в пределах курса по убыванию даты рождения.
SELECT s.id, s.surname, s.name, s.datebirth, s.ngroup
FROM student s
LEFT JOIN student_hobby sh ON sh.id_student = s.id
WHERE s.score = 5
AND sh.id_student IS NULL
ORDER BY s.ngroup ASC, s.datebirth DESC;

--14) 
--Создать представление, в котором отображается вся информация о студентах, 
--которые продолжают заниматься хобби в данный момент и занимаются им как минимум 5 лет.
CREATE VIEW active_hobby_students AS
SELECT s.*
FROM student s
JOIN student_hobby sh ON sh.id_student = s.id
WHERE (sh.date_finish IS NULL OR sh.date_finish > CURRENT_DATE)
AND DATE_PART('year', make_interval(days => COALESCE(sh.date_finish, CURRENT_DATE) - sh.date_start)) >= 5;

--15) 
--Для каждого хобби вывести количество людей, которые им занимаются.
SELECT h.name, COUNT (sh.id_student) AS people_count
FROM hobby h
JOIN student_hobby sh ON sh.id_hobby = h.id
GROUP BY h.name;

--16) 
--Вывести ИД самого популярного хобби.
SELECT h.id, COUNT (sh.id_student) AS people_count
FROM hobby h
JOIN student_hobby sh ON sh.id_hobby = h.id
GROUP BY h.id
ORDER BY people_count DESC
LIMIT 1;

--17) 
--Вывести всю информацию о студентах, занимающихся самым популярным хобби.
WITH most_popular_hobby AS (
  SELECT id_hobby, COUNT (id_student) AS num_students
  FROM student_hobby
  GROUP BY id_hobby
  ORDER BY num_students DESC
  LIMIT 1
)
SELECT s.*
FROM student s
JOIN student_hobby sh ON s.id = sh.id_student
JOIN most_popular_hobby mph ON sh.id_hobby = mph.id_hobby;

--18) 
--Вывести ИД 3х хобби с максимальным риском.
SELECT id
FROM hobby
ORDER BY risk DESC
LIMIT 3;

--19) 
--Вывести 10 студентов, которые занимаются одним (или несколькими) хобби самое продолжительно время.
WITH hobby_duration AS (
  SELECT id_student, id_hobby, (date_finish - date_start) AS duration
  FROM student_hobby
)
SELECT id_student, SUM(duration) AS total_duration
FROM hobby_duration
GROUP BY id_student
ORDER BY total_duration DESC
LIMIT 10;

--20) 
--Вывести номера групп (без повторений), в которых учатся студенты из предыдущего запроса.
WITH top_students AS (
  WITH hobby_duration AS (
    SELECT id_student, id_hobby, (date_finish - date_start) AS duration
    FROM student_hobby
  )
  SELECT id_student, SUM (duration) AS total_duration
  FROM hobby_duration
  GROUP BY id_student
  ORDER BY total_duration DESC
  LIMIT 10
)
SELECT DISTINCT s.ngroup
FROM student s
JOIN top_students ts ON s.id = ts.id_student;

--21) 
--Создать представление, которое выводит номер зачетки, имя и фамилию студентов, отсортированных по убыванию среднего балла.
CREATE VIEW student_view AS
SELECT id, name, surname
FROM student;
SELECT sv.*
FROM student_view sv
JOIN student s ON sv.id = s.id
ORDER BY s.score DESC;

--22) 
--Представление: найти каждое популярное хобби на каждом курсе.
CREATE VIEW course_hobby_view AS
SELECT s.ngroup AS course, h.name AS hobby, COUNT (sh.id_student) AS num_students
FROM student s
JOIN student_hobby sh ON s.id = sh.id_student
JOIN hobby h ON sh.id_hobby = h.id
GROUP BY s.ngroup, h.name;

SELECT course, MODE () WITHIN GROUP (ORDER BY num_students DESC) AS most_popular_hobby
FROM course_hobby_view
GROUP BY course;

--23) 
--Представление: найти хобби с максимальным риском среди самых популярных хобби на 2 курсе.
--Создаем представление с номером курса, названием хобби, уровнем риска и количеством студентов
CREATE VIEW course_hobby_risk_view AS
SELECT s.ngroup/1000 AS course, h.name AS hobby, h.risk AS risk, COUNT (sh.id_student) AS num_students
FROM student s
JOIN student_hobby sh ON s.id = sh.id_student
JOIN hobby h ON sh.id_hobby = h.id
GROUP BY s.ngroup, h.name, h.risk;
WITH popular_hobbies AS (
  SELECT hobby, num_students
  FROM course_hobby_risk_view
  WHERE course = 2
  AND num_students = (SELECT MAX (num_students) FROM course_hobby_risk_view WHERE course = 2)
)
SELECT hobby, risk
FROM popular_hobbies ph
JOIN hobby h ON ph.hobby = h.name
WHERE risk = (SELECT MAX (risk) FROM popular_hobbies ph JOIN hobby h ON ph.hobby = h.name);

--24) 
--Представление: для каждого курса подсчитать количество студентов на курсе и количество отличников.
CREATE VIEW course_students_view AS
SELECT ngroup AS course, COUNT (id) AS num_students, COUNT (CASE WHEN score >= 4.5 THEN 1 END) AS num_excellent
FROM student
GROUP BY ngroup;

SELECT *
FROM course_students_view;

--25) 
--Представление: самое популярное хобби среди всех студентов.
CREATE VIEW hobby_students_view AS
SELECT h.name AS hobby, COUNT (sh.id_student) AS num_students
FROM hobby h
JOIN student_hobby sh ON h.id = sh.id_hobby
GROUP BY h.name;

SELECT hobby, num_students
FROM hobby_students_view
WHERE num_students = (SELECT MAX(num_students) FROM hobby_students_view);

--26) 
--Создать обновляемое представление.
CREATE OR REPLACE VIEW updateable_view AS
SELECT s.id, s.name, s.surname, sh.date_start, sh.date_finish
FROM student s
JOIN student_hobby sh ON s.id = sh.id_student;

--27) 
--Для каждой буквы алфавита из имени найти максимальный, средний и минимальный балл. 
--(Т.е. среди всех студентов, чьё имя начинается на А (Алексей, Алина, Артур, Анджела) 
--найти то, что указано в задании. Вывести на экран тех, максимальный балл которых больше 3.6
CREATE VIEW letter_score_view AS
SELECT LEFT (name, 1) AS letter, MAX (score) AS max_score, AVG (score) AS avg_score, MIN (score) AS min_score
FROM student
GROUP BY LEFT (name, 1);

SELECT *
FROM letter_score_view
WHERE max_score > 3.6;

--28) 
--Для каждой фамилии на курсе вывести максимальный и минимальный средний балл. 
--(Например, в университете учатся 4 Иванова (1-2-3-4). 1-2-3 учатся на 2 курсе и 
--имеют средний балл 4.1, 4, 3.8 соответственно, а 4 Иванов учится на 3 курсе и имеет балл 4.5. 
--На экране должно быть следующее: 2 Иванов 4.1 3.8 3 Иванов 4.5 4.5
SELECT ngroup, surname, MAX (avg_score), MIN (avg_score)
FROM (
  SELECT ngroup, surname, AVG (score) AS avg_score
  FROM student
  GROUP BY ngroup, surname
) AS subquery
GROUP BY ngroup, surname;

--29) 
--Для каждого года рождения подсчитать количество хобби, которыми занимаются или занимались студенты.
SELECT EXTRACT (YEAR FROM datebirth) AS birth_year, COUNT (DISTINCT id_hobby) AS hobby_count
FROM student
JOIN student_hobby ON student.id = student_hobby.id_student
JOIN hobby ON student_hobby.id_hobby = hobby.id
GROUP BY birth_year;

--30) 
--Для каждой буквы алфавита в имени найти максимальный и минимальный риск хобби.
SELECT SUBSTRING(name, 1, 1) AS letter, MAX (risk) AS max_risk, MIN (risk) AS min_risk
FROM hobby
GROUP BY letter;

--31) 
--Для каждого месяца из даты рождения вывести средний балл студентов, которые занимаются хобби с названием «Футбол»
SELECT EXTRACT (MONTH FROM datebirth) AS birth_month, AVG (score) AS avg_score
FROM student
JOIN student_hobby ON student.id = student_hobby.id_student
JOIN hobby ON student_hobby.id_hobby = hobby.id
WHERE hobby.name = 'Футбол'
GROUP BY birth_month;

--32) 
--Вывести информацию о студентах, которые занимались или занимаются хотя бы 1 хобби 
--в следующем формате: Имя: Иван, фамилия: Иванов, группа: 1234
SELECT CONCAT('Имя: ', name, ', фамилия: ', surname, ', группа: ', ngroup) AS info
FROM student
JOIN student_hobby ON student.id = student_hobby.id_student
GROUP BY student.id;

--33) 
--Найдите в фамилии в каком по счёту символа встречается «ов». Если 0 (т.е. не встречается, то выведите на экран «не найдено»).
SELECT surname, CASE WHEN POSITION('ов' IN surname) > 0 THEN CAST(POSITION('ов' IN surname) AS VARCHAR) ELSE 'не найдено' END AS position
FROM student;

--34) 
--Дополните фамилию справа символом # до 10 символов.
SELECT surname, RPAD(surname, 10, '#') AS padded_surname
FROM student;

--35) 
--При помощи функции удалите все символы # из предыдущего запроса.
SELECT surname, REPLACE(RPAD(surname, 10, '#'), '#', '') AS unpadded_surname
FROM student;

--36) 
--Выведите на экран сколько дней в апреле 2018 года.
SELECT EXTRACT(DAY FROM '2018-04-30'::date) AS days_in_april_2018;

--37) 
--Выведите на экран какого числа будет ближайшая суббота.
SELECT CURRENT_DATE + (6 - EXTRACT(DOW FROM CURRENT_DATE))::integer AS nearest_saturday;

--38) 
--Выведите на экран век, а также какая сейчас неделя года и день года.
SELECT DATE_PART('century', CURRENT_DATE) AS century,
       DATE_PART('week', CURRENT_DATE) AS week_of_year,
       DATE_PART('doy', CURRENT_DATE) AS day_of_year;

--39) 
--Выведите всех студентов, которые занимались или занимаются хотя бы 1 хобби. 
--Выведите на экран Имя, Фамилию, Названию хобби, а также надпись «занимается», 
--если студент продолжает заниматься хобби в данный момент или «закончил», если уже не занимается.
SELECT student.name, student.surname, hobby.name AS hobby_name,
       CASE WHEN student_hobby.date_finish IS NULL THEN 'занимается'
            WHEN student_hobby.date_finish IS NOT NULL THEN 'закончил'
            ELSE 'неизвестно'
       END AS hobby_status
FROM student
JOIN student_hobby ON student.id = student_hobby.id_student
JOIN hobby ON student_hobby.id_hobby = hobby.id;

--40) 
--Для каждой группы вывести сколько студентов учится на 5,4,3,2. Использовать обычное математическое округление. 
--Итоговый результат должен выглядеть примерно в таком виде:
SELECT ngroup,
  COUNT(CASE WHEN ROUND(score) = 5 THEN 1 END) AS "5",
  COUNT(CASE WHEN ROUND(score) = 4 THEN 1 END) AS "4",
  COUNT(CASE WHEN ROUND(score) = 3 THEN 1 END) AS "3",
  COUNT(CASE WHEN ROUND(score) = 2 THEN 1 END) AS "2"
FROM student
GROUP BY ngroup
ORDER BY ngroup;