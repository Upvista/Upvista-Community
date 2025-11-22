CREATE DATABASE UniversityDB;
USE UniversityDB;

CREATE TABLE Students (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(50),
    Department VARCHAR(50)
);

CREATE TABLE Courses (
    CourseID INT PRIMARY KEY AUTO_INCREMENT,
    CourseName VARCHAR(50)
);

CREATE TABLE Enrollments (
    EnrollmentID INT PRIMARY KEY AUTO_INCREMENT,
    StudentID INT,
    CourseID INT,
    FOREIGN KEY (StudentID) REFERENCES Students(ID),
    FOREIGN KEY (CourseID) REFERENCES Courses(CourseID)
);

CREATE TABLE Teachers (
    TeacherID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(50)
);

CREATE TABLE Subjects (
    SubjectID INT PRIMARY KEY AUTO_INCREMENT,
    SubjectName VARCHAR(50)
);

INSERT INTO Students (Name, Department) VALUES
('Ali', 'CS'),
('Sara', 'IT'),
('Bilal', 'CS'),
('Hina', 'AI');

INSERT INTO Courses (CourseName) VALUES
('Database Systems'),
('Operating Systems'),
('Web Development');

INSERT INTO Enrollments (StudentID, CourseID) VALUES
(1, 1),
(2, 2),
(3, 1);

INSERT INTO Teachers (Name) VALUES
('Mr. Ahmed'),
('Ms. Fatima');

INSERT INTO Subjects (SubjectName) VALUES
('Mathematics'),
('Physics'),
('Programming');

SELECT Students.Name, Courses.CourseName
FROM Students
INNER JOIN Enrollments ON Students.ID = Enrollments.StudentID
INNER JOIN Courses ON Enrollments.CourseID = Courses.CourseID;

SELECT Teachers.Name AS Teacher, Subjects.SubjectName AS Subject
FROM Teachers
CROSS JOIN Subjects;

SELECT * FROM Students
NATURAL JOIN Enrollments;

SELECT Students.Name, Courses.CourseName
FROM Students
LEFT OUTER JOIN Enrollments ON Students.ID = Enrollments.StudentID
LEFT OUTER JOIN Courses ON Enrollments.CourseID = Courses.CourseID;

SELECT Students.Name, Courses.CourseName
FROM Students
RIGHT OUTER JOIN Enrollments ON Students.ID = Enrollments.StudentID
RIGHT OUTER JOIN Courses ON Enrollments.CourseID = Courses.CourseID;

SELECT Students.Name, Courses.CourseName
FROM Students
LEFT JOIN Enrollments ON Students.ID = Enrollments.StudentID
LEFT JOIN Courses ON Enrollments.CourseID = Courses.CourseID
UNION
SELECT Students.Name, Courses.CourseName
FROM Students
RIGHT JOIN Enrollments ON Students.ID = Enrollments.StudentID
RIGHT JOIN Courses ON Enrollments.CourseID = Courses.CourseID;