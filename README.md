# Microservices example in Ballerina

## Overview
This example is based on the [FTGO application](https://github.com/microservices-patterns/ftgo-application), a sample of an online food delivery application, connecting consumers and restaurants.

![Architectute](/assets/architecture.png)

The example has five different services
* Consumer
* Restaurant
* Order
* Accounting
* Delivery

These four services are interacted with by three types of users
* Consumers
* Restaurants
* Couriers

## Consumer service
The consumer service represents a customer who places orders through the application.

The data structure of a consumer is as follows
```ballerina
public type Consumer record {|
    int id;
    string name;
    string address;
    string email;
|};
```

This service provides four basic endpoints:
### 1. Create consumer
> Endpoint: `/`  
> Method: `POST`  
> Request payload: `ConsumerRequest`  

Creates a new consumer using the provided details.

### 2. Get consumer
> Endpoint: `/<consumerId>`  
> Method: `GET`  

Retrieves the details of the consumer with the given ID. 

### 3. Delete consumer
> Endpoint: `/<consumerId>`  
> Method: `DELETE`  

Deleted the consumer with the given ID. Returns a 404 Not Found error if a consumer with the given ID is not found. 

### 4. Update consumer
> Endpoint: `/<consumerId>`  
> Method: `POST`  
> Request payload: `ConsumerRequest`  

Updates the details of the consumer with the given ID using the provided details.

These four endpoints showcases the basic CRUD functionalities and how it can be achieved with Ballerina.

### Data storage and retrieval
The consumer service has it's own MySQL database for storing relevant consumer data. Since this service does not access data outside of it's own module, there is no requirement to make any REST API calls to access the other microservices.

### Order validation
This service also provides the endpoint `<consumerId>/validate` to validate an order placed by a consumer. This method is currently a dummy method, and does not perform any functional business logic. 

### Running the module
1. Set up a MySQL database and create the relevant tables using the queries in the `init.sql` file in the `consumer` directory.
2. Configure the database connection properties in the `Config.toml` file in the `consumer` directory. 
3. To run the consumer service, simply navigate to the `consumer` directory and execute `bal run` in the terminal. 

## Restaurant service
The restaurant service represents a restaurant, with its menu, menu items and prices. A restaurant can contain multiple menus; and a menu can contain multiple menu items.

The basic data structure of a restaurant and its associated data types are as follows.
```ballerina
type Restaurant record {|
    int id;
    string name;
    string address;
    Menu[] menus;
|};

type Menu record {|
    int id;
    string name;
    MenuItem[] items;
|};

type MenuItem record {|
    int id;
    string name;
    decimal price;
|};
```

This service provides endpoints to perform basic CRUD functionalities with restaurants, menus and menu items through 12 different endpoints.

### Managing tickets
The restaurant service also provides endpoints to create and view tickets, as well as update their status. A ticket contains the following information:
```ballerina
type Ticket record {|
    int id;
    Restaurant restaurant;
    Order 'order;
    TicketState status;
|};
```

A ticket can be in one of the following states:
* `ACCEPTED`
* `PREPARING`
* `READY_FOR_PICKUP`
* `PICKED_UP`

When a ticket is created, it will initially be in the `ACCEPTED` state. The state of a ticket can be advanced to each state using the three endpoints defined.
* To `PREPARING`: `restaurant/<restaurantId>/ticket/<ticketId>/mark/preparing`
* To `READY_FOR_PICKUP`: `restaurant/<restaurantId>/ticket/<ticketId>/mark/ready`
* To `PICKED_UP`: `restaurant/<restaurantId>/ticket/<ticketId>/mark/pickedUp`

In each of these scenarios, the corresponding state of the `Order` in the `Order Service` is also changed.

![Ticket Sequence](/assets/ticket_sequence.png)


### Data storage and retrieval
The restaurant service has it's own MySQL database for storing relevant restaurant data. Since this services accesses data from the `Order Service` it is required to configure this endpoint and make REST API calls whenever necessary.

### Running the module
1. Set up a MySQL database and create the relevant tables using the queries in the `init.sql` file in the `restaurant` directory.
2. Configure the database connection properties as well as the order endpoint in the `Config.toml` file in the `restaurant` directory. 
3. To run the consumer service, simply navigate to the `restaurant` directory and execute `bal run` in the terminal. 

## Order service
The order service handles orders placed by a consumer for a restaurant. This service is central to this example. 

The basic data structure of an order is as follows:
```ballerina
type Order record {|
    int id;
    Consumer consumer;
    Restaurant restaurant;
    OrderItem[] orderItems;
    string deliveryAddress;
    time:Civil deliveryTime;
    OrderState status;
|};

type OrderItem record {|
    int id;
    MenuItem menuItem;
    int quantity;
|};
```

This service provides 4 endpoints to perform basic CRUD functionalities with orders.

An order can be in one of the following states:
* `APPROVAL_PENDING`
* `APPROVED`
* `REJECTED`
* `ACCEPTED`
* `PREPARING`
* `READY_FOR_PICKUP`
* `PICKED_UP`
* `DELIVERED`
* `CANCELLED`

As an order is created, it is initially in the `APPROVAL_PENDING` stage. 
- As it moves into the `ACCEPTED` stage after the order is confirmed, a ticket has to be created in the restaurant. 
- As it moves into the `READY_FOR_PICKUP` stage, a delivery has to be scheduled using the `Delivery Service`.

![Order Sequence](/assets/order_sequence.png)


### Data storage and retrieval
The restaurant service has it's own MySQL database for storing relevant restaurant data. Since this services accesses data from the other services it is required to configure these endpoints and make REST API calls whenever necessary.

### Running the module
1. Set up a MySQL database and create the relevant tables using the queries in the `init.sql` file in the `order` directory.
2. Configure the database connection properties as well as the endpoint configurations in the `Config.toml` file in the `order` directory. 
3. To run the consumer service, simply navigate to the `order` directory and execute `bal run` in the terminal. 

## Accounting service
The accounting service calulates the fee to be charged from the consumer and manages the accounting process.

## Delivery Service
The delivery service is responsible for the management of couriers and managing the delivery of orders from the restaurant to the consumer.