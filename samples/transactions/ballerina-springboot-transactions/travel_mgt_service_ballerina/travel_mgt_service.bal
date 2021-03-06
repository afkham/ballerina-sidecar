// Copyright (c) 2017 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package travel_mgt_svc_b6a;

import ballerina.net.http;
import ballerina.log;

// Initiator
@http:configuration {
    basePath:"/travel/reservation",
    host:"localhost",
    port:8000
}
service<http> travel_mgt_svc {
    @http:resourceConfig {
        methods:["POST"],
        path:"/"
    }
    resource reserve (http:Connection conn, http:InRequest req) {
        http:OutResponse res = {};
        log:printInfo("Initiating booking transaction...");

        json travelReq = req.getJsonPayload();

        string fullName = travelReq.full_name.toString();
        string departureCity = travelReq.departure_city.toString();
        string destinationCity = travelReq.destination_city.toString();
        string startDateStr = travelReq.state_date.toString();
        string endDateStr = travelReq.end_date.toString();
        string airline = travelReq.airline.toString();
        string hotel = travelReq.hotel.toString();

        transaction {
            var airlineResJson, err1 = reserveFlight(fullName, departureCity, destinationCity, startDateStr, endDateStr, airline);
            var hotelResJson, err2  = reserveHotel(fullName, departureCity, startDateStr, endDateStr, hotel);
            if (err1 == null && err2 == null) {
                res = {statusCode:200};
                res.setJsonPayload({airline_reservation:airlineResJson, hotel_reservation:hotelResJson});
            } else {
                res = {statusCode:500};
            }
        }

        var err = conn.respond(res);
        if (err != null) {
            log:printErrorCause("Could not send response back to client", err);
        } else {
            log:printInfo("Sent response back to client");
        }
    }
}

function reserveFlight (string fullName, string departureCity, string destinationCity,
                        string startDate, string endDate, string airline) returns (json response, error err) {
    endpoint<http:HttpClient> arilineEP {
        create http:HttpClient("http://127.0.0.1:8889", {});
    }

    json airlineReservationReq = {full_name:fullName, airline:airline, departure_city:departureCity,
                      destination_city:destinationCity, state_date:startDate, end_date:endDate, airline:airline};
    http:OutRequest req = {};

    req.setJsonPayload(airlineReservationReq);
    var airlineReservationRes, e = arilineEP.post("/flight/reservation", req);

    if (e == null) {
        if (airlineReservationRes.statusCode != 200) {
                err = {message:"Error occurred"};
        } else {
            log:printInfo("Got response from : Airline Service");
            response = airlineReservationRes.getJsonPayload();
        }
    } else {
        err = (error)e;
    }
    return response, err;
}

function reserveHotel (string fullName, string departureCity,
                       string startDate, string endDate, string hotel) returns (json jsonRes, error err) {
    endpoint<http:HttpClient> hotelEP {
        create http:HttpClient("http://localhost:9090", {});
    }
    json hotelReservationReq = {fullName:fullName, checkIn:startDate,
                      checkOut:endDate, rooms:1};
    http:OutRequest req = {};

    req.setJsonPayload(hotelReservationReq);
    var res, e = hotelEP.post("/reservation/hotel", req);
    if (e == null) {
        if (res.statusCode != 200) {
            err = {message:"Error occurred"};
        } else {
            log:printInfo("Got response from : Hotel Service");
            jsonRes = res.getJsonPayload();
        }
    } else {
        err = (error)e;
    }
    return jsonRes, err;
}