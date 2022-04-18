import ballerina/test;
import ballerina/http;

type RestaurantCreatedRecord record {|
    *Restaurant;
    *http:Links;
|};

type RestaurantViewRecord record {|
    *Restaurant;
    *http:Links;
|};

type RestaurantRecord record {|
    string name?;
    string address?;
    record {|
        string name;
        record {|
            string name;
            decimal price;
        |}[] items;
    |}[] menus;
|};

type RestaurantUpdateRecord record {|
    string name;
    string address;
|};

http:Client restaurantClient = check new("http://localhost:8081/restaurant/");

@test:Config {
    groups: ["create-restaurant"]
}
function createRestaurantTest1() returns error? {
    http:Request createRestaurantRequest = new;
    RestaurantRecord createRestaurantPayload = {
        name: "Test Restaurant",
        address: "Test Address",
        menus: [
            {
                name: "Drinks",
                items: [
                    { name: "Water", price: 50.21 },
                    { name: "Coke", price: 100.71 }
                ]
            },
            {
                name: "Mains",
                items: [
                    { name: "Rice", price: 500.21 },
                    { name: "Noodles", price: 600.71 },
                    { name: "Pasta", price: 900.12 }
                ]
            }
        ]
    };
    createRestaurantRequest.setJsonPayload(createRestaurantPayload.toJson());
    http:Response response = check restaurantClient->post("", createRestaurantRequest);
    test:assertEquals(response.statusCode, 201);

    RestaurantCreatedRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    validateRestaurant(createRestaurantPayload, returnData);
    test:assertEquals(returnData.links.length(), 3);
}

@test:Config {
    groups: ["create-restaurant"]
}
function createRestaurantTest2() returns error? {
    http:Request createRestaurantRequest = new;
    RestaurantRecord createRestaurantPayload = {
        name: "Test Restaurant",
        address: "Test Address",
        menus: []
    };
    createRestaurantRequest.setJsonPayload(createRestaurantPayload.toJson());
    http:Response response = check restaurantClient->post("", createRestaurantRequest);
    test:assertEquals(response.statusCode, 201);

    RestaurantCreatedRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    validateRestaurant(createRestaurantPayload, returnData);
    test:assertEquals(returnData.links.length(), 3);
}

@test:Config {
    groups: ["create-restaurant"]
}
function createRestaurantTest3() returns error? {
    http:Request createRestaurantRequest = new;
    RestaurantRecord createRestaurantPayload = {
        name: "Test Restaurant",
        address: "Test Address",
        menus: [
            {
                name: "Drinks",
                items: [
                    { name: "Water", price: 50.21 },
                    { name: "Coke", price: 100.71 }
                ]
            },
            {
                name: "Mains",
                items: []
            }
        ]
    };
    createRestaurantRequest.setJsonPayload(createRestaurantPayload.toJson());
    http:Response response = check restaurantClient->post("", createRestaurantRequest);
    test:assertEquals(response.statusCode, 201);

    RestaurantCreatedRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    validateRestaurant(createRestaurantPayload, returnData);
    test:assertEquals(returnData.links.length(), 3);
}

@test:Config {
    groups: ["create-restaurant"]
}
function createRestaurantNegativeTest() returns error? {
    http:Request createRestaurantRequest = new;
    RestaurantRecord createRestaurantPayload = {
        name: "Test Restaurant",
        menus: [
            {
                name: "Drinks",
                items: [
                    { name: "Water", price: 50.21 },
                    { name: "Coke", price: 100.71 }
                ]
            },
            {
                name: "Mains",
                items: [
                    { name: "Rice", price: 500.21 },
                    { name: "Noodles", price: 600.71 },
                    { name: "Pasta", price: 900.12 }
                ]
            }
        ]
    };
    createRestaurantRequest.setJsonPayload(createRestaurantPayload.toJson());
    http:Response response = check restaurantClient->post("", createRestaurantRequest);
    test:assertEquals(response.statusCode, 400);
}

@test:Config {
    groups: ["get-restaurant"]
}
function getRestaurantTest() returns error? {
    http:Request createRestaurantRequest = new;
    RestaurantRecord createRestaurantPayload = {
        name: "Test Restaurant2",
        address: "Test Address2",
        menus: [
            {
                name: "Drinks2",
                items: [
                    { name: "Water2", price: 50.21 },
                    { name: "Coke2", price: 100.71 }
                ]
            },
            {
                name: "Mains2",
                items: [
                    { name: "Rice2", price: 500.21 },
                    { name: "Noodles2", price: 600.71 },
                    { name: "Pasta2", price: 900.12 }
                ]
            }
        ]
    };
    createRestaurantRequest.setJsonPayload(createRestaurantPayload.toJson());
    RestaurantCreatedRecord createdRestaurant = check restaurantClient->post("", createRestaurantRequest);

    http:Response response = check restaurantClient->get(createdRestaurant.id.toString());
    test:assertEquals(response.statusCode, 200);

    RestaurantViewRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    validateRestaurant(createRestaurantPayload, returnData);
    test:assertEquals(returnData.links.length(), 3);
}

@test:Config {
    groups: ["get-restaurant"]
}
function getRestaurantNegativeTest() returns error? {
    http:Request createRestaurantRequest = new;
    RestaurantRecord createRestaurantPayload = {
        name: "Test Restaurant2",
        address: "Test Address2",
        menus: [
            {
                name: "Drinks2",
                items: [
                    { name: "Water2", price: 50.21 },
                    { name: "Coke2", price: 100.71 }
                ]
            },
            {
                name: "Mains2",
                items: [
                    { name: "Rice2", price: 500.21 },
                    { name: "Noodles2", price: 600.71 },
                    { name: "Pasta2", price: 900.12 }
                ]
            }
        ]
    };
    createRestaurantRequest.setJsonPayload(createRestaurantPayload.toJson());
    RestaurantCreatedRecord createdRestaurant = check restaurantClient->post("", createRestaurantRequest);

    http:Response response = check restaurantClient->get((createdRestaurant.id + 1).toString());
    test:assertEquals(response.statusCode, 404);
}

@test:Config {
    groups: ["delete-restaurant"]
}
function deleteRestaurantTest() returns error? {
    http:Request createRestaurantRequest = new;
    RestaurantRecord createRestaurantPayload = {
        name: "Test Restaurant2",
        address: "Test Address2",
        menus: [
            {
                name: "Drinks2",
                items: [
                    { name: "Water2", price: 50.21 },
                    { name: "Coke2", price: 100.71 }
                ]
            },
            {
                name: "Mains2",
                items: [
                    { name: "Rice2", price: 500.21 },
                    { name: "Noodles2", price: 600.71 },
                    { name: "Pasta2", price: 900.12 }
                ]
            }
        ]
    };
    createRestaurantRequest.setJsonPayload(createRestaurantPayload.toJson());
    RestaurantCreatedRecord createdRestaurant = check restaurantClient->post("", createRestaurantRequest);

    http:Response response = check restaurantClient->get(createdRestaurant.id.toString());
    test:assertEquals(response.statusCode, 200);

    response = check restaurantClient->delete(createdRestaurant.id.toString());
    test:assertEquals(response.statusCode, 200);

    response = check restaurantClient->get(createdRestaurant.id.toString());
    test:assertEquals(response.statusCode, 404);
}

@test:Config {
    groups: ["delete-restaurant"]
}
function deleteRestaurantNegativeTest() returns error? {
    http:Request createRestaurantRequest = new;
    RestaurantRecord createRestaurantPayload = {
        name: "Test Restaurant2",
        address: "Test Address2",
        menus: [
            {
                name: "Drinks2",
                items: [
                    { name: "Water2", price: 50.21 },
                    { name: "Coke2", price: 100.71 }
                ]
            },
            {
                name: "Mains2",
                items: [
                    { name: "Rice2", price: 500.21 },
                    { name: "Noodles2", price: 600.71 },
                    { name: "Pasta2", price: 900.12 }
                ]
            }
        ]
    };
    createRestaurantRequest.setJsonPayload(createRestaurantPayload.toJson());
    RestaurantCreatedRecord createdRestaurant = check restaurantClient->post("", createRestaurantRequest);

    http:Response response = check restaurantClient->get(createdRestaurant.id.toString());
    test:assertEquals(response.statusCode, 200);

    response = check restaurantClient->delete((createdRestaurant.id + 1).toString());
    test:assertEquals(response.statusCode, 404);
}

@test:Config {
    groups: ["update-restaurant"]
}
function updateRestaurantTest() returns error? {
    http:Request createRestaurantRequest = new;
    RestaurantRecord createRestaurantPayload = {
        name: "Test Restaurant2",
        address: "Test Address2",
        menus: [
            {
                name: "Drinks2",
                items: [
                    { name: "Water2", price: 50.21 },
                    { name: "Coke2", price: 100.71 }
                ]
            },
            {
                name: "Mains2",
                items: [
                    { name: "Rice2", price: 500.21 },
                    { name: "Noodles2", price: 600.71 },
                    { name: "Pasta2", price: 900.12 }
                ]
            }
        ]
    };

    createRestaurantRequest.setJsonPayload(createRestaurantPayload.toJson());
    RestaurantCreatedRecord createdRestaurant = check restaurantClient->post("", createRestaurantRequest);

    http:Request updateRestaurantRequest = new;
    RestaurantUpdateRecord updateRestaurantPayload = {
        name: "Test Restaurant3",
        address: "Test Address3"
    };
    updateRestaurantRequest.setJsonPayload(updateRestaurantPayload);
    http:Response response = check restaurantClient->put(createdRestaurant.id.toString(), updateRestaurantRequest);
    test:assertEquals(response.statusCode, 200);

    response = check restaurantClient->get(createdRestaurant.id.toString());
    test:assertEquals(response.statusCode, 200);

    RestaurantViewRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    createRestaurantPayload.name = updateRestaurantPayload.name;
    createRestaurantPayload.address = updateRestaurantPayload.address;
    validateRestaurant(createRestaurantPayload, returnData);
    test:assertEquals(returnData.links.length(), 3);
}

@test:Config {
    groups: ["update-restaurant"]
}
function updateRestaurantNegativeTest() returns error? {
    http:Request createRestaurantRequest = new;
    RestaurantRecord createRestaurantPayload = {
        name: "Test Restaurant2",
        address: "Test Address2",
        menus: [
            {
                name: "Drinks2",
                items: [
                    { name: "Water2", price: 50.21 },
                    { name: "Coke2", price: 100.71 }
                ]
            },
            {
                name: "Mains2",
                items: [
                    { name: "Rice2", price: 500.21 },
                    { name: "Noodles2", price: 600.71 },
                    { name: "Pasta2", price: 900.12 }
                ]
            }
        ]
    };

    createRestaurantRequest.setJsonPayload(createRestaurantPayload.toJson());
    RestaurantCreatedRecord createdRestaurant = check restaurantClient->post("", createRestaurantRequest);

    http:Request updateRestaurantRequest = new;
    RestaurantUpdateRecord updateRestaurantPayload = {
        name: "Test Restaurant3",
        address: "Test Address3"
    };
    updateRestaurantRequest.setJsonPayload(updateRestaurantPayload);
    http:Response response = check restaurantClient->put((createdRestaurant.id + 1).toString(), updateRestaurantRequest);
    test:assertEquals(response.statusCode, 404);
}

isolated function validateRestaurant(RestaurantRecord inputRestaurant, RestaurantViewRecord|RestaurantCreatedRecord outputRestaurant) {
    test:assertEquals(outputRestaurant.name, inputRestaurant.name);
    test:assertEquals(outputRestaurant.address, inputRestaurant.address);
    test:assertEquals(inputRestaurant.menus.length(), outputRestaurant.menus.length());

    foreach int i in 0 ..<inputRestaurant.menus.length() {
        test:assertEquals(inputRestaurant.menus[i].name, outputRestaurant.menus[i].name);
        test:assertEquals(inputRestaurant.menus[i].items.length(), outputRestaurant.menus[i].items.length());

        foreach int j in 0 ..<inputRestaurant.menus[i].items.length() {
            test:assertEquals(inputRestaurant.menus[i].items[j].name, outputRestaurant.menus[i].items[j].name);
            test:assertEquals(inputRestaurant.menus[i].items[j].price, outputRestaurant.menus[i].items[j].price);
        }
    }
}
