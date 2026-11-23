-- Завдання 0: функція, яка за назвою регіону (частина поля address)
-- повертає сумарну кількість працівників з цього регіону.

IF OBJECT_ID(N'dbo.ufn_employees_by_region', N'FN') IS NOT NULL
    DROP FUNCTION dbo.ufn_employees_by_region;
GO

CREATE FUNCTION ufn_employees_by_region (@region NVARCHAR(40))
RETURNS INT
AS
BEGIN
    DECLARE @emp_count INT;

    SET @emp_count = (SELECT COUNT(*)
                        FROM employees
                       WHERE address LIKE N'%' + @region + N'%');

    RETURN ISNULL(@emp_count, 0);
END
GO


-- перевірка
SELECT dbo.ufn_employees_by_region(N'Харківська') AS kharkiv_region,
       dbo.ufn_employees_by_region(N'Полтавська') AS poltava_region,
       dbo.ufn_employees_by_region(N'Київська')   AS kyiv_region,
       dbo.ufn_employees_by_region(N'Львівська')  AS lviv_region;
GO

DECLARE @region NVARCHAR(40) = N'Львівська';
DECLARE @cnt INT;
SET @cnt = dbo.ufn_employees_by_region(@region);

SELECT CASE WHEN @cnt = 0
            THEN N'Працівники з регіону «' + @region + N'» відсутні'
            ELSE N'Регіон «' + @region + N'»: працівників - '
                 + LTRIM(CAST(@cnt AS VARCHAR(10)))
       END AS result;
GO
