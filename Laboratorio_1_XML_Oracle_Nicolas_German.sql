
-- LABORATORIO 1: ALMACENAMIENTO Y VALIDACIÓN DE XML
-- ORACLE DATABASE 21c XE

-- 1. Verificación del entorno y consulta del esquema HR

-- Verificar el usuario conectado
SELECT USER AS USUARIO_ACTUAL FROM DUAL;

-- Verificar las tablas disponibles del esquema HR
SELECT table_name
FROM all_tables
WHERE owner = 'HR'
ORDER BY table_name;

-- Consultar los empleados
SELECT * FROM HR.EMPLOYEES;

-- Consultar los departamentos
SELECT * FROM HR.DEPARTMENTS;

-- Consultar los cargos
SELECT * FROM HR.JOBS;


-- 1.1 Verificación de las tablas del esquema HR

SELECT
    e.EMPLOYEE_ID,
    e.FIRST_NAME,
    e.LAST_NAME,
    d.DEPARTMENT_NAME,
    j.JOB_TITLE
FROM HR.EMPLOYEES e
LEFT JOIN HR.DEPARTMENTS d
    ON e.DEPARTMENT_ID = d.DEPARTMENT_ID
LEFT JOIN HR.JOBS j
    ON e.JOB_ID = j.JOB_ID
ORDER BY e.EMPLOYEE_ID;


-- 2. Generacion del documento XML mediante SQL/XML

SELECT XMLSERIALIZE(
    DOCUMENT
    XMLELEMENT("EmployeesReport",
        XMLAGG(
            XMLELEMENT("Employee",
                XMLATTRIBUTES(
                    e.employee_id AS "EmployeeID"
                ),
                XMLFOREST(
                    e.first_name AS "FirstName",
                    e.last_name AS "LastName",
                    e.salary AS "Salary"
                ),
                XMLELEMENT("Department",
                    XMLFOREST(
                        d.department_id AS "DepartmentID",
                        d.department_name AS "DepartmentName"
                    )
                ),
                XMLELEMENT("Job",
                    XMLFOREST(
                        j.job_id AS "JobID",
                        j.job_title AS "JobTitle"
                    )
                )
            )
            ORDER BY e.employee_id
        )
    )
    AS CLOB INDENT SIZE = 2
) AS XML_DOCUMENTO
FROM HR.EMPLOYEES e
LEFT JOIN HR.DEPARTMENTS d
    ON e.department_id = d.department_id
LEFT JOIN HR.JOBS j
    ON e.job_id = j.job_id;
    

-- 5. Registro del esquema XSD en Oracle

BEGIN
    DBMS_XMLSCHEMA.registerSchema(
        schemaURL => 'http://example.com/hr/empleados_hr.xsd',

        schemaDoc => q'~
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">

    <xs:element name="EmployeesReport">
        <xs:complexType>
            <xs:sequence>

                <xs:element name="Employee"
                            minOccurs="1"
                            maxOccurs="unbounded">
                    <xs:complexType>
                        <xs:sequence>

                            <xs:element name="FirstName"
                                        type="xs:string"
                                        minOccurs="0"/>

                            <xs:element name="LastName"
                                        type="xs:string"/>

                            <xs:element name="Salary"
                                        type="xs:decimal"
                                        minOccurs="0"/>

                            <xs:element name="Department">
                                <xs:complexType>
                                    <xs:sequence>

                                        <xs:element name="DepartmentID"
                                                    type="xs:integer"
                                                    minOccurs="0"/>

                                        <xs:element name="DepartmentName"
                                                    type="xs:string"
                                                    minOccurs="0"/>

                                    </xs:sequence>
                                </xs:complexType>
                            </xs:element>

                            <xs:element name="Job">
                                <xs:complexType>
                                    <xs:sequence>

                                        <xs:element name="JobID"
                                                    type="xs:string"/>

                                        <xs:element name="JobTitle"
                                                    type="xs:string"/>

                                    </xs:sequence>
                                </xs:complexType>
                            </xs:element>

                        </xs:sequence>

                        <xs:attribute name="EmployeeID"
                                      type="xs:integer"
                                      use="required"/>

                    </xs:complexType>
                </xs:element>

            </xs:sequence>
        </xs:complexType>
    </xs:element>

</xs:schema>
~',
        local     => TRUE,
        genTypes  => FALSE,
        genTables => FALSE,
        options   => DBMS_XMLSCHEMA.REGISTER_BINARYXML
    );
END;
/


-- 5.1. Verificacion del esquema XSD registrado

SELECT schema_url
FROM user_xml_schemas
WHERE schema_url = 'http://example.com/hr/empleados_hr.xsd';


-- 6. Creacion de la tabla para almacenar y validar XML

CREATE TABLE LAB_DOCUMENTOS_XML (
    ID NUMBER PRIMARY KEY,
    DOCUMENTO XMLTYPE NOT NULL,

    CONSTRAINT CK_LAB_XML_VALIDO
    CHECK (
        XMLISVALID(
            DOCUMENTO,
            'http://example.com/hr/empleados_hr.xsd',
            'EmployeesReport'
        ) = 1
    )
)
XMLTYPE COLUMN DOCUMENTO STORE AS BINARY XML;


-- 7. Insercion de un documento XML valido

INSERT INTO LAB_DOCUMENTOS_XML (ID, DOCUMENTO)
VALUES (
    1,
    XMLTYPE(
        '<EmployeesReport>
            <Employee EmployeeID="900">
                <FirstName>Carlos</FirstName>
                <LastName>Ramirez</LastName>
                <Salary>3500</Salary>
                <Department>
                    <DepartmentID>60</DepartmentID>
                    <DepartmentName>IT</DepartmentName>
                </Department>
                <Job>
                    <JobID>IT_PROG</JobID>
                    <JobTitle>Programmer</JobTitle>
                </Job>
            </Employee>
        </EmployeesReport>'
    )
);

COMMIT;


-- 8. Insercion de un documento XML invalido

INSERT INTO LAB_DOCUMENTOS_XML (ID, DOCUMENTO)
VALUES (
    2,
    XMLTYPE(
        '<EmployeesReport>
            <Employee EmployeeID="901">
                <FirstName>Laura</FirstName>
                <LastName>Gomez</LastName>
                <Salary>NO_VALIDO</Salary>
                <Department>
                    <DepartmentID>60</DepartmentID>
                    <DepartmentName>IT</DepartmentName>
                </Department>
                <Job>
                    <JobID>IT_PROG</JobID>
                    <JobTitle>Programmer</JobTitle>
                </Job>
            </Employee>
        </EmployeesReport>'
    )
);



-- 9. Verificacion de los documentos XML almacenados

-- Consultar los documentos registrados
SELECT ID, XMLISVALID(
    DOCUMENTO,
    'http://example.com/hr/empleados_hr.xsd',
    'EmployeesReport'
) AS XML_VALIDO
FROM LAB_DOCUMENTOS_XML
ORDER BY ID;

-- Contar los documentos almacenados
SELECT COUNT(*) AS TOTAL_DOCUMENTOS
FROM LAB_DOCUMENTOS_XML;