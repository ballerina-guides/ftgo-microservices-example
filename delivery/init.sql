CREATE DATABASE IF NOT EXISTS Delivery;

CREATE TABLE IF NOT EXISTS Delivery.Couriers (
    id      INTEGER     AUTO_INCREMENT PRIMARY KEY,
    name    VARCHAR(50) NOT NULL
)

CREATE TABLE IF NOT EXISTS Delivery.Deliveries (
    id              INTEGER         AUTO_INCREMENT PRIMARY KEY,
    orderId         INTEGER         NOT NULL,
    courierId       INTEGER         NOT NULL,
    pickUpAddress   VARCHAR(255)    NOT NULL,
    pickUpTime      TIMESTAMP,
    deliveryAddress VARCHAR(255)    NOT NULL,
    deliveryTime    TIMESTAMP,
    status          VARCHAR(25)     NOT NULL,
    FOREIGN KEY (courierId) REFERENCES Delivery.Couriers(id) ON DELETE CASCADE
)
