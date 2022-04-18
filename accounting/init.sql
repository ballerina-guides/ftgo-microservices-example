CREATE DATABASE IF NOT EXISTS Accounting;

CREATE TABLE IF NOT EXISTS Accounting.bills (
    id          INTEGER         AUTO_INCREMENT PRIMARY KEY,
    consumerId  INTEGER         NOT NULL,
    orderId     INTEGER         NOT NULL,
    orderAmount DECIMAL(10,2)   NOT NULL
);
