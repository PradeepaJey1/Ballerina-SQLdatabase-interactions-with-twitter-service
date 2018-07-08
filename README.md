# Ballerina-SQLdatabase-interactions-with-twitter-service


This project will allow to add an employee , delete an employee , retrieve an employee , update an employee , send a tweet to Twitter if the employee's job has been updated (assumed as he/she is promoted).

hello_service.bal - Twitter implementation.
Edit the twitter.toml file by using your twitter account keys (ref: https://ballerina.io/learn/quick-tour/)

employee_db_service.bal - Database Implementation
initializeDatabase.sql - The SQL file of the database
(ref: https://ballerina.io/learn/by-guide/data-backed-service/)

The database service has been integrated with the twitter service.
When a http request for update employee is sent , it checks if the job has been updated or not ,
if it is updated it would be considered as a promotion and a http request to the twitter service will be sent.
The employee's name , old job and the new job is sent as JSON along with the http request to the twitter service.
In the twitter implementation the information is extracted from the request and the appropriate message is constructed and tweeted.
An acknowledgement is sent back to the database service from the twitter service to print the message in the console which was tweeted.


HTTP Requests To:

Add an employee -

curl -v -X POST -d '{"name":"Ben", "age":20,"ssn":123456789, "job": "SE", "employeeId":2}' \
"http://localhost:9090/records/employee" -H "Content-Type:application/json"

Output:  
{"Status":"Data Inserted Successfully"}

Retrieve an employee details by employee ID

curl -v  "http://localhost:9090/records/employee/1"

Output: 
[{"EmployeeID":1,"Name":"Alice","Age":20,"SSN":123456789, "Job": "SE"}]

Delete an employee by employee ID

curl -v -X DELETE "http://localhost:9090/records/employee/1"

Output: 
{"Status":"Data Deleted Successfully"}


Update an employee

curl -v -X PUT -d '{"name":"Alice joeyd", "age":30,"ssn":123456789,"employeeId":1, "job":"Manager"}' "http://localhost:9090/records/employee" -H "Content-Type:application/json"

Output: 
{"Status":"Data updated Successfully"}

