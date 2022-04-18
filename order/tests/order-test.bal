import ballerina/http;
import ballerina/test;

http:Client orderClient = check new("http://localhost:8082/order/");

@test:Config {
    groups: ["create-order"]
}
function createOrderTest1() returns error? {
    http:Request createOrderRequest = new;
    CreateOrderRequest createOrderPayload = {
        consumerId: 1,
        restaurantId: 1,
        deliveryAddress: "Test delivery addrress",
        deliveryTime: {
            year: 2022,
            month: 3,
            day: 1,
            hour: 17,
            minute: 30
        },
        orderItems: [
            { menuItemId: 1, quantity: 3 },
            { menuItemId: 2, quantity: 2 }
        ]
    };
    createOrderRequest.setJsonPayload(createOrderPayload.toJson());
    http:Response response = check orderClient->post("", createOrderRequest);
    test:assertEquals(response.statusCode, 201);

    record {|
        *Order;
        *http:Links;
    |} returnData = check (check response.getJsonPayload()).cloneWithType();
    validateOrder(createOrderPayload, returnData);
    test:assertEquals(returnData.links.length(), 3);
}

@test:Config {
    groups: ["create-order"]
}
function createOrderTest2() returns error? {
    http:Request createOrderRequest = new;
    CreateOrderRequest createOrderPayload = {
        consumerId: 1,
        restaurantId: 1,
        deliveryAddress: "Test delivery addrress",
        deliveryTime: {
            year: 2022,
            month: 3,
            day: 1,
            hour: 17,
            minute: 30
        },
        orderItems: []
    };
    createOrderRequest.setJsonPayload(createOrderPayload.toJson());
    http:Response response = check orderClient->post("", createOrderRequest);
    test:assertEquals(response.statusCode, 201);

    record {|
        *Order;
        *http:Links;
    |} returnData = check (check response.getJsonPayload()).cloneWithType();
    validateOrder(createOrderPayload, returnData);
    test:assertEquals(returnData.links.length(), 3);
}

@test:Config {
    groups: ["create-order"]
}
function createOrderTestNegative() returns error? {
    http:Request createOrderRequest = new;
    CreateOrderRequest createOrderPayload = {
        consumerId: 2,
        restaurantId: 1,
        deliveryAddress: "Test delivery addrress",
        deliveryTime: {
            year: 2022,
            month: 3,
            day: 1,
            hour: 17,
            minute: 30
        },
        orderItems: [
            { menuItemId: 1, quantity: 3 },
            { menuItemId: 2, quantity: 2 }
        ]
    };
    createOrderRequest.setJsonPayload(createOrderPayload.toJson());
    http:Response response = check orderClient->post("", createOrderRequest);
    test:assertEquals(response.statusCode, 500);
}

@test:Config {
    groups: ["get-order"]
}
function getOrderTest() returns error? {
    http:Request createOrderRequest = new;
    CreateOrderRequest createOrderPayload = {
        consumerId: 1,
        restaurantId: 1,
        deliveryAddress: "Test delivery addrress",
        deliveryTime: {
            year: 2022,
            month: 3,
            day: 1,
            hour: 17,
            minute: 30
        },
        orderItems: [
            { menuItemId: 1, quantity: 3 },
            { menuItemId: 2, quantity: 2 }
        ]
    };
    createOrderRequest.setJsonPayload(createOrderPayload.toJson());
    record {|
        *Order;
        *http:Links;
    |} createdOrder = check orderClient->post("", createOrderRequest);

    http:Response response = check orderClient->get(createdOrder.id.toString());
    test:assertEquals(response.statusCode, 200);

    record {|
        *Order;
        *http:Links;
    |} returnData = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData.links.length(), 3);
}

@test:Config {
    groups: ["get-order"]
}
function getOrderTestNegative() returns error? {
    http:Request createOrderRequest = new;
    CreateOrderRequest createOrderPayload = {
        consumerId: 1,
        restaurantId: 1,
        deliveryAddress: "Test delivery addrress",
        deliveryTime: {
            year: 2022,
            month: 3,
            day: 1,
            hour: 17,
            minute: 30
        },
        orderItems: [
            { menuItemId: 1, quantity: 3 },
            { menuItemId: 2, quantity: 2 }
        ]
    };
    createOrderRequest.setJsonPayload(createOrderPayload.toJson());
    record {|
        *Order;
        *http:Links;
    |} createdOrder = check orderClient->post("", createOrderRequest);

    http:Response response = check orderClient->get((createdOrder.id + 1).toString());
    test:assertEquals(response.statusCode, 404);
    test:assertEquals(response.getJsonPayload(), { message: "Order cannot be found."});
}

@test:Config {
    groups: ["delete-order"]
}
function deleteOrderTest() returns error? {
    http:Request createOrderRequest = new;
    CreateOrderRequest createOrderPayload = {
        consumerId: 1,
        restaurantId: 1,
        deliveryAddress: "Test delivery addrress",
        deliveryTime: {
            year: 2022,
            month: 3,
            day: 1,
            hour: 17,
            minute: 30
        },
        orderItems: [
            { menuItemId: 1, quantity: 3 },
            { menuItemId: 2, quantity: 2 }
        ]
    };
    createOrderRequest.setJsonPayload(createOrderPayload.toJson());
    record {|
        *Order;
        *http:Links;
    |} createdOrder = check orderClient->post("", createOrderRequest);

    http:Response response = check orderClient->get(createdOrder.id.toString());
    test:assertEquals(response.statusCode, 200);

    response = check orderClient->delete(createdOrder.id.toString());
    test:assertEquals(response.statusCode, 200);

    response = check orderClient->get(createdOrder.id.toString());
    test:assertEquals(response.statusCode, 404);
}

@test:Config {
    groups: ["delete-order"]
}
function deleteOrderTestNegative() returns error? {
    http:Request createOrderRequest = new;
    CreateOrderRequest createOrderPayload = {
        consumerId: 1,
        restaurantId: 1,
        deliveryAddress: "Test delivery addrress",
        deliveryTime: {
            year: 2022,
            month: 3,
            day: 1,
            hour: 17,
            minute: 30
        },
        orderItems: [
            { menuItemId: 1, quantity: 3 },
            { menuItemId: 2, quantity: 2 }
        ]
    };
    createOrderRequest.setJsonPayload(createOrderPayload.toJson());
    record {|
        *Order;
        *http:Links;
    |} createdOrder = check orderClient->post("", createOrderRequest);

    http:Response response = check orderClient->get(createdOrder.id.toString());
    test:assertEquals(response.statusCode, 200);

    response = check orderClient->delete((createdOrder.id + 1).toString());
    test:assertEquals(response.statusCode, 404);
    test:assertEquals(response.getJsonPayload(), { message: "Order cannot be found."});
}


isolated function validateOrder(CreateOrderRequest inputOrder, record {| *Order; *http:Links; |} outputOrder) {
    test:assertEquals(outputOrder.consumer.id, inputOrder.consumerId);
    test:assertEquals(outputOrder.restaurant.id, inputOrder.restaurantId);
    test:assertEquals(outputOrder.deliveryTime, inputOrder.deliveryTime);
    test:assertEquals(outputOrder.deliveryAddress, outputOrder.deliveryAddress);
    test:assertEquals(outputOrder.deliveryTime, inputOrder.deliveryTime);
    test:assertEquals(outputOrder.orderItems.length(), inputOrder.orderItems.length());

    foreach int i in 0 ..<outputOrder.orderItems.length() {
        test:assertEquals(outputOrder.orderItems[i].menuItem.id, outputOrder.orderItems[i].menuItem.id);
        test:assertEquals(outputOrder.orderItems[i].quantity, outputOrder.orderItems[i].quantity);
    }
}
