import ballerinax/mysql;
import ballerina/sql;
import ballerina/http;

# Represents a restaurant
type Restaurant record {|
    # The ID of the restaurant
    int id;
    # The name of the restaurant
    string name;
    # The address of the restaurant
    string address;
    # The menus offered by the restaurant
    Menu[] menus;
|};

# Represents a menu
type Menu record {|
    # The ID of the menu
    int id;
    # The name of the menu
    string name;
    # The items included in the menu
    MenuItem[] items;
|};

# Represents a menu item
type MenuItem record {|
    # The ID of the menu item
    int id;
    # The name of the menu item
    string name;
    # The price of the menu item
    decimal price;
|};

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;
configurable string ORDER_ENDPOINT = ?;

final mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT, database="Restaurant");
final http:Client orderEndpoint = check new(ORDER_ENDPOINT);

# Creates a new restaurant. This method does not manage the creation of menus under the restaurant.
#
# + name - The name of the restaurant  
# + address - The address of the restaurant
# + return - The details of the restaurant if the creation was successful. An error if unsuccessful
isolated function createRestaurant(string name, string address) returns Restaurant|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO Restaurants (name, address) VALUES (${name}, ${address})`);
    int|string? generatedRestaurantId = result.lastInsertId;
    if generatedRestaurantId is string? {
        return error("Unable to retrieve generated ID of restaurant.");
    }

    return <Restaurant>{
        id: generatedRestaurantId,
        name: name,
        address: address,
        menus: []
    };
}

# Creates a new menu under a particular restaurant. This method does not manage the creation of menu items under the menu.
#
# + name - The name of the menu  
# + restaurantId - The ID of the restaurant under which the menu should be created
# + return - The details of the menu if the creation was successful. An error if unsuccessful
isolated function createMenu(string name, int restaurantId) returns Menu|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO Menus (name, restaurantId) VALUES (${name}, ${restaurantId})`);
    int|string? generatedMenuId = result.lastInsertId;
    if generatedMenuId is string? {
        return error("Unable to retrieve ID of menu.");
    }

    return <Menu>{
        id: generatedMenuId,
        name: name,
        items: []
    };
}

# Creates a new menu item under a particular menu.
#
# + name - The name of the menu item  
# + price - The price of the menu item  
# + menuId - The ID of the menu under which the menu item should be created
# + return - The details of the menu item if the creation was successful. An error if unsuccessful
isolated function createMenuItem(string name, decimal price, int menuId) returns MenuItem|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO MenuItems (name, price, menuId) VALUES (${name}, ${price}, ${menuId})`);
    int|string? generatedMenuItemId = result.lastInsertId;
    if generatedMenuItemId is string? {
        return error("Unable to retrieve ID of menu item.");
    }

    return <MenuItem>{
        id: generatedMenuItemId,
        name: name,
        price: price
    };
}

# Retrieves the details of a restaurant
#
# + restaurantId - The ID of the requested restaurant
# + return - The details of the restaurant if the retrieval was successful. An error if unsuccessful
isolated function getRestaurant(int restaurantId) returns Restaurant|error {
    Restaurant restaurant = check dbClient->queryRow(`SELECT id, name, address FROM Restaurants WHERE id = ${restaurantId}`);
    restaurant.menus = check getMenus(restaurantId);
    return restaurant;
}

# Retrieves the details of a menu
#
# + menuId - The ID of the requested menu
# + return - The details of the menu if the retrieval was successful. An error if unsuccessful
isolated function getMenu(int menuId) returns Menu|error {
    Menu menu = check dbClient->queryRow(`SELECT id, name FROM Menus WHERE id = ${menuId}`);
    menu.items = check getMenuItems(menuId);
    return menu;
}

# Retrieves the details of a menu item
#
# + menuItemId - The ID of the requested menu item
# + return - The details of the menu item if the retrieval was successful. An error if unsuccessful
isolated function getMenuItem(int menuItemId) returns MenuItem|error {
    MenuItem menuItem = check dbClient->queryRow(`SELECT id, name, price FROM MenuItems WHERE id = ${menuItemId}`);
    return menuItem;
}

# Retrieves the details of all the menus listed under a restaurant as well as the menu items included within them
#
# + restaurantId - The ID of the restaurant for which the menus are required
# + return - An array containing the details of all the menus under the provided restaurant
isolated function getMenus(int restaurantId) returns Menu[]|error {
    Menu[] menus = [];
    stream<Menu, error?> resultStream = dbClient->query(`SELECT id, name FROM Menus WHERE restaurantId = ${restaurantId}`);
    check from Menu menu in resultStream
        do {
            menu.items = check getMenuItems(menu.id);
            menus.push(menu);
        };
    return menus;
}

# Retrieves the details of all the menu items listed under a menu
#
# + menuId - The ID of the menu for which the menu items are required
# + return - An array containing the details of all the menu items under the provided menu
isolated function getMenuItems(int? menuId) returns MenuItem[]|error {
    MenuItem[] menuItems = [];
    stream<MenuItem, error?> resultStream = dbClient->query(`SELECT id, name, price FROM MenuItems WHERE menuId = ${menuId}`);
    check from MenuItem menuItem in resultStream
        do {
            menuItems.push(menuItem);
        };
    return menuItems;
}

# Deletes a restauarant
#
# + restaurantId - The ID of the restaurant to be deleted
# + return - The details of the deleted restaurant if the deletion was successful. An error if unsuccessful 
isolated function deleteRestaurant(int restaurantId) returns Restaurant|error {
    Restaurant restaurant = check getRestaurant(restaurantId);
    _ = check dbClient->execute(`DELETE FROM Restaurants WHERE id = ${restaurantId}`);
    return restaurant;
}

# Deletes a menu
#
# + menuId - The ID of the menu to be deleted
# + return - The details of the deleted menu if the deletion was successful. An error if unsuccessful 
isolated function deleteMenu(int menuId) returns Menu|error {
    Menu menu = check getMenu(menuId);
    _ = check dbClient->execute(`DELETE FROM Menus WHERE id = ${menuId}`);
    return menu;
}

# Deletes a menu item
#
# + menuItemId - The ID of the menu item to be deleted
# + return - The details of the deleted menu item if the deletion was successful. An error if unsuccessful 
isolated function deleteMenuItem(int menuItemId) returns MenuItem|error {
    MenuItem menuItem = check getMenuItem(menuItemId);
    _ = check dbClient->execute(`DELETE FROM MenuItems WHERE id = ${menuItem}`);
    return menuItem;
}

# Updates the details of a restaurant
#
# + restaurantId - The ID of the restaurant to be updated  
# + name - The updated name of the restaurant  
# + address - The updated address of the restaurant  
# + return - The updated details of the restaurant if the update was successful. An error if unsuccessful
isolated function updateRestaurant(int restaurantId, string name, string address) returns Restaurant|error {
    _ = check dbClient->execute(`UPDATE Restaurants SET name=${name}, address=${address} WHERE id = ${restaurantId}`);
    return getRestaurant(restaurantId);
}

# Updates the details of a menu
#
# + menuId - The ID of the menu to be updated  
# + name - The updated name of the menu
# + return - The updated details of the menu if the update was successful. An error if unsuccessful
isolated function updateMenu(int menuId, string name) returns Menu|error {
    _ = check dbClient->execute(`UPDATE Menus SET name=${name} WHERE id = ${menuId}`);
    return getMenu(menuId);
}

# Updates the details of a menu item
#
# + menuItemId - The ID of the menu item to be updated  
# + name - The updated name of the menu item
# + price - The updated price of the menu item
# + return - The updated details of the menu item if the update was successful. An error if unsuccessful
isolated function updateMenuItem(int menuItemId, string name, decimal price) returns MenuItem|error {
    _ = check dbClient->execute(`UPDATE MenuItems SET name=${name}, price=${price} WHERE id = ${menuItemId}`);
    return getMenuItem(menuItemId);
}

# Obtains the parent menu of a provided menu item
#
# + menuItemId - The ID of the menu item for which the parent menu should be retrieved
# + return - The updated details of the parent menu if the retrieval successful. An error if unsuccessful
public isolated function getParentMenu(int menuItemId) returns Menu|error {
    int menuId = check dbClient->queryRow(`SELECT menuId FROM MenuItems WHERE id=${menuItemId}`);
    return getMenu(menuId);
}

# Obtains the parent restaurant of a provided menu
#
# + menuId - The ID of the menu for which the parent restaurant should be retrieved
# + return - The updated details of the parent restaurant if the retrieval successful. An error if unsuccessful
public isolated function getParentRestaurant(int menuId) returns Restaurant|error {
    int restaurantId = check dbClient->queryRow(`SELECT restaurantId FROM Menus WHERE id=${menuId}`);
    return getRestaurant(restaurantId);
}
