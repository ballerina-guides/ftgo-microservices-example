// This is a module used for testing purposes. 

import ballerinax/mysql;

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;

public function main() returns error? {

    mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT);

    // Accounting 
    _ = check dbClient->execute(`CREATE DATABASE IF NOT EXISTS Accounting;`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Accounting.bills (
            id          INTEGER         AUTO_INCREMENT PRIMARY KEY,
            consumerId  INTEGER         NOT NULL,
            orderId     INTEGER         NOT NULL,
            orderAmount DECIMAL(10,2)   NOT NULL
        );
    `);
    

    // Consumer 
    _ = check dbClient->execute(`CREATE DATABASE IF NOT EXISTS Consumer;`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Consumer.Consumers (
            id      INTEGER         AUTO_INCREMENT PRIMARY KEY,
            name    VARCHAR(255)    NOT NULL,
            address VARCHAR(255)    NOT NULL,
            email   VARCHAR(255)    NOT NULL
        );
    `);


    // Order 
    _ = check dbClient->execute(`CREATE DATABASE IF NOT EXISTS Orders;`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Orders.Orders (
            id              INTEGER AUTO_INCREMENT PRIMARY KEY,
            consumerId      INTEGER NOT NULL,
            restaurantId    INTEGER NOT NULL,
            deliveryAddress VARCHAR(255) NOT NULL,
            deliveryTime    TIMESTAMP NOT NULL,
            status          VARCHAR(20) NOT NULL
        );
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Orders.OrderItems (
            id              INTEGER AUTO_INCREMENT PRIMARY KEY,
            menuItemId      INTEGER NOT NULL,
            quantity        INTEGER NOT NULL,
            orderId         INTEGER NOT NULL,
            FOREIGN KEY (orderId) REFERENCES Orders.Orders(id) ON DELETE CASCADE,
            CONSTRAINT chk_quantity CHECK (quantity > 0)
        );
    `);


    // Restaurant 
    _ = check dbClient->execute(`CREATE DATABASE IF NOT EXISTS Restaurant;`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Restaurant.Restaurants (
            id      INTEGER         AUTO_INCREMENT PRIMARY KEY,
            name    VARCHAR(255)    NOT NULL,
            address VARCHAR(255)    NOT NULL
        );
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Restaurant.Menus (
            id              INTEGER AUTO_INCREMENT PRIMARY KEY,
            name            VARCHAR(255) NOT NULL,
            restaurantId    INTEGER NOT NULL,
            FOREIGN KEY (restaurantId) REFERENCES Restaurant.Restaurants(id) ON DELETE CASCADE
        );
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Restaurant.MenuItems (
            id      INTEGER         AUTO_INCREMENT PRIMARY KEY,
            name    VARCHAR(255)    NOT NULL,
            price   DECIMAL(10,2)   NOT NULL,
            menuId  INTEGER         NOT NULL,
            FOREIGN KEY (menuId) REFERENCES Restaurant.Menus(id) ON DELETE CASCADE
        );
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Restaurant.Tickets (
            id              INTEGER         AUTO_INCREMENT PRIMARY KEY,
            restaurantId    INTEGER         NOT NULL,
            orderId         INTEGER         NOT NULL,
            status          VARCHAR(25)     NOT NULL,
            FOREIGN KEY (restaurantId) REFERENCES Restaurant.Restaurants(id) ON DELETE CASCADE
        );
    `);

    // Delivery 
    _ = check dbClient->execute(`CREATE DATABASE IF NOT EXISTS Delivery;`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Delivery.Couriers (
            id      INTEGER     AUTO_INCREMENT PRIMARY KEY,
            name    VARCHAR(50) NOT NULL
        )
    `);
    _ = check dbClient->execute(`
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
    `);

}
