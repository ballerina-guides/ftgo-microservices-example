CREATE DATABASE IF NOT EXISTS Restaurant;

CREATE TABLE IF NOT EXISTS Restaurant.Restaurants (
    id      INTEGER         AUTO_INCREMENT PRIMARY KEY,
    name    VARCHAR(255)    NOT NULL,
    address VARCHAR(255)    NOT NULL
);

CREATE TABLE IF NOT EXISTS Restaurant.Menus (
    id              INTEGER AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    restaurantId    INTEGER NOT NULL,
    FOREIGN KEY (restaurantId) REFERENCES Restaurant.Restaurants(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Restaurant.MenuItems (
    id      INTEGER         AUTO_INCREMENT PRIMARY KEY,
    name    VARCHAR(255)    NOT NULL,
    price   DECIMAL(10,2)   NOT NULL,
    menuId  INTEGER         NOT NULL,
    FOREIGN KEY (menuId) REFERENCES Restaurant.Menus(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Restaurant.Tickets (
    id      INTEGER         AUTO_INCREMENT PRIMARY KEY,
    restaurantId    INTEGER NOT NULL,
    orderId INTEGER         NOT NULL,
    status  VARCHAR(25)     NOT NULL,
    FOREIGN KEY (restaurantId) REFERENCES Restaurant.Restaurants(id) ON DELETE CASCADE
);
