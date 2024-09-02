Welcome to DataDesk!

This is a pet project designed to make it easy to create records dynamically in Salesforce from a one-stop-shop Lightning Web Component. You can create a template for a record that includes fields you'd like to populate with each record creation. You can hard-code values, or have the engine generate a value based on entered parameters, such as a min and max value for a number field, or start and end dates for a date field. This also allows for easy bulk record creation for automation testing.

This project was created to help test an outgoing API integration with lots of data validation on the incoming data. These validations made it difficult to repeatedly test API submissions using the exact same record, as the external system would send back error codes any time a student submits an application for the same academic program twice, for example.
