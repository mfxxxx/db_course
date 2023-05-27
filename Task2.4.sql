--1)
--Удалите всех студентов с неуказанной датой 
DELETE FROM student
WHERE datebirth IS NULL;

--2)
--Измените дату рождения всех студентов, с неуказанной датой рождения на 01-01-1999
UPDATE student
SET datebirth = '1999-01-01'
WHERE datebirth IS NULL;

--3)
--Удалите из таблицы студента с номером зачётки 21
DELETE FROM student
WHERE id = 21;

--4)
--Уменьшите риск хобби, которым занимается наибольшее количество человек
select h.name, h.risk
from hobby h
join (
  select id, count (*) as cnt, rank () over (order by count (*) desc) as rnk
  from student_hobby
  group by id
) sh on h.id = sh.id
where sh.rnk = 1;

--5)
--Добавьте всем студентам, которые занимаются хотя бы одним хобби 0.01 балл
UPDATE student
SET score = score + 0.01
WHERE id IN (SELECT DISTINCT id_student FROM student_hobby);	

--6)
--Удалите все завершенные хобби студентов
DELETE FROM student_hobby
WHERE date_finish IS NOT NULL;

--7)
--Добавьте студенту с id 4 хобби с id 5. date_start - '15-11-2009, date_finish - null
INSERT INTO student_hobby (id, id_student, id_hobby, date_start, date_finish)
VALUES (10, 4, 5, '11-15-2009', NULL);

--8)
--Напишите запрос, который удаляет самую раннюю из студентов_хобби запись, в случае, если студент делал перерыв в хобби (т.е. занимался одним и тем же несколько раз)
DELETE FROM student_hobby
WHERE id IN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY id_student, id_hobby ORDER BY date_start) AS rn
    FROM student_hobby
  ) AS sub
  WHERE rn > 1
);

--9)
--Поменяйте название хобби всем студентам, кто занимается футболом - на бальные танцы, а кто баскетболом - на вышивание крестиком.
UPDATE student_hobby
SET id_hobby = CASE
  WHEN id_hobby IN (SELECT id FROM hobby WHERE name = 'Футбол') THEN (SELECT id FROM hobby WHERE name = 'Бальные танцы')
  WHEN id_hobby IN (SELECT id FROM hobby WHERE name = 'Баскетбол') THEN (SELECT id FROM hobby WHERE name = 'Вышивание крестиком')
END
WHERE id_hobby IN (SELECT id FROM hobby WHERE name IN ('Футбол', 'Баскетбол'));

--10)
--Добавьте в таблицу хобби новое хобби с названием "Учёба"
INSERT INTO hobby (id, name, risk)
VALUES (11, 'Учёба', 0.3);

--11)
--У всех студентов, средний балл которых меньше 3.2 поменяйте во всех хобби (если занимается чем-либо) и добавьте (если ничем не занимается), что студент занимается хобби из 10 задания
UPDATE student_hobby sh
SET id_hobby = (SELECT id FROM hobby WHERE name = 'Учёба'),
    date_start = CURRENT_DATE
FROM student s
WHERE sh.id_student = s.id
AND s.score < 3.2;

--12)
--Переведите всех студентов не 4 курса на курс выше
UPDATE student s
SET ngroup = ngroup + 1000
WHERE ngroup / 1000 <> 4;

--13)
--Удалите из таблицы студента с номером зачётки 2
DELETE FROM student
WHERE id = 2;

--14)
--Измените средний балл у всех студентов, которые занимаются хобби более 10 лет на 5.00
UPDATE student s
SET score = 5.00
FROM student_hobby sh
WHERE s.id = sh.id_student
AND DATE_PART ('year', COALESCE (sh.date_finish, CURRENT_DATE)) - DATE_PART ('year', sh.date_start) > 10;

--15)
--Удалите информацию о хобби, если студент начал им заниматься раньше, чем родился
DELETE FROM student_hobby USING student
WHERE student_hobby.id_student = student.id
AND (student_hobby.date_start < student.datebirth
OR COALESCE (student_hobby.date_finish, CURRENT_DATE) < student.datebirth);



--Задания на изменение/удаление/добавление без каскадного удаления/изменения


CREATE TABLE student_hobby (
    id          SERIAL PRIMARY KEY,
    student_id  INTEGER NOT NULL REFERENCES student(id) ON DELETE NO ACTION,
    hobby_id    INTEGER NOT NULL REFERENCES hobby(id) ON DELETE NO ACTION,
    date_start  TIMESTAMP NOT NULL,
    date_finish DATE
);


BEGIN;

ALTER TABLE student_hobby DROP CONSTRAINT student_hobby_student_id_fkey;
ALTER TABLE student_hobby DROP CONSTRAINT student_hobby_hobby_id_fkey;

ALTER TABLE student_hobby ADD CONSTRAINT student_hobby_student_id_fkey
FOREIGN KEY (id)
REFERENCES student (id);

ALTER TABLE student_hobby ADD CONSTRAINT student_hobby_hobby_id_fkey
FOREIGN KEY (hobby_id)
REFERENCES hobby (id);

ROLLBACK;



--1) Удалите всех студентов с неуказанной датой рождения


--DELETE FROM student WHERE datebirth IS NULL; - это не сработало, пришлось писать то что ниже :)

DELETE FROM student_hobby
WHERE id_student IN (
SELECT id FROM student WHERE datebirth IS NULL
);
DELETE FROM student WHERE datebirth IS NULL;


--2) Измените дату рождения всех студентов, с неуказанной датой рождения на 01-01-1999

UPDATE student SET datebirth = '1999-01-01' WHERE datebirth IS NULL;


--3) Удалите из таблицы студента с номером зачётки 21

DELETE FROM student WHERE id = 21;


--4) Уменьшите риск хобби, которым занимается наибольшее количество человек


UPDATE hobby SET risk = risk - 0.10 WHERE id = (
  SELECT id_hobby
  FROM student_hobby
  GROUP BY id_hobby
  ORDER BY COUNT(*) DESC
  LIMIT 1
);

--5) Добавьте всем студентам, которые занимаются хотя бы одним хобби 0.01 балл

UPDATE public.student
SET score = score + 0.01
WHERE id IN (
  SELECT DISTINCT id_student
  FROM public.student_hobby
)


--6) Удалите все завершенные хобби студентов

DELETE FROM public.student_hobby WHERE date_finish IS NOT NULL;



--7) Добавьте студенту с id 4 хобби с id 5. date_start - '15-11-2009, date_finish - null

INSERT INTO public.student_hobby (id_student, id_hobby, date_start, date_finish)
VALUES (4, 5, '2009-11-15', NULL);



--8) Напишите запрос, который удаляет самую раннюю из студентов_хобби запись, 
--в случае, если студент делал перерыв в хобби (т.е. занимался одним и тем же несколько раз)

DELETE FROM public.student_hobby sh1
WHERE date_start = (
  SELECT MIN(date_start) 
  FROM public.student_hobby sh2 
  WHERE sh1.id_student = sh2.id_student
  AND sh1.id_hobby = sh2.id_hobby
  AND sh2.date_finish IS NOT NULL
);


--9 Поменяйте название хобби всем студентам, кто занимается футболом - на бальные танцы, а кто баскетболом - на вышивание крестиком.
--(замена названий и обновление id в student_hobby)
--а
UPDATE public.hobby
SET name = 
  CASE 
    WHEN name = 'Футбол' THEN 'Бальные танцы'
    WHEN name = 'Баскетбол' THEN 'Вышивание крестиком'
    ELSE name
  END;

--б
UPDATE public.student_hobby
SET id_hobby = 
  CASE 
    WHEN id_hobby = 1 THEN (SELECT id FROM public.hobby WHERE name = 'Бальные танцы')
    WHEN id_hobby = 51 THEN (SELECT id FROM public.hobby WHERE name = 'Вышивание крестиком')
    ELSE id_hobby
  END
WHERE id_hobby IN (1, 3);


--10) Добавьте в таблицу хобби новое хобби с названием "Учёба"


INSERT INTO public.hobby (id, name, risk) VALUES (
  (SELECT COALESCE(MAX(id), 0) + 1 FROM public.hobby),
  'Учёба',
  0.1
);


--11) У всех студентов, средний балл которых меньше 3.2 поменяйте во всех хобби (если занимается чем-либо) 
--и добавьте (если ничем не занимается), что студент занимается хобби из 10 задания

SELECT id FROM student WHERE score < 3.2;

INSERT INTO student_hobby (id, id_student, id_hobby, date_start)
SELECT (MAX(id) + ROW_NUMBER() OVER (ORDER BY student.id)), student.id, 9, NOW()
FROM student
WHERE student.score < 3.2
GROUP BY student.id;


--12) Переведите всех студентов не 4 курса на курс выше

UPDATE student
SET ngroup = (ngroup/1000 + 1)*1000 + ngroup%1000
WHERE ngroup/1000 < 4;


--13) Удалите из таблицы студента с номером зачётки 2

DELETE FROM student_hobby WHERE id_student = 2;
DELETE FROM student WHERE id = 2;



--14) Измените средний балл у всех студентов, которые занимаются хобби более 10 лет на 5.00

UPDATE student
SET score = 5.00
WHERE id IN (
  SELECT id_student
  FROM student_hobby
  WHERE EXTRACT(YEAR FROM age(date_start)) > 10
);


--15) Удалите информацию о хобби, если студент начал им заниматься раньше, чем родился

DELETE FROM student_hobby 
USING student 
WHERE student_hobby.id_student = student.id 
  AND student_hobby.date_start < student.datebirth;
