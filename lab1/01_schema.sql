CREATE DATABASE Pharmacy;
GO

CREATE TABLE pharmacies (
    pharmacy_id INT           IDENTITY(1,1) NOT NULL,
    name        NVARCHAR(40)   NOT NULL,
    address     NVARCHAR(80)   NOT NULL,
    city        NVARCHAR(30)   NOT NULL,
    info        NVARCHAR(100) NULL
);
GO

ALTER TABLE pharmacies
    ADD CONSTRAINT pk_pharmacies PRIMARY KEY CLUSTERED (pharmacy_id);
ALTER TABLE pharmacies
    ADD CONSTRAINT df_pharmacies_info DEFAULT (NULL) FOR info;
GO

CREATE TABLE employees (
    employee_id INT         IDENTITY(1,1) NOT NULL,
    full_name   NVARCHAR(60) NOT NULL,
    address     NVARCHAR(80) NOT NULL,
    job_title   NVARCHAR(30) NOT NULL,
    pharmacy_id INT         NOT NULL
);
GO

ALTER TABLE employees
    ADD CONSTRAINT pk_employees PRIMARY KEY CLUSTERED (employee_id);
ALTER TABLE employees
    ADD CONSTRAINT fk_employees_pharmacy FOREIGN KEY (pharmacy_id)
        REFERENCES pharmacies (pharmacy_id);
GO

CREATE TABLE medicines (
    medicine_id       INT         IDENTITY(1,1) NOT NULL,
    name              NVARCHAR(50) NOT NULL,
    producer          NVARCHAR(40) NOT NULL,
    base_price        MONEY       NOT NULL,
    prescription_only BIT         NOT NULL
);
GO

ALTER TABLE medicines
    ADD CONSTRAINT pk_medicines PRIMARY KEY CLUSTERED (medicine_id);
ALTER TABLE medicines
    ADD CONSTRAINT df_medicines_rx DEFAULT (0) FOR prescription_only;
ALTER TABLE medicines
    ADD CONSTRAINT ck_medicines_price CHECK (base_price > 0);
GO

-- асортимент: один препарат може бути в багатьох аптеках зі своєю ціною й залишком
CREATE TABLE stock (
    pharmacy_id INT          NOT NULL,
    medicine_id INT          NOT NULL,
    price       MONEY        NOT NULL,
    quantity    INT          NOT NULL,
    note        NVARCHAR(60) NULL
);
GO

ALTER TABLE stock
    ADD CONSTRAINT pk_stock PRIMARY KEY CLUSTERED (pharmacy_id, medicine_id);
ALTER TABLE stock
    ADD CONSTRAINT fk_stock_pharmacy FOREIGN KEY (pharmacy_id)
        REFERENCES pharmacies (pharmacy_id);
ALTER TABLE stock
    ADD CONSTRAINT fk_stock_medicine FOREIGN KEY (medicine_id)
        REFERENCES medicines (medicine_id);
ALTER TABLE stock
    ADD CONSTRAINT ck_stock_price CHECK (price > 0);
ALTER TABLE stock
    ADD CONSTRAINT ck_stock_quantity CHECK (quantity >= 0);
GO

CREATE TABLE orders (
    order_id    INT   IDENTITY(1,1) NOT NULL,
    pharmacy_id INT   NOT NULL,
    employee_id INT   NOT NULL,
    order_date  DATE  NOT NULL,
    total_sum   MONEY NOT NULL
);
GO

ALTER TABLE orders
    ADD CONSTRAINT pk_orders PRIMARY KEY CLUSTERED (order_id);
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_pharmacy FOREIGN KEY (pharmacy_id)
        REFERENCES pharmacies (pharmacy_id);
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_employee FOREIGN KEY (employee_id)
        REFERENCES employees (employee_id);
ALTER TABLE orders
    ADD CONSTRAINT df_orders_date DEFAULT (CAST(GETDATE() AS DATE)) FOR order_date;
ALTER TABLE orders
    ADD CONSTRAINT df_orders_total DEFAULT (0) FOR total_sum;
GO

CREATE TABLE order_items (
    order_item_id INT   IDENTITY(1,1) NOT NULL,
    order_id      INT   NOT NULL,
    medicine_id   INT   NOT NULL,
    quantity      INT   NOT NULL,
    unit_price    MONEY NOT NULL
);
GO

ALTER TABLE order_items
    ADD CONSTRAINT pk_order_items PRIMARY KEY CLUSTERED (order_item_id);
ALTER TABLE order_items
    ADD CONSTRAINT fk_items_order FOREIGN KEY (order_id)
        REFERENCES orders (order_id);
ALTER TABLE order_items
    ADD CONSTRAINT fk_items_medicine FOREIGN KEY (medicine_id)
        REFERENCES medicines (medicine_id);
ALTER TABLE order_items
    ADD CONSTRAINT ck_items_quantity CHECK (quantity > 0);
ALTER TABLE order_items
    ADD CONSTRAINT uq_items_order_medicine UNIQUE (order_id, medicine_id);
GO
