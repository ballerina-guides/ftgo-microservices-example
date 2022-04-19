// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;
import ballerina/sql;

# Request body to be used when creating and updating a consumer
type CourierRequest record {
    # Name of the consumer
    string name;
};

# Response for a successful consumer creation
type CourierCreated record {|
    *http:Created;
    # Details of the created courier along with the HTTP links to manage it
    record {|
        *Courier;
        *http:Links;
    |} body;
|};

# Response for a successful courier retrieval
type CourierView record {|
    *http:Ok;
    # Details of the retrieved courier along with the HTTP links to manage it
    record {|
        *Courier;
        *http:Links;
    |} body;
|};

type ScheduleDeliveryRequest record {
    int orderId;
    string pickUpAddress;
    string deliveryAddress;
};

# Response for a successful delivery scheduling
type DeliveryScheduled record {|
    *http:Created;
    # Details of the created courier along with the HTTP links to manage it
    record {|
        *Delivery;
        *http:Links;
    |} body;
|};

# Response for a successful delivery retrieval
type DeliveryView record {|
    *http:Ok;
    # Details of the retrieved courier along with the HTTP links to manage it
    record {|
        *Delivery;
        *http:Links;
    |} body;
|};

# Error response for when the requested courier cannot be found
type CourierNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Courier cannot be found." 
    };
|};

# Error response for when the requested delivery cannot be found
type DeliveryNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Delivery cannot be found." 
    };
|};

# Represents an unexpected error
type InternalError record {|
   *http:InternalServerError;
   # Error payload
    record {| 
        string message;
    |} body;
|}; 

# Listener for the Delivery service
service  on new http:Listener(8084) {

    # Resource function to create a new courier
    #
    # + request - Details of the courier to be created
    # + return - `CourierCreated` if the consumer was sucessfully created.
    #            `InternalError` if an unexpected error occurs.
    isolated resource function post courier(@http:Payload CourierRequest request) returns CourierCreated|InternalError {
        do {
            Courier generatedCourier = check createCourier(request.name);
            return <CourierCreated>{ 
                headers: {
                    location: "/courier/" + generatedCourier.id.toString()
                },
                body: {
                    ...generatedCourier,
                    links: getCourierLinks(generatedCourier.id)
                }
            };
        } on fail error e {
            log:printError("Error in creating new courier.", e, e.stackTrace());
            return <InternalError>{ body: { message: e.message() }};
        }
    }

    # Resource function to fetch the details of a courier
    #
    # + id - The ID of the requested consumer
    # + return - `CourierView` if the details are successfully fetched.
    #            `CourierNotFound` if a consumer with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function get courier/[int id]() returns CourierView|CourierNotFound|InternalError {
        do {
            Courier courier = check getCourier(id);
            return <CourierView>{ 
                body: {
                    ...courier,
                    links: getCourierLinks(courier.id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <CourierNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }       
    }

    # Resource function to schedule a new delivery
    #
    # + request - The details of the delivery
    # + return - `DeliveryScheduled` if the delivery is successfully scheduled.
    #            `InternalError` if an unexpected error occurs
    isolated resource function post delivery/schedule(@http:Payload ScheduleDeliveryRequest request) returns DeliveryScheduled|InternalError{
        do {
            Delivery delivery = check scheduleDelivery(request.orderId, request.pickUpAddress, request.deliveryAddress);
            return <DeliveryScheduled>{
                body: {
                    ...delivery,
                    links: getDeliveryLinks(delivery.id)
                }
            };
        } on fail error e {
            log:printError("Error scheduling delivery", 'error = e, stackTrace = e.stackTrace());
            return <InternalError>{ body: { message: e.message() }};
        }     
    }

    # Resource function to fetch the details of a delivery
    #
    # + id - The ID of the requested consumer
    # + return - `DeliveryView` if the details are successfully fetched.
    #            `DeliveryNotFound` if a delivery with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function get delivery/[int id]() returns DeliveryView|DeliveryNotFound|InternalError{
        do {
            Delivery delivery = check getDelivery(id);
            return <DeliveryView>{
                body: {
                    ...delivery,
                    links: getDeliveryLinks(delivery.id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <DeliveryNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }     
    }

    # Resource function to change the status of a delivery to `PICKED_UP`
    #
    # + id - The ID of the delivery
    # + return - `DeliveryView` if the details are successfully fetched.
    #            `DeliveryNotFound` if a delivery with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function put delivery/[int id]/update/pickedUp() returns DeliveryView|DeliveryNotFound|InternalError {
        return changeDeliveryStatus(id, PICKED_UP);           
    }

    # Resource function to change the status of a delivery to `DELIVERED`
    #
    # + id - The ID of the delivery
    # + return - `DeliveryView` if the details are successfully fetched.
    #            `DeliveryNotFound` if a delivery with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function put delivery/[int id]/update/delivered() returns DeliveryView|DeliveryNotFound|InternalError {
        return changeDeliveryStatus(id, DELIVERED);           
    }

}

# Changes the status of a delivery
#
# + id - The ID of the delivery  
# + newStatus - The new status of the delivery
# + return - `DeliveryView` if the details are successfully fetched.
#            `DeliveryNotFound` if a delivery with the provided ID was not found.
#            `InternalError` if an unexpected error occurs
isolated function changeDeliveryStatus(int id, DeliveryState newStatus) returns DeliveryView|DeliveryNotFound|InternalError {
    do {
        Delivery delivery = check updateDelivery(id, newStatus);
        return <DeliveryView>{
            body: {
                ...delivery,
                links: getDeliveryLinks(delivery.id)
            }
        };
    } on fail error e {
        if e is sql:NoRowsError {
            return <DeliveryNotFound>{};
        }
        return <InternalError>{ body: { message: e.message() }};
    }      
}

# Returns the HTTP links related to a given courier
#
# + courierId - The ID of the courier
# + return - An array of links
isolated function getCourierLinks(int courierId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/courier/" + courierId.toString(),
            methods: [http:GET]
        }
    ];
}

# Returns the HTTP links related to a given delivery
#
# + deliveryId - The ID of the courier
# + return - An array of links
isolated function getDeliveryLinks(int deliveryId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/delivery/" + deliveryId.toString(),
            methods: [http:GET]
        }
    ];
}
