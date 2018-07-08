import ballerina/sql;
import ballerina/mysql;
import ballerina/log;
import ballerina/http;
import ballerina/config;
import ballerina/io;

type Employee {
    string name;
    int age;
    int ssn;
    int employeeId;
    string job;
};

// Create SQL endpoint to MySQL database
endpoint mysql:Client employeeDB {
    host: config:getAsString("DATABASE_HOST", default = "localhost"),
    port: config:getAsInt("DATABASE_PORT", default = 3306),
    name: config:getAsString("DATABASE_NAME", default = "EMPLOYEE_RECORDS"),
    username: config:getAsString("DATABASE_USERNAME", default = "root"),
    password: config:getAsString("DATABASE_PASSWORD", default = ""),
    dbOptions: { useSSL: false }
};

//create endpoint to twitter service
endpoint http:Client hs{
    url: "http://localhost:8080"
};

endpoint http:Listener listener {
    port: 9090
};

// Service for the employee data service
@http:ServiceConfig {
    basePath: "/records"
}
service<http:Service> EmployeeData bind listener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/employee/"
    }
    addEmployeeResource(endpoint httpConnection, http:Request request) {
        // Initialize an empty http response message
        http:Response response;
        Employee employeeData;
        // Extract the data from the request payload
        var payloadJson = check request.getJsonPayload();
        employeeData = check <Employee>payloadJson;

        // Check for errors with JSON payload using
        if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0 ||
            employeeData.employeeId == 0) {
            response.setTextPayload("Error : json payload should contain
             {name:<string>, age:<int>, ssn:<123456>,employeeId:<int>} ");
            response.statusCode = 400;
            _ = httpConnection->respond(response);
            done;
        }

        // Invoke insertData function to save data in the Mymysql database
        json ret = insertData(employeeData.name, employeeData.age, employeeData.ssn,
            employeeData.employeeId);
        // Send the response back to the client with the employee data
        response.setJsonPayload(ret);
        _ = httpConnection->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/employee/{employeeId}"
    }
    retrieveEmployeeResource(endpoint httpConnection, http:Request request, string
    employeeId) {
        
        // Initialize an empty http response message to send response to the terminal
        http:Response response;

        // Initialize an empty request to send request to twitter service
        http:Request req = new;

        // Convert the employeeId string to integer
        int empID = check <int>employeeId;

        // Invoke retrieveById function to retrieve data from Mymysql database
        json employeeData = retrieveById(empID);
      
        // Send the response back to the client with the employee data
        response.setJsonPayload(employeeData);
        _ = httpConnection->respond(response);
            
    }

    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/employee/"
    }
    updateEmployeeResource(endpoint httpConnection, http:Request request) {
        
        http:Request req; // Initialize an empty request
        http:Response response; // Initialize an empty response
        Employee employeeData;

        // Extract the data from the request payload
        var payloadJson = check request.getJsonPayload();
        employeeData = check <Employee>payloadJson;

        // Check for errors with JSON payload using
        if (employeeData.name == "" || employeeData.age == 0 || employeeData.ssn == 0 ||
            employeeData.employeeId == 0 || employeeData.job == "") {
            response.setTextPayload("Error : json payload should contain
             {name:<string>, age:<int>, ssn:<123456>,employeeId:<int>,job:<string> }");
            response.statusCode = 400;
            _ = httpConnection->respond(response);
            done;
        }

       //before update retrieve the previous employee details
       json oldEmployee = retrieveById(employeeData.employeeId);
       string oldJob = check <string> oldEmployee[0].Job;

        // Invoke updateData function to update data in mysql database
        json ret = updateData(employeeData.name, employeeData.age, employeeData.ssn, employeeData.job,
        employeeData.employeeId);

        //to check if the job is not updated, if so    
        if (oldJob == employeeData.job){
            

         //send a response saying data is successfully uploaded   
         response.setJsonPayload("updated successfully!");
          _ = httpConnection->respond(response);
       
        }

        //if the job has been updated
        if (oldJob != employeeData.job) {

        //create the request as json message
         json jsonMsg = { old: oldJob, newJ: employeeData.job, name: employeeData.name};
         req.setJsonPayload(jsonMsg);

        //send the request to twitter service and get the response from it and store it in ping variable
        var ping= hs->post("/twitter",req);

        // check the response received from twitter service
        match ping {
        // get the response from twitter    
        http:Response resp => {
            //and store it in the msg variable
            var msg = resp.getJsonPayload();

            //check the msg (response)
            match msg {
                //pass the value in the msg variable to reply variable
                json reply => {
                    //create a response to send it to the terminal
                    var resultMessage = "Done tweeting as - " + reply["name"].toString() + " has been promoted to " +reply["newJ"].toString() + " from " + reply["old"].toString();
                    //send the response to the terminal
                     response.setJsonPayload(resultMessage);
                    _ = httpConnection->respond(response);
                    done;
                }
                //exception for the msg reponse
                error err => {
                    log:printError(err.message, err = err);
                }
            }
        }
        //exception for the ping response
        error err => { log:printError(err.message, err = err); }
    }
  }
        
}

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/employee/{employeeId}"
    }
    deleteEmployeeResource(endpoint httpConnection, http:Request request, string
    employeeId) {
        // Initialize an empty http response message
        http:Response response;
        // Convert the employeeId string to integer
        var empID = check <int>employeeId;
        var deleteStatus = deleteData(empID);
        // Send the response back to the client with the employee data
        response.setJsonPayload(deleteStatus);
        _ = httpConnection->respond(response);
    }
}

public function insertData(string name, int age, int ssn, int employeeId) returns (json){
    json updateStatus;
    string sqlString =
    "INSERT INTO EMPLOYEES (Name, Age, SSN, EmployeeID) VALUES (?,?,?,?)";
    // Insert data to SQL database by invoking update action
    var ret = employeeDB->update(sqlString, name, age, ssn, employeeId);
    // Use match operator to check the validity of the result from database
    match ret {
        int updateRowCount => {
            updateStatus = { "Status": "Data Inserted Successfully" };
        }
        error err => {
            updateStatus = { "Status": "Data Not Inserted", "Error": err.message };
        }
    }
    return updateStatus;
}

public function retrieveById(int employeeID) returns (json) {
    json jsonReturnValue;
    string sqlString = "SELECT * FROM EMPLOYEES WHERE EmployeeID = ?";
    // Retrieve employee data by invoking select action defined in ballerina sql client
    var ret = employeeDB->select(sqlString, (), employeeID);
    match ret {
        table dataTable => {
            // Convert the sql data table into JSON using type conversion
            jsonReturnValue = check <json>dataTable;
        }
        error err => {
            jsonReturnValue = { "Status": "Data Not Found", "Error": err.message };
        }
    }
    return jsonReturnValue;
}

public function updateData(string name, int age, int ssn, string job, int employeeId) returns (json){
    json updateStatus = {};
    string sqlString =
    "UPDATE EMPLOYEES SET Name = ?, Age = ?, SSN = ?, Job = ? WHERE EmployeeID  = ?";
    // Update existing data by invoking update action defined in ballerina sql client
    var ret = employeeDB->update(sqlString, name, age, ssn, job, employeeId);
    match ret {
        int updateRowCount => {
            if (updateRowCount > 0) {
                updateStatus = { "Status": "Data Updated Successfully" };
            }
            else {
                updateStatus = { "Status": "Data Not Updated" };
            }
        }
        error err => {
            updateStatus = { "Status": "Data Not Updated", "Error": err.message };
        }
    }
    return updateStatus;
}

public function deleteData(int employeeID) returns (json) {
    json updateStatus = {};

    string sqlString = "DELETE FROM EMPLOYEES WHERE EmployeeID = ?";
    // Delete existing data by invoking update action defined in ballerina sql client
    var ret = employeeDB->update(sqlString, employeeID);
    match ret {
        int updateRowCount => {
            updateStatus = { "Status": "Data Deleted Successfully" };
        }
        error err => {
            updateStatus = { "Status": "Data Not Deleted", "Error": err.message };
        }
    }
    return updateStatus;
}