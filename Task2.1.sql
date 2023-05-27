--1.Вывести всеми возможными способами имена и фамилии студентов, средний балл которых от 4 до 4.5
SELECT name, surname FROM student st WHERE st.score >= 4 AND st.score <= 4.5 ORDER BY st.score DESC
SELECT name, surname FROM student st WHERE st.score BETWEEN 4.0 and 4.5

--2.Познакомиться с функцией CAST. Вывести при помощи неё студентов заданного курса (использовать Like)
SELECT st.name, st.surname FROM student st WHERE CAST (st.ngroup AS varchar) LIKE '%2282'

--3.Вывести всех студентов, отсортировать по убыванию номера группы и имени от а до я
SELECT * FROM student st ORDER BY st.ngroup, st.name

--4.Вывести студентов, средний балл которых больше 4 и отсортировать по баллу от большего к меньшему
SELECT * FROM student st WHERE st.score > 4 ORDER BY st.score DESC

--5.Вывести на экран название и риск 2-х хобби (на своё усмотрение)
SELECT name, risk FROM hobby h WHERE h.name IN ('Танцы', 'Волейбол')

--6.Вывести id_hobby и id_student которые начали заниматься хобби между двумя заданными датами (выбрать самим) и студенты должны до сих пор заниматься хобби
SELECT st.id_hobby,st.id_student FROM student_hobby st WHERE (st.date_start BETWEEN '2020-01-01' AND '2023-10-02')
AND
(st.date_finish IS NULL)

--7.Вывести студентов, средний балл которых больше 4.5 и отсортировать по баллу от большего к меньшему
SELECT * FROM student st WHERE st.score >= 4.5 ORDER BY st.score DESC

--8.Из запроса №7 вывести несколькими способами на экран только 5 студентов с максимальным баллом
SELECT * FROM student ORDER BY score DESC LIMIT 5;

--9.Выведите хобби и с использованием условного оператора сделайте риск словами.
SELECT *,
CASE
WHEN m.risk >= 8 THEN 'Очень высокий'
WHEN m.risk < 8 AND m.risk >= 6 THEN 'Высокий'
WHEN m.risk < 6 AND m.risk >= 4 THEN 'Средний'
WHEN m.risk < 4 AND m.risk >= 2 THEN 'Низкий'
ELSE 'Очень низкий'
END AS Category
FROM hobby m

--10.Вывести 3 хобби с максимальным риском
SELECT * FROM hobby ORDER BY risk DESC LIMIT 3;