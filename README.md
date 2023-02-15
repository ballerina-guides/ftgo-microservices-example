# FTGO microservices example in Ballerina

## Overview
This example is based on the [FTGO application](https://github.com/microservices-patterns/ftgo-application), a sample of an online food delivery application, connecting consumers and restaurants.

![Architecture](/assets/architecture.png)


## Services
The example has the five different services below.
* Consumer
* Restaurant
* Order
* Accounting
* Delivery

## Users
These five services interact with the three types of users below.
* Consumers
* Restaurants
* Couriers

## Consumer service
The consumer service represents a customer who places orders through the application.

The data structure of a consumer is as follows,
```ballerina
public type Consumer record {|
    int id;
    string name;
    string address;
    string email;
|};
```

### Endpoints
This service provides the four basic endpoints below. These four endpoints showcase the basic CRUD functionalities and how they can be achieved with Ballerina.

#### 1. Create a consumer
Creates a new consumer using the provided details.
> Endpoint: `/`
> Method: `POST`
> Request payload: `ConsumerRequest`

#### 2. Get a consumer
Retrieves the details of the consumer with the given ID.
> Endpoint: `/<consumerId>`
> Method: `GET`

#### 3. Delete a consumer
Deletes the consumer with the given ID. Returns a `404 Not Found` error if a consumer with the given ID is not found. 
> Endpoint: `/<consumerId>`
> Method: `DELETE`

#### 4. Update a consumer
Updates the details of the consumer with the given ID using the provided details.
> Endpoint: `/<consumerId>`
> Method: `POST`
> Request payload: `ConsumerRequest`

### Data storage and retrieval
The consumer service has its own MySQL database for storing relevant consumer data. Since this service does not access data outside of its own module, there is no requirement to make any REST API calls to access the other microservices.

### Order validation
This service also provides the endpoint `<consumerId>/validate` to validate an order placed by a consumer. This method is currently a dummy method and does not perform any functional business logic. 

### Running the module
1. Set up a MySQL database and create the relevant tables using the queries in the `init.sql` file in the `consumer` directory.
2. Configure the database connection properties in the `Config.toml` file in the `consumer` directory. 
3. To run the consumer service, navigate to the `consumer` directory and execute `bal run` in the terminal. 

## Restaurant service
The restaurant service represents a restaurant with its menu, menu items, and prices. A restaurant can contain multiple menus; and a menu can contain multiple menu items.

The basic data structure of a restaurant and its associated data types are as follows:
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

This service provides endpoints to perform basic CRUD functionalities with restaurants, menus, and menu items through 12 different endpoints.

### Managing tickets
The restaurant service also provides endpoints to create and view tickets as well as update their status. A ticket contains the following information:
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

When a ticket is created, it will initially be in the `ACCEPTED` state. The state of a ticket can be advanced to each state below using the three endpoints defined.
* To `PREPARING`: `restaurant/<restaurantId>/ticket/<ticketId>/mark/preparing`
* To `READY_FOR_PICKUP`: `restaurant/<restaurantId>/ticket/<ticketId>/mark/ready`
* To `PICKED_UP`: `restaurant/<restaurantId>/ticket/<ticketId>/mark/pickedUp`

In each of these scenarios, the corresponding state of the `Order` in the `Order Service` is also changed.

![Ticket Sequence](/assets/ticket_sequence.png)


### Data storage and retrieval
The restaurant service has its own MySQL database for storing relevant restaurant data. Since this service accesses data from the `Order Service` it is required to configure this endpoint and make REST API calls whenever necessary.

### Running the module
1. Set up a MySQL database and create the relevant tables using the queries in the `init.sql` file in the `restaurant` directory.
2. Configure the database connection properties as well as the order endpoint in the `Config.toml` file in the `restaurant` directory. 
3. To run the restaurant service, navigate to the `restaurant` directory and execute `bal run` in the terminal. 

## Order service
The order service handles orders placed by a consumer of a restaurant. This service is central to this example. This service provides 4 endpoints to perform basic CRUD functionalities with orders.

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
- As it moves into the `READY_FOR_PICKUP` stage, delivery has to be scheduled using the delivery service.

![Order Sequence](/assets/order_sequence.png)

### Data storage and retrieval
The order service has its own MySQL database for storing relevant order data. Since this service accesses data from the other services it is required to configure these endpoints and make REST API calls whenever necessary.

### Running the module
1. Set up a MySQL database and create the relevant tables using the queries in the `init.sql` file in the `order` directory.
2. Configure the database connection properties as well as the endpoint configurations in the `Config.toml` file in the `order` directory. 
3. To run the order service, navigate to the `order` directory and execute `bal run` in the terminal. 

## Accounting service
The `accounting` service is used to charge payments to the consumer and to view the bills generated.

The basic data structure of a bill is as follows:
```ballerina
type Bill record {|
    int id;
    Consumer consumer;
    Order 'order;
    decimal orderAmount;
|};
```

This service provides two endpoints:
### 1. Charge consumer
> Endpoint: `/charge`  
> Method: `POST`  
> Request payload: `ChargeRequest`  

Initiates a charge on a customer using the provided details. Currently this method does not perform any meaningful functionality, as is a dummy method. 

### 2. View bill
> Endpoint: `/bill/<billId>`  
> Method: `GET`  

Retrieves the details of the bill with the provided ID. 

### Data storage and retrieval
The accounting service has it's own MySQL database for storing relevant accounting data. The two defined endpoints accesses `Order Service` and `Consumer Service` to retrieve relevant data. Since this service accesses data from the other services it is required to configure these endpoints and make REST API calls whenever necessary.

### Running the module
1. Set up a MySQL database and create the relevant tables using the queries in the `init.sql` file in the `accounting` directory.
2. Configure the database connection properties as well as the endpoint configurations in the `Config.toml` file in the `accounting` directory. 
3. To run the accounting service, navigate to the `accounting` directory and execute `bal run` in the terminal. 

## Delivery Service
The delivery service is responsible for the management of couriers and delivery of orders from the restaurant to the consumer.

This service is also responsible the creation and management of couriers. The basic data structure of a courier is as follows:
```ballerina
type Courier record {|
    int id;
    string name;
|};
```

The delivery service provides four endpoints to perform basic CRUD functionalities associated with couriers.


In addition, to manange deliveries, the basic data structure of a delivery is as follows:
```ballerina
type Delivery record {|
    int id;
    Order 'order;
    Courier courier;
    string pickUpAddress;
    time:Civil? pickUpTime;
    string deliveryAddress;
    time:Civil? deliveryTime;
    DeliveryState status;
|};
```

The delivery state can be one of the following:
* `READY_FOR_PICKUP`
* `PICKED_UP`
* `DELIVERED`

The delivery service provides two primary endpoints to manage deliveries.

### 1. Schedule delivery
> Endpoint: `/delivery/schedule`  
> Method: `POST`  
> Request payload: `ScheduleDeliveryRequest`  

This would schedule a new delivery. The closest avaiable courier is picked and assigned to carry out the delivery (at the momeent, this logic is not implemented; instead a courier is picked at random).

### 2. Get delivery info
> Endpoint: `/delivery/<deliveryId>`  
> Method: `GET`  

Retrieves the details of the delivery with the provided ID. 

When a delivery is scheduled, it will initially be in the `READY_FOR_PICKUP` state. The state of a delivery can be advanced to each state using the three endpoints defined.
* To `PICKED_UP`: `delivery/<deliveryId>/update/pickedUp`
* To `DELIVERED`: `delivery/<deliveryId>/update/delivered`

In each of the above scenarios, the relevant timestamps are also updated in the database and the corresponding state of the `Order` in the `Order Service` is also changed.

### Data storage and retrieval
The delivery service has it's own MySQL database for storing relevant accounting data. The endpoints access the `Order Service` to retrieve relevant data and update order statuses. Since this service accesses data from the other services it is required to configure these endpoints and make REST API calls whenever necessary.

### Running the module
1. Set up a MySQL database and create the relevant tables using the queries in the `init.sql` file in the `delivery` directory.
2. Configure the database connection properties as well as the endpoint configurations in the `Config.toml` file in the `delivery` directory. 
3. To run the delivery service, navigate to the `delivery` directory and execute `bal run` in the terminal. 
