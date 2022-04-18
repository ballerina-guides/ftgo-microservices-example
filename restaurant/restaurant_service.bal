import ballerina/http;
import ballerina/sql;
import ballerina/log;

# Request body to be used when creating a restaurant
type CreateRestaurantRequest record {|
    # The name of the restaurant
    string name;
    # The address of the restauarant
    string address;
    # The menus offered by the restaurant
    CreateRestaurantRequestMenu[] menus;
|};

# Representation for a menu to be used when creating a restaurant
type CreateRestaurantRequestMenu record {|
    # The name of the menue
    string name;
    # The items contained within the menu
    CreateMenuRequestMenuItem[] items;
|};

# Representation for a menu item to be used when creating a menu
type CreateMenuRequestMenuItem record {|
    # The name of the menu item
    string name;
    # The price of the menu item
    decimal price;
|};

# Request body to be used when creating a menu
type CreateMenuRequest record {|
    # The name of the menu
    string name;
    # The items contained within the menu
    CreateMenuRequestMenuItem[] menuItems;
|};

# Request body to be used when creating a menu item
type CreateMenuItemRequest record {|
    # The name of the menu item
    string name;
    # The price of the menu item
    decimal price;
|};

# The request body to be used when updating the details of a restaurant
type UpdateRestaurantRequest record {|
    # The updated name of the restaurant
    string name;
    # The updated address of the restaurant
    string address;
|};

# The request body to be used when updating the details of a menu
type UpdateMenuRequest record {|
    # The updated name of the menu
    string name;
|};

# The request body to be used when updating the details of a menu item
type UpdateMenuItemRequest record {|
    # The updated name of the menu item
    string name;
    # The price of the menu item
    decimal price;
|};

# The request body to be used when creating a ticket
type CreateTicketRequest record {|
    # The ID of the order associated with the ticket
    int orderId;
|};

# Response for a successful restaurant creation
type RestaurantCreated record {|
    *http:Created;
    # Details of the created restaurant along with the HTTP links to manage it
    record {|
        *Restaurant;
        *http:Links;
    |} body;
|};

# Response for a successful menu creation
type MenuCreated record {|
    *http:Created;
    # Details of the created menu along with the HTTP links to manage it
    record {|
        *Menu;
        *http:Links;
    |} body;
|};

# Response for a successful menu item creation
type MenuItemCreated record {|
    *http:Created;
    # Details of the created menu item along with the HTTP links to manage it
    record {|
        *MenuItem;
        *http:Links;
    |} body;
|};

# Response for a successful ticket creation
type TicketCreated record {|
    *http:Created;
    # Details of the ticket along with the HTTP links to manage it
    record {|
        *Ticket;
        *http:Links;
    |} body;
|};

# Error response for when the requested restaurant cannot be found
type RestaurantNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Restaurant cannot be found." 
    };
|};

# Error response for when the requested menu cannot be found
type MenuNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Menu cannot be found." 
    };
|};

# Error response for when the requested menu item cannot be found
type MenuItemNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Menu cannot be found." 
    };
|};

# Error response for when the requested ticket cannot be found
type TicketNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Menu cannot be found." 
    };
|};


# Response for a successful restaurant retrieval
type RestaurantView record {|
    *http:Ok;
    # Details of the retrieved restaurant along with the HTTP links to manage it
    record {|
        *Restaurant;
        *http:Links;
    |} body;
|};

# Response for a successful menu retrieval
type MenuView record {|
    *http:Ok;
    # Details of the retrieved menu along with the HTTP links to manage it
    record {|
        *Menu;
        *http:Links;
    |} body;
|};

# Response for a successful menu item retrieval
type MenuItemView record {|
    *http:Ok;
    # Details of the retrieved menu item along with the HTTP links to manage it
    record {|
        *MenuItem;
        *http:Links;
    |} body;
|};

# Response for a successful ticket retrieval
type TicketView record {|
    *http:Ok;
    # Details of the retrieved menu item along with the HTTP links to manage it
    record {|
        *Ticket;
        *http:Links;
    |} body;
|};


# Response for a successful restaurant deletion
type RestaurantDeleted record {|
    *http:Ok;
    # Details of the deleted restaurant
    Restaurant body;
|};

# Response for a successful menu deletion
type MenuDeleted record {|
    *http:Ok;
    # Details of the deleted menu
    Menu body;
|};

# Response for a successful menu item deletion
type MenuItemDeleted record {|
    *http:Ok;
    # Details of the deleted menu item
    MenuItem body;
|};

# Response for a successful restaurant update
type RestaurantUpdated record {|
    *http:Ok;
    # Details of the updated restaurant along with the HTTP links to manage it
    record {|
        *Restaurant;
        *http:Links;
    |} body;
|};

# Response for a successful menu update
type MenuUpdated record {|
    *http:Ok;
    # Details of the updated menu along with the HTTP links to manage itz
    record {|
        *Menu;
        *http:Links;
    |} body;
|};

# Response for a successful menu item update
type MenuItemUpdated record {|
    *http:Ok;
    # Details of the updated menu itemn along with the HTTP links to manage it
    record {|
        *MenuItem;
        *http:Links;
    |} body;
|};

# Response for a successful ticket update
type TicketUpdated record {|
    *http:Ok;
    # Details of the updated menu itemn along with the HTTP links to manage it
    record {|
        *Ticket;
        *http:Links;
    |} body;
|};

# Represents an unexpected error
type InternalError record {|
   *http:InternalServerError;
    # Error payload
    record {| 
        string message;
    |} body;
|}; 


# Description
service on new http:Listener(8081) {

    # Resource function to create a new restaurant
    #
    # + request - Details of the restaurant to be created. This can also contain information regarding the menus under the restaurant
    # + return - `RestaurantCreated` if the restaurant was successfully created.
    #            `RestaurantInternalError` if an unexpected error occurs
    isolated resource function post restaurant(@http:Payload CreateRestaurantRequest request) returns RestaurantCreated|InternalError {
        do {
            transaction {
                Restaurant generatedRestaurant = check createRestaurant(request.name, request.address);

                foreach CreateRestaurantRequestMenu menu in request.menus {
                    Menu generatedMenu = check createMenu(menu.name, generatedRestaurant.id);

                    foreach CreateMenuRequestMenuItem menuItem in menu.items {
                        MenuItem generatedMenuItem = check createMenuItem(menuItem.name, menuItem.price, generatedMenu.id);
                        generatedMenu.items.push(generatedMenuItem);
                    }

                    generatedRestaurant.menus.push(generatedMenu);
                }

                check commit;

                return <RestaurantCreated>{ 
                    headers: {
                        location: "/restaurant/" + generatedRestaurant.id.toString()
                    },
                    body: {
                        ...generatedRestaurant,
                        links: getRestaurantLinks(generatedRestaurant.id)
                    }
                };
            }
        } on fail error e {
            return <InternalError>{ body: { message: e.message() }};
        }
    }

    # Resource function to create a new menu under a restaurant
    #
    # + restaurantId - The ID of the restaurant under which the menu should be added  
    # + request - Details of the menu to be created. This can also contain information regarding the menu items under the menu
    # + return - `MenuCreated` if the menu was sucessfully created.
    #            `RestaurantInternalError` if an unexpected error occurs
    isolated resource function post restaurant/[int restaurantId]/menu(@http:Payload CreateMenuRequest request) returns MenuCreated|InternalError {
        do {
            transaction {
                Menu generatedMenu = check createMenu(request.name, restaurantId);

                foreach CreateMenuRequestMenuItem menuItem in request.menuItems {
                    MenuItem generatedMenuItem = check createMenuItem(menuItem.name, menuItem.price, generatedMenu.id);
                    generatedMenu.items.push(generatedMenuItem);
                }

                check commit;

                return <MenuCreated>{ 
                    headers: {
                        location: "/menu/" + generatedMenu.id.toString()
                    },
                    body: {
                        ...generatedMenu,
                        links: getMenuLinks(generatedMenu.id, restaurantId)
                    }
                };
            }
        } on fail error e {
            return <InternalError>{ body: { message: e.message() }};
        }
    }

    # Resource function to create a new menu item under a menu
    #
    # + restaurantId - The ID of the restaurnt under which the menu item should be created  
    # + menuId - The ID of the menu under which the menu item should be created  
    # + request - Details of the menu item to be created
    # + return - `MenuItemCreated` if the menu item was sucessfully created.
    #            `RestaurantInternalError` if an unexpected error occurs
    isolated resource function post restaurant/[int restaurantId]/menu/[int menuId]/item(@http:Payload CreateMenuItemRequest request) returns MenuItemCreated|InternalError {
        do {
            MenuItem generatedMenuItem = check createMenuItem(request.name, request.price, menuId);
            return <MenuItemCreated>{ 
                headers: {
                    location: "/restaurant/" + restaurantId.toString() + "/menu/" + menuId.toString() + "/menuItem/" + generatedMenuItem.id.toString()
                },
                body: {
                    ...generatedMenuItem,
                    links: getMenuItemLinks(generatedMenuItem.id, menuId, restaurantId)
                }
            };
        } on fail error e {
            return <InternalError>{ body: { message: e.message() }};
        }
    }

    # Resource function to fetch the details of a restaurant
    #
    # + restaurantId - The ID of the requested restaurant
    # + return - `RestaurantView` if the details are successfully fetched.
    #            `RestaurantNotFound` if a restaurant with the provided ID was not found.
    #            `RestaurantInternalError` if an unexpected error occurs
    isolated resource function get restaurant/[int restaurantId]() returns RestaurantView|RestaurantNotFound|InternalError {
        do {
            Restaurant restaurant = check getRestaurant(restaurantId);
            return <RestaurantView>{ 
                body: {
                    ...restaurant,
                    links: getRestaurantLinks(restaurant.id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <RestaurantNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        } 
    }

    # Resource function to fetch the details of a menu
    #
    # + restaurantId - The ID of the restaurant to which the menu belongs
    # + menuId - The ID of the requested menu
    # + return - `MenuView` if the details are successfully fetched.
    #            `MenuNotFound` if a menu with the provided ID was not found.
    #            `RestaurantInternalError` if an unexpected error occurs
    isolated resource function get restaurant/[int restaurantId]/menu/[int menuId]() returns MenuView|MenuNotFound|InternalError {
        do {
            Menu menu = check getMenu(menuId);
            return <MenuView>{ 
                body: {
                    ...menu,
                    links: getMenuLinks(menu.id, restaurantId)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        } 
    }

    # Resource function to fetch the details of a menu
    #
    # + restaurantId - The ID of the restaurant to which the menu item belongs
    # + menuId - The ID of the menu to which the menu item belongs
    # + menuItemId - The ID of the requested menu item
    # + return - `MenuItemView` if the details are successfully fetched.
    #            `MenuItemNotFound` if a menu item with the provided ID was not found.
    #            `RestaurantInternalError` if an unexpected error occurs
    isolated resource function get restaurant/[int restaurantId]/menu/[int menuId]/item/[int menuItemId]() returns MenuItemView|MenuItemNotFound|InternalError {
        do {
            MenuItem menuItem = check getMenuItem(menuItemId);
            return <MenuItemView>{ 
                body: {
                    ...menuItem,
                    links: getMenuItemLinks(menuItem.id, menuId, restaurantId)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuItemNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        } 
    }

    # Resource function to fetch the details of a menu
    #
    # + menuItemId - The ID of the requested menu item
    # + return - `MenuItemView` if the details are successfully fetched.
    #            `MenuItemNotFound` if a menu item with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function get menuItem/[int menuItemId]() returns MenuItemView|MenuItemNotFound|InternalError {
        do {
            MenuItem menuItem = check getMenuItem(menuItemId);
            Menu parentMenu = check getParentMenu(menuItemId);
            Restaurant parentRestaurant = check getParentRestaurant(parentMenu.id);
            return <MenuItemView>{ 
                body: {
                    ...menuItem,
                    links: getMenuItemLinks(menuItem.id, parentMenu.id, parentRestaurant.id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuItemNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        } 
    }

    # Resource function to delete a consumer. This would also delete all menus and menu items under the restaurant
    #
    # + restaurantId - The ID of the restaurant to be deleted
    # + return - `RestaurantDeleted` if the restaurant was successfully deleted.
    #            `RestaurantNotFound` if a restaurant with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function delete restaurant/[int restaurantId]() returns RestaurantDeleted|RestaurantNotFound|InternalError {
        do {
            Restaurant restaurant = check deleteRestaurant(restaurantId);
            return <RestaurantDeleted>{ body: restaurant};
        } on fail error e {
            if e is sql:NoRowsError {
                return <RestaurantNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }   
    }

    # Resource function to delete a menu. This would also delete all menu items under the menu
    #
    # + restaurantId - The ID of the restaurant to which the menu belongs
    # + menuId - The ID of the menu to be deleted
    # + return - `MenuDeleted` if the menu was successfully deleted.
    #            `MenuNotFound` if a menu with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function delete restaurant/[int restaurantId]/menu/[int menuId]() returns MenuDeleted|MenuNotFound|InternalError {
        do {
            Menu menu = check deleteMenu(menuId);
            return <MenuDeleted>{ body: menu};
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }
    }

    # Resource function to delete a menu item
    #
    # + restaurantId - The ID of the restaurant to which the menu item belongs
    # + menuId - The ID of the menu to which the menu item belongs
    # + menuItemId - The ID of the menu item to be deleted
    # + return - `MenuItemDeleted` if the menu item was successfully deleted.
    #            `MenuItemNotFound` if a menu item with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function delete restaurant/[int restaurantId]/menu/[int menuId]/menuItem/[int menuItemId]() returns MenuItemDeleted|MenuItemNotFound|InternalError {
         do {
            MenuItem menuitem = check deleteMenuItem(menuItemId);
            return <MenuItemDeleted>{ body: menuitem};
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuItemNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }
    }

    # Resource function to update the details of a restaurant
    #
    # + restaurantId - The ID of the restaurant to be updated  
    # + request - Details of the restaurant to be updated
    # + return - `RestaurantUpdated` if the restaurant was successfully updated.
    #            `RestaurantNotFound` if a restaurant with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function put restaurant/[int restaurantId](@http:Payload UpdateRestaurantRequest request) returns RestaurantUpdated|RestaurantNotFound|InternalError {
        do {
            Restaurant updatedRestaurant = check updateRestaurant(restaurantId, request.name, request.address);
            return <RestaurantUpdated>{ 
                body: { 
                    ...updatedRestaurant,
                    links: getRestaurantLinks(updatedRestaurant.id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <RestaurantNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }       
    }

    # Resource function to update the details of a menu
    #
    # + restaurantId - The ID of the restaurant to which the menu belongs
    # + menuId - The ID of the menu to be updated
    # + request - Details of the menu to be updated
    # + return - `MenuUpdated` if the menu was successfully updated.
    #            `MenuNotFound` if a menu with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function put restaurant/[int restaurantId]/menu/[int menuId](@http:Payload UpdateMenuRequest request) returns MenuUpdated|MenuNotFound|InternalError {
        do {
            Menu updatedMenu = check updateMenu(menuId, request.name);
            return <MenuUpdated>{ 
                body: {
                    ...updatedMenu,
                    links: getMenuLinks(updatedMenu.id, restaurantId)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <RestaurantNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }  
    }

    # Resource function to update the details of a menu iten
    #
    # + restaurantId - The ID of the restaurant to which the menu  itme belongs
    # + menuId - The ID of the menu to which the menu item belongs
    # + menuItemId - The ID of the menu item to be deleted  
    # + request - Details of the menu item to be updated
    # + return - `MenuItemUpdated` if the menu was successfully updated.
    #            `MenuItemNotFound` if a menu with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function put restaurant/[int restaurantId]/menu/[int menuId]/item/[int menuItemId](@http:Payload UpdateMenuItemRequest request) returns MenuItemUpdated|MenuItemNotFound|InternalError {
        do {
            MenuItem updatedMenuItem = check updateMenuItem(menuItemId, request.name, request.price);
            return <MenuItemUpdated>{ 
                body: {
                    ...updatedMenuItem,
                    links: getMenuItemLinks(updatedMenuItem.id, menuId, restaurantId)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuItemNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }  
    }

    # Create a new ticket
    #
    # + restaurantId - The ID of the restaurant under which the ticket should be created  
    # + request - The details related to the ticker
    # + return - `TicketCreated` if the ticket was successfully created.
    #            `InternalError` if an unexpected error occurs
    isolated resource function post restaurant/[int restaurantId]/ticket(@http:Payload CreateTicketRequest request) returns TicketCreated|InternalError {
        log:printInfo("Ticket create request", restaurantId = restaurantId, request = request);
        do {
            Ticket generatedTicket = check createTicket(restaurantId, request.orderId);
            return <TicketCreated>{ 
                body: {
                    ...generatedTicket,
                    links: getTicketLinks(generatedTicket.id)
                }
            };
        } on fail error e {
            log:printError("Error creating ticket", 'error = e);
            return <InternalError>{ body: { message: e.message() }};
        }  
    }

    # Retrieves the details for a ticket
    #
    # + restaurantId - The ID of the restaurant to which the ticket belongs to  
    # + id - The ID of the ticket
    # + return - `TicketView` if the ticket was successfully retrieved.
    #            `TicketNotFound` if a ticket with the provided ID cannot be found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function get restaurant/[int restaurantId]/ticket/[int id]() returns TicketView|TicketNotFound|InternalError {
        do {
            Ticket ticket = check getTicket(id);
            return <TicketView>{ 
                body: {
                    ...ticket,
                    links: getTicketLinks(id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <TicketNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }  
    }

    # Marks the status of a ticket as `PREPARING`
    #
    # + restaurantId - The ID of the restaurant to which the ticket belongs to  
    # + id - The ID of the ticket
    # + return - `TicketUpdated` if the ticket was successfully updated.
    #            `TicketNotFound` if a ticket with the provided ID cannot be found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function put restaurant/[int restaurantId]/ticket/[int id]/mark/preparing() returns TicketUpdated|TicketNotFound|InternalError {
        log:printInfo("Update ticket status to preparing request", restaurantId = restaurantId, ticketId = id);
        do {
            Ticket updatedTicket = check updateTicket(id, PREPARING);
            return <TicketUpdated>{
                body: {
                    ...updatedTicket,
                    links: getTicketLinks(id)
                }
            };
        } on fail error e {
            log:printError("Error updating ticket status", 'error = e, stackTrace = e.stackTrace());
            if e is sql:NoRowsError {
                return <TicketNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        } 
    }

    # Marks the status of a ticket as `READY`
    #
    # + restaurantId - The ID of the restaurant to which the ticket belongs to  
    # + id - The ID of the ticket
    # + return - `TicketUpdated` if the ticket was successfully updated.
    #            `TicketNotFound` if a ticket with the provided ID cannot be found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function put restaurant/[int restaurantId]/ticket/[int id]/mark/ready() returns TicketUpdated|TicketNotFound|InternalError {
        do {
            Ticket updatedTicket = check updateTicket(id, READY_FOR_PICKUP);
            return <TicketUpdated>{
                body: {
                    ...updatedTicket,
                    links: getTicketLinks(id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <TicketNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        } 
    }

    # Marks the status of a ticket as `PICKED UP`
    #
    # + restaurantId - The ID of the restaurant to which the ticket belongs to  
    # + id - The ID of the ticket
    # + return - `TicketUpdated` if the ticket was successfully updated.
    #            `TicketNotFound` if a ticket with the provided ID cannot be found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function put restaurant/[int restaurantId]/ticket/[int id]/mark/pickedUp() returns TicketUpdated|TicketNotFound|InternalError {
        do {
            Ticket updatedTicket = check updateTicket(id, PICKED_UP);
            return <TicketUpdated>{
                body: {
                    ...updatedTicket,
                    links: getTicketLinks(id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <TicketNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        } 
    }

}

# Returns the HTTP links related to a given restaurant
#
# + restaurantId - The ID of the restaurant
# + return - An array of links
isolated function getRestaurantLinks(int restaurantId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/restaurant/" + restaurantId.toString(),
            methods: [http:GET]
        },
        {
            rel: "update",
            href: "/restaurant/" + restaurantId.toString(),
            methods: [http:PUT]
        },
        {
            rel: "delete",
            href: "/restaurant/" + restaurantId.toString(),
            methods: [http:DELETE]
        }
    ];
}

# Returns the HTTP links related to a given menu
#
# + menuId - THe ID of the menu  
# + parentRestaurantId - The ID of the restaurant to which the menu belongs
# + return - An array of links
isolated function getMenuLinks(int menuId, int parentRestaurantId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + menuId.toString(),
            methods: [http:GET]
        },
        {
            rel: "update",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + menuId.toString(),
            methods: [http:PUT]
        },
        {
            rel: "delete",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + menuId.toString(),
            methods: [http:DELETE]
        },
        {
            rel: "parent restaurant",
            href: "/restaurant/" + parentRestaurantId.toString(),
            methods: [http:GET]
        }
    ];
}

# Returns the HTTP links related to a given menu item
#
# + menuItemId - The ID of the menu item  
# + parentMenuId - The ID of the menu to which the menu item belongs  
# + parentRestaurantId - The ID of the restaurant to which the menu item belongs
# + return - An array of links
isolated function getMenuItemLinks(int menuItemId, int parentMenuId, int parentRestaurantId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + parentMenuId.toString() + "/item/" + menuItemId.toString(),
            methods: [http:GET]
        },
        {
            rel: "update",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + parentMenuId.toString() + "/item/" + menuItemId.toString(),
            methods: [http:PUT]
        },
        {
            rel: "delete",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + parentMenuId.toString() + "/item/" + menuItemId.toString(),
            methods: [http:DELETE]
        },
        {
            rel: "parent menu",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + parentMenuId.toString(),
            methods: [http:GET]
        },
        {
            rel: "parent restaurant",
            href: "/restaurant/" + parentRestaurantId.toString(),
            methods: [http:GET]
        }
    ];
}

# Returns the HTTP links related to a given ticket
#
# + ticketId - The ID of the ticket
# + return - An array of links
isolated function getTicketLinks(int ticketId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/ticket/" + ticketId.toString(),
            methods: [http:GET]
        }
    ];
}